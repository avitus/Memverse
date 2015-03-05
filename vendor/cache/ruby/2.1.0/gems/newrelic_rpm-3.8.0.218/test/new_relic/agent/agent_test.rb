# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))

module NewRelic
  module Agent
    class AgentTest < Minitest::Test
      include NewRelic::TestHelpers::Exceptions

      def setup
        super
        @agent = NewRelic::Agent::Agent.new
        @agent.service = default_service
        @agent.agent_command_router.stubs(:new_relic_service).returns(@agent.service)
        @agent.stubs(:start_worker_thread)

        @config = { :license_key => "a" * 40 }
        NewRelic::Agent.config.apply_config(@config)
      end

      def teardown
        NewRelic::Agent.config.remove_config(@config)
      end

      def test_after_fork_reporting_to_channel
        @agent.stubs(:connected?).returns(true)
        @agent.after_fork(:report_to_channel => 123)
        assert(@agent.service.kind_of?(NewRelic::Agent::PipeService),
               'Agent should use PipeService when directed to report to pipe channel')
        NewRelic::Agent::PipeService.any_instance.expects(:shutdown).never
        assert_equal 123, @agent.service.channel_id
      end

      def test_after_fork_reporting_to_channel_should_not_collect_environment_report
        with_config(:monitor_mode => true) do
          @agent.stubs(:connected?).returns(true)
          @agent.expects(:generate_environment_report).never
          @agent.after_fork(:report_to_channel => 123)
        end
      end

      def test_after_fork_should_close_pipe_if_parent_not_connected
        pipe = mock
        pipe.expects(:after_fork_in_child)
        pipe.expects(:close)
        pipe.stubs(:parent_pid).returns(:digglewumpus)
        dummy_channels = { 123 => pipe }
        NewRelic::Agent::PipeChannelManager.stubs(:channels).returns(dummy_channels)

        @agent.stubs(:connected?).returns(false)
        @agent.after_fork(:report_to_channel => 123)
        assert(@agent.disconnected?)
      end

      def test_after_fork_should_replace_stats_engine
        with_config(:monitor_mode => true) do
          @agent.stubs(:connected?).returns(true)
          old_engine = @agent.stats_engine

          @agent.after_fork(:report_to_channel => 123)

          assert old_engine != @agent.stats_engine, "Still got our old engine around!"
        end
      end

      def test_after_fork_should_reset_errors_collected
        with_config(:monitor_mode => true) do
          @agent.stubs(:connected?).returns(true)

          errors = []
          errors << NewRelic::NoticedError.new("", {}, Exception.new("boo"))
          @agent.merge_data_for_endpoint(:error_data, errors)

          @agent.after_fork(:report_to_channel => 123)

          assert_equal 0, @agent.error_collector.errors.length, "Still got errors collected in parent"
        end
      end

      def test_after_fork_should_mark_as_started
        with_config(:monitor_mode => true) do
          refute @agent.started?
          @agent.after_fork
          assert @agent.started?
        end
      end

      def test_after_fork_should_prevent_further_thread_restart_attempts
        with_config(:monitor_mode => true) do
          # Disconnecting will tell us not to restart the thread
          @agent.disconnect
          @agent.after_fork

          refute @agent.harvester.needs_restart?
        end
      end

      def test_transmit_data_should_emit_before_harvest_event
        got_it = false
        @agent.events.subscribe(:before_harvest) { got_it = true }
        @agent.instance_eval { transmit_data }
        assert(got_it)
      end

      def test_transmit_data_should_transmit
        @agent.service.expects(:metric_data).at_least_once
        @agent.stats_engine.record_metrics(['foo'], 12)
        @agent.instance_eval { transmit_data }
      end

      def test_transmit_data_should_use_one_http_handle_per_harvest
        @agent.service.expects(:session).once
        @agent.instance_eval { transmit_data }
      end

      def test_transmit_data_should_close_explain_db_connections
        NewRelic::Agent::Database.expects(:close_connections)
        @agent.instance_eval { transmit_data }
      end

      def test_harvest_and_send_transaction_traces
        with_config(:'transaction_tracer.explain_threshold' => 2,
                    :'transaction_tracer.explain_enabled' => true,
                    :'transaction_tracer.record_sql' => 'raw') do
          trace = stub('transaction trace',
                       :duration => 2.0, :threshold => 1.0,
                       :transaction_name => nil,
                       :force_persist => true,
                       :truncate => 4000)

          @agent.transaction_sampler.stubs(:harvest!).returns([trace])
          @agent.send :harvest_and_send_transaction_traces
        end
      end

      def test_harvest_and_send_transaction_traces_merges_back_on_failure
        traces = [mock('tt1'), mock('tt2')]

        @agent.transaction_sampler.expects(:harvest!).returns(traces)
        @agent.service.stubs(:transaction_sample_data).raises("wat")
        @agent.transaction_sampler.expects(:merge!).with(traces)

        @agent.send :harvest_and_send_transaction_traces
      end

      def test_harvest_and_send_errors_merges_back_on_failure
        errors = [mock('e0'), mock('e1')]

        @agent.error_collector.expects(:harvest!).returns(errors)
        @agent.service.stubs(:error_data).raises('wat')
        @agent.error_collector.expects(:merge!).with(errors)

        @agent.send :harvest_and_send_errors
      end

      # This test asserts nothing about correctness of logging data from multiple
      # threads, since the get_stats + record_data_point combo is not designed
      # to be thread-safe, but it does ensure that writes to the stats hash
      # via this path that happen concurrently with harvests will not cause
      # 'hash modified during iteration' errors.
      def test_harvest_timeslice_data_should_be_thread_safe
        threads = []
        nthreads = 10
        nmetrics = 100

        nthreads.times do |tid|
          t = Thread.new do
            nmetrics.times do |mid|
              @agent.stats_engine.get_stats("m#{mid}").record_data_point(1)
            end
          end
          t.abort_on_exception = true
          threads << t
        end

        100.times { @agent.send(:harvest_and_send_timeslice_data) }
        threads.each { |t| t.join }
      end

      def test_handle_for_agent_commands
        @agent.service.expects(:get_agent_commands).returns([]).once
        @agent.send :check_for_and_handle_agent_commands
      end

      def test_check_for_and_handle_agent_commands_with_error
        @agent.service.expects(:get_agent_commands).raises('bad news')
        @agent.send :check_for_and_handle_agent_commands
      end

      def test_harvest_and_send_for_agent_commands
        @agent.service.expects(:profile_data).with(any_parameters)
        @agent.agent_command_router.stubs(:harvest!).returns({:profile_data => [Object.new]})
        @agent.send :harvest_and_send_for_agent_commands
      end

      def test_merge_data_for_endpoint_empty
        @agent.stats_engine.expects(:merge!).never
        @agent.error_collector.expects(:merge!).never
        @agent.transaction_sampler.expects(:merge!).never
        @agent.instance_variable_get(:@request_sampler).expects(:merge!).never
        @agent.sql_sampler.expects(:merge!).never
        @agent.merge_data_for_endpoint(:metric_data, [])
        @agent.merge_data_for_endpoint(:transaction_sample_data, [])
        @agent.merge_data_for_endpoint(:error_data, [])
        @agent.merge_data_for_endpoint(:sql_trace_data, [])
        @agent.merge_data_for_endpoint(:analytic_event_data, [])
      end

      def test_merge_data_traces
        transaction_sampler = mock('transaction sampler')
        @agent.instance_eval {
          @transaction_sampler = transaction_sampler
        }
        transaction_sampler.expects(:merge!).with([1,2,3])
        @agent.merge_data_for_endpoint(:transaction_sample_data, [1,2,3])
      end

      def test_merge_data_for_endpoint_abides_by_error_queue_limit
        errors = []
        40.times { |i| errors << NewRelic::NoticedError.new("", {}, Exception.new("boo #{i}")) }

        @agent.merge_data_for_endpoint(:error_data, errors)

        assert_equal 20, @agent.error_collector.errors.length

        # This method should NOT increment error counts, since that has already
        # been counted in the child
        assert_equal 0, @agent.stats_engine.get_stats("Errors/all").call_count
      end

      def test_harvest_and_send_analytic_event_data_merges_in_samples_on_failure
        service = @agent.service
        request_sampler = @agent.instance_variable_get(:@request_sampler)
        samples = [mock('some analytics event')]

        request_sampler.expects(:harvest!).returns(samples)
        request_sampler.expects(:merge!).with(samples)

        # simulate a failure in transmitting analytics events
        service.stubs(:analytic_event_data).raises(StandardError.new)

        @agent.send(:harvest_and_send_analytic_event_data)
      end

      def test_harvest_and_send_timeslice_data_merges_back_on_failure
        timeslices = [1,2,3]

        @agent.stats_engine.expects(:harvest!).returns(timeslices)
        @agent.service.stubs(:metric_data).raises('wat')
        @agent.stats_engine.expects(:merge!).with(timeslices)

        @agent.send(:harvest_and_send_timeslice_data)
      end

      def test_connect_retries_on_timeout
        service = @agent.service
        service.stubs(:connect).raises(Timeout::Error).then.returns(nil)
        @agent.stubs(:connect_retry_period).returns(0)
        @agent.send(:connect)
        assert(@agent.connected?)
      end

      def test_connect_retries_on_server_connection_exception
        service = @agent.service
        service.stubs(:connect).raises(ServerConnectionException).then.returns(nil)
        @agent.stubs(:connect_retry_period).returns(0)
        @agent.send(:connect)
        assert(@agent.connected?)
      end

      def test_connect_does_not_retry_if_keep_retrying_false
        @agent.service.expects(:connect).once.raises(Timeout::Error)
        @agent.send(:connect, :keep_retrying => false)
        assert(@agent.disconnected?)
      end

      def test_connect_does_not_retry_on_license_error
        @agent.service.expects(:connect).raises(NewRelic::Agent::LicenseException)
        @agent.send(:connect)
        assert(@agent.disconnected?)
      end

      def test_connect_does_not_reconnect_by_default
        @agent.stubs(:connected?).returns(true)
        @agent.service.expects(:connect).never
        @agent.send(:connect)
      end

      def test_connect_does_not_reconnect_if_disconnected
        @agent.stubs(:disconnected?).returns(true)
        @agent.service.expects(:connect).never
        @agent.send(:connect)
      end

      def test_connect_does_reconnect_if_forced
        @agent.stubs(:connected?).returns(true)
        @agent.service.expects(:connect)
        @agent.send(:connect, :force_reconnect => true)
      end

      def test_connect_settings
        settings = @agent.connect_settings
        assert settings.include?(:pid)
        assert settings.include?(:host)
        assert settings.include?(:app_name)
        assert settings.include?(:language)
        assert settings.include?(:agent_version)
        assert settings.include?(:environment)
        assert settings.include?(:settings)
      end

      def test_connect_settings_checks_environment_report_can_marshal
        @agent.service.stubs(:valid_to_marshal?).returns(false)
        assert_equal [], @agent.connect_settings[:environment]
      end

      def test_defer_start_if_resque_dispatcher_and_channel_manager_isnt_started_and_forkable
        NewRelic::LanguageSupport.stubs(:can_fork?).returns(true)
        NewRelic::Agent::PipeChannelManager.listener.stubs(:started?).returns(false)

        # :send_data_on_exit setting to avoid setting an at_exit
        with_config( :monitor_mode => true, :send_data_on_exit => false, :dispatcher => :resque ) do
          @agent.start
        end

        assert !@agent.started?
      end

      def test_doesnt_defer_start_if_resque_dispatcher_and_channel_manager_started
        NewRelic::Agent::PipeChannelManager.listener.stubs(:started?).returns(true)

        with_config( :monitor_mode => true, :send_data_on_exit => false, :dispatcher => :resque ) do
          @agent.start
        end

        assert @agent.started?
      end

      def test_doesnt_defer_start_for_resque_if_non_forking_platform
        NewRelic::LanguageSupport.stubs(:can_fork?).returns(false)
        NewRelic::Agent::PipeChannelManager.listener.stubs(:started?).returns(false)

        # :send_data_on_exit setting to avoid setting an at_exit
        with_config( :monitor_mode => true, :send_data_on_exit => false, :dispatcher => :resque ) do
          @agent.start
        end

        assert @agent.started?
      end

      def test_defer_start_if_no_application_name_configured
        logdev = with_array_logger( :error ) do
          with_config( :app_name => false ) do
            @agent.start
          end
        end
        logmsg = logdev.array.first.gsub(/\n/, '')

        assert !@agent.started?, "agent was started"
        assert_match( /No application name configured/i, logmsg )
      end

      def test_synchronize_with_harvest
        lock = Mutex.new
        @agent.stubs(:harvest_lock).returns(lock)
        @agent.harvest_lock.lock

        started = false
        done = false

        thread = Thread.new do
          started = true
          @agent.synchronize_with_harvest do
            done = true
          end
        end

        until started do
          sleep(0.001)
        end
        assert !done

        @agent.harvest_lock.unlock
        thread.join

        assert done
      end

      def test_harvest_from_container
        container = mock
        harvested_items = ['foo', 'bar', 'baz']
        container.expects(:harvest!).returns(harvested_items)
        items = @agent.send(:harvest_from_container, container, 'digglewumpus')
        assert_equal(harvested_items, items)
      end

      def test_harvest_from_container_with_error
        container = mock
        container.stubs(:harvest!).raises('an error')
        container.expects(:reset!)
        @agent.send(:harvest_from_container, container, 'digglewumpus')
      end

      def test_harvest_and_send_from_container
        container = mock('data container')
        items = [1, 2, 3]
        container.expects(:harvest!).returns(items)
        service = @agent.service
        service.expects(:dummy_endpoint).with(items)
        @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
      end

      def test_harvest_and_send_from_container_does_not_harvest_if_nothing_to_send
        container = mock('data container')
        items = []
        container.expects(:harvest!).returns(items)
        service = @agent.service
        service.expects(:dummy_endpoint).never
        @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
      end

      def test_harvest_and_send_from_container_resets_on_harvest_failure
        container = mock('data container')
        container.stubs(:harvest!).raises('an error')
        container.expects(:reset!)
        @agent.service.expects(:dummy_endpoint).never
        @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
      end

      def test_harvest_and_send_from_container_does_not_merge_on_serialization_failure
        container = mock('data container')
        container.stubs(:harvest!).returns([1,2,3])
        @agent.service.stubs(:dummy_endpoint).raises(SerializationError)
        container.expects(:merge!).never
        @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
      end

      def test_harvest_and_send_from_container_does_not_merge_on_unrecoverable_failure
        container = mock('data container')
        container.stubs(:harvest!).returns([1,2,3])
        @agent.service.expects(:dummy_endpoint).with([1,2,3]).raises(UnrecoverableServerException)
        container.expects(:merge!).never
        @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
      end

      def test_harvest_and_send_from_container_merges_on_other_failure
        container = mock('data container')
        container.stubs(:harvest!).returns([1,2,3])
        @agent.service.expects(:dummy_endpoint).with([1,2,3]).raises('other error')
        container.expects(:merge!).with([1,2,3])
        @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
      end

      def test_harvest_and_send_from_container_does_not_swallow_forced_errors
        container = mock('data container')
        container.stubs(:harvest!).returns([1])

        error_classes = [
          NewRelic::Agent::ForceRestartException,
          NewRelic::Agent::ForceDisconnectException
        ]

        error_classes.each do |cls|
          @agent.service.expects(:dummy_endpoint).with([1]).raises(cls.new)
          assert_raises(cls) do
            @agent.send(:harvest_and_send_from_container, container, 'dummy_endpoint')
          end
        end
      end

      def test_check_for_and_handle_agent_commands_does_not_swallow_forced_errors
        error_classes = [
          NewRelic::Agent::ForceRestartException,
          NewRelic::Agent::ForceDisconnectException
        ]

        error_classes.each do |cls|
          @agent.service.expects(:get_agent_commands).raises(cls.new)
          assert_raises(cls) do
            @agent.send(:check_for_and_handle_agent_commands)
          end
        end
      end

      def test_graceful_disconnect_should_emit_before_disconnect_event
        before_shutdown_call_count = 0
        @agent.events.subscribe(:before_shutdown) do
          before_shutdown_call_count += 1
        end
        @agent.stubs(:connected?).returns(true)
        @agent.send(:graceful_disconnect)
        assert_equal(1, before_shutdown_call_count)
      end

      def test_trap_signals_for_litespeed
        Signal.expects(:trap).with('SIGUSR1', 'IGNORE')
        Signal.expects(:trap).with('SIGTERM', 'IGNORE')

        with_config(:dispatcher => :litespeed) do
          @agent.trap_signals_for_litespeed
        end
      end

      def test_stop_worker_loop_runs_loop_before_exit_with_force_send_config
        fake_loop = mock
        fake_loop.expects(:run_task)
        fake_loop.stubs(:stop)

        @agent.instance_variable_set(:@worker_loop, fake_loop)

        with_config(:force_send => true) do
          @agent.stop_worker_loop
        end
      end

      def test_stop_worker_loop_doesnt_run_loop_if_force_send_is_false
        fake_loop = mock
        fake_loop.expects(:run_task).never
        fake_loop.stubs(:stop)

        @agent.instance_variable_set(:@worker_loop, fake_loop)

        with_config(:force_send => false) do
          @agent.stop_worker_loop
        end
      end

      def test_stop_worker_loop_stops_the_loop
        fake_loop = mock
        fake_loop.expects(:stop)

        @agent.instance_variable_set(:@worker_loop, fake_loop)

        @agent.stop_worker_loop
      end

      def test_untraced_graceful_disconnect_logs_errors
        NewRelic::Agent.stubs(:disable_all_tracing).raises(TestError, 'test')
        ::NewRelic::Agent.logger.expects(:error).with(is_a(TestError))

        @agent.untraced_graceful_disconnect
      end

      def test_revert_to_default_configuration_removes_manual_and_server_source
        manual_source = NewRelic::Agent::Configuration::ManualSource.new(:manual => "source")
        Agent.config.apply_config(manual_source)

        server_config = NewRelic::Agent::Configuration::ServerSource.new({})
        Agent.config.apply_config(server_config, 1)

        config_classes = NewRelic::Agent.config.config_stack.map(&:class)

        assert_includes config_classes, NewRelic::Agent::Configuration::ManualSource
        assert_includes config_classes, NewRelic::Agent::Configuration::ServerSource

        @agent.revert_to_default_configuration

        config_classes = NewRelic::Agent.config.config_stack.map(&:class)
        assert !config_classes.include?(NewRelic::Agent::Configuration::ManualSource)
        assert !config_classes.include?(NewRelic::Agent::Configuration::ServerSource)
      end
    end

    class AgentStartingTest < Minitest::Test
      def test_no_service_if_not_monitoring
        with_config(:monitor_mode => false) do
          agent = NewRelic::Agent::Agent.new
          assert_nil agent.service
        end
      end

      def test_abides_by_disabling_harvest_thread
        with_config(:disable_harvest_thread => true) do
          threads_before = Thread.list.length

          agent = NewRelic::Agent::Agent.new
          agent.send(:start_worker_thread)

          assert_equal threads_before, Thread.list.length
        end
      end

    end
  end
end
