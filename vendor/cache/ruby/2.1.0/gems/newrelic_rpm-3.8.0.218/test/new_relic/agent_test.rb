# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','test_helper'))
require 'ostruct'

module NewRelic
  # mostly this class just passes through to the active agent
  # through the agent method or the control instance through
  # NewRelic::Control.instance . But it's nice to make sure.
  class MainAgentTest < Minitest::Test
    include NewRelic::Agent::MethodTracer

    def setup
      NewRelic::Agent.reset_config
      NewRelic::Agent.instance.stubs(:start_worker_thread)
    end

    def teardown
      NewRelic::Agent::TransactionState.clear
    end

    def test_shutdown
      mock_agent = mocked_agent
      mock_agent.expects(:shutdown).with({})
      NewRelic::Agent.shutdown
    end

    def test_shutdown_removes_manual_startup_config
      NewRelic::Agent.manual_start(:monitor_mode => true, :license_key => "a" * 40, :some_absurd_setting => true)
      assert NewRelic::Agent.config[:some_absurd_setting]
      NewRelic::Agent.shutdown
      assert !NewRelic::Agent.config[:some_absurd_setting]
    end

    def test_shutdown_removes_server_config
      NewRelic::Agent.manual_start(:monitor_mode => true, :license_key => "a" * 40)
      NewRelic::Agent.instance.service = default_service
      NewRelic::Agent.instance.finish_setup('agent_config' =>
                                            { :some_absurd_setting => true })
      assert NewRelic::Agent.config[:some_absurd_setting]
      NewRelic::Agent.shutdown
      assert !NewRelic::Agent.config[:some_absurd_setting]
    end

    def test_finish_setup_applied_server_side_config
      with_config({ :'transction_tracer.enabled' => true,
                    'error_collector.enabled' => true,
                    :log_level => 'info' }, :level => 2) do
        NewRelic::Agent.instance.finish_setup('log_level' => 'debug',
         'agent_config' => { 'transaction_tracer.enabled' => false },
                                         'collect_errors' => false)
        assert !NewRelic::Agent.config[:'transaction_tracer.enabled']
        assert !NewRelic::Agent.config[:'error_collector.enabled']
        assert_equal 'debug', NewRelic::Agent.config[:log_level]
      end
    end

    def test_after_fork
      mock_agent = mocked_agent
      mock_agent.expects(:after_fork).with({})
      NewRelic::Agent.after_fork
    end

    def test_reset_stats
      mock_agent = mocked_agent
      mock_agent.expects(:drop_buffered_data)
      NewRelic::Agent.reset_stats
    end

    def test_manual_start_default
      mock_control = mocked_control
      mock_control.expects(:init_plugin).with({:agent_enabled => true, :sync_startup => true})
      NewRelic::Agent.manual_start
    end

    def test_manual_start_with_opts
      mock_control = mocked_control
      mock_control.expects(:init_plugin).with({:agent_enabled => true, :sync_startup => false})
      NewRelic::Agent.manual_start(:sync_startup => false)
    end

    def test_manual_start_starts_channel_listener
      NewRelic::Agent::PipeChannelManager.listener.expects(:start).at_least_once
      NewRelic::Agent.manual_start(:start_channel_listener => true)
      NewRelic::Agent.shutdown
    end

    def test_get_stats
      agent = mocked_agent
      mock_stats_engine = mock('stats_engine')
      agent.expects(:stats_engine).returns(mock_stats_engine)
      mock_stats_engine.expects(:get_stats).with('Custom/test/metric', false)
      NewRelic::Agent.get_stats('Custom/test/metric')
    end

    # note that this is the same as get_stats above, they're just aliases
    def test_get_stats_no_scope
      agent = mocked_agent
      mock_stats_engine = mock('stats_engine')
      agent.expects(:stats_engine).returns(mock_stats_engine)
      mock_stats_engine.expects(:get_stats).with('Custom/test/metric', false)
      NewRelic::Agent.get_stats_no_scope('Custom/test/metric')
    end

    def test_agent_not_started
      old_agent = NewRelic::Agent.agent
      NewRelic::Agent.instance_eval { @agent = nil }
      assert_raises(RuntimeError) do
        NewRelic::Agent.agent
      end
      NewRelic::Agent.instance_eval { @agent = old_agent }
    end

    def test_agent_when_started
      old_agent = NewRelic::Agent.agent
      NewRelic::Agent.instance_eval { @agent = 'not nil' }
      assert_equal('not nil', NewRelic::Agent.agent, "should return the value from @agent")
      NewRelic::Agent.instance_eval { @agent = old_agent }
    end

    def test_abort_transaction_bang
      NewRelic::Agent::Transaction.expects(:abort_transaction!)
      NewRelic::Agent.abort_transaction!
    end

    def test_is_transaction_traced_true
      NewRelic::Agent::TransactionState.get.record_tt = true
      assert_equal(true, NewRelic::Agent.is_transaction_traced?, 'should be true since the thread local is set')
    end

    def test_is_transaction_traced_blank
      NewRelic::Agent::TransactionState.get.record_tt = nil
      assert_equal(true, NewRelic::Agent.is_transaction_traced?, 'should be true since the thread local is not set')
    end

    def test_is_transaction_traced_false
      NewRelic::Agent::TransactionState.get.record_tt = false
      assert_equal(false, NewRelic::Agent.is_transaction_traced?, 'should be false since the thread local is false')
    end

    def test_is_sql_recorded_true
      NewRelic::Agent::TransactionState.get.record_sql = true
      assert_equal(true, NewRelic::Agent.is_sql_recorded?, 'should be true since the thread local is set')
    end

    def test_is_sql_recorded_blank
      NewRelic::Agent::TransactionState.get.record_sql = nil
      assert_equal(true, NewRelic::Agent.is_sql_recorded?, 'should be true since the thread local is not set')
    end

    def test_is_sql_recorded_false
      NewRelic::Agent::TransactionState.get.record_sql = false
      assert_equal(false, NewRelic::Agent.is_sql_recorded?, 'should be false since the thread local is false')
    end

    def test_is_execution_traced_true
      NewRelic::Agent::TransactionState.get.untraced = [true, true]
      assert_equal(true, NewRelic::Agent.is_execution_traced?, 'should be true since the thread local is set')
    end

    def test_is_execution_traced_blank
      NewRelic::Agent::TransactionState.get.untraced = nil
      assert_equal(true, NewRelic::Agent.is_execution_traced?, 'should be true since the thread local is not set')
    end

    def test_is_execution_traced_empty
      NewRelic::Agent::TransactionState.get.untraced = []
      assert_equal(true, NewRelic::Agent.is_execution_traced?, 'should be true since the thread local is an empty array')
    end

    def test_is_execution_traced_false
      NewRelic::Agent::TransactionState.get.untraced = [true, false]
      assert_equal(false, NewRelic::Agent.is_execution_traced?, 'should be false since the thread local stack has the last element false')
    end

    def test_instance
      assert_equal(NewRelic::Agent.agent, NewRelic::Agent.instance, "should return the same agent for both identical methods")
    end

    def test_register_report_channel
      NewRelic::Agent.register_report_channel(:channel_id)
      assert NewRelic::Agent::PipeChannelManager.channels[:channel_id] \
        .kind_of?(NewRelic::Agent::PipeChannelManager::Pipe)
      NewRelic::Agent::PipeChannelManager.listener.close_all_pipes
    end

    def test_record_metric
      dummy_engine = NewRelic::Agent.agent.stats_engine
      dummy_engine.expects(:record_metrics).with('foo', 12)
      NewRelic::Agent.record_metric('foo', 12)
    end

    def test_record_metric_accepts_hash
      dummy_engine = NewRelic::Agent.agent.stats_engine
      stats_hash = {
        :count => 12,
        :total => 42,
        :min   => 1,
        :max   => 5,
        :sum_of_squares => 999
      }
      expected_stats = NewRelic::Agent::Stats.new()
      expected_stats.call_count = 12
      expected_stats.total_call_time = 42
      expected_stats.total_exclusive_time = 42
      expected_stats.min_call_time = 1
      expected_stats.max_call_time = 5
      expected_stats.sum_of_squares = 999
      dummy_engine.expects(:record_metrics).with('foo', expected_stats)
      NewRelic::Agent.record_metric('foo', stats_hash)
    end

    def test_record_metric_sets_default_hash_values_for_missing_keys
      dummy_engine = NewRelic::Agent.agent.stats_engine
      incomplete_stats_hash = {
        :count => 12,
        :max   => 5,
        :sum_of_squares => 999
      }

      expected_stats = NewRelic::Agent::Stats.new()
      expected_stats.call_count = 12
      expected_stats.total_call_time = 0.0
      expected_stats.total_exclusive_time = 0.0
      expected_stats.min_call_time = 0.0
      expected_stats.max_call_time = 5
      expected_stats.sum_of_squares = 999

      dummy_engine.expects(:record_metrics).with('foo', expected_stats)
      NewRelic::Agent.record_metric('foo', incomplete_stats_hash)
    end

    def test_increment_metric
      dummy_engine = NewRelic::Agent.agent.stats_engine
      dummy_stats = mock
      dummy_stats.expects(:increment_count).with(12)
      dummy_engine.expects(:record_metrics).with('foo').yields(dummy_stats)
      NewRelic::Agent.increment_metric('foo', 12)
    end

    class Transactor
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      def txn
        yield
      end
      add_transaction_tracer :txn

      def task_txn
        yield
      end
      add_transaction_tracer :task_txn, :category => :task
    end

    def test_set_transaction_name
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('new_name')
      end
      assert engine.lookup_stats('Controller/new_name')
    end

    def test_get_transaction_name_returns_nil_outside_transaction
      assert_equal nil, NewRelic::Agent.get_transaction_name
    end

    def test_get_transaction_name_returns_the_default_txn_name
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        assert_equal 'NewRelic::MainAgentTest::Transactor/txn', NewRelic::Agent.get_transaction_name
      end
    end

    def test_get_transaction_name_returns_what_I_set
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('a_new_name')
        assert_equal 'a_new_name', NewRelic::Agent.get_transaction_name
      end
    end

    def test_get_txn_name_and_set_txn_name_preserves_category
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('a_new_name', :category => :task)
        new_name = NewRelic::Agent.get_transaction_name + "2"
        NewRelic::Agent.set_transaction_name(new_name)
      end
      assert engine.lookup_stats('OtherTransaction/Background/a_new_name2')
    end

    def test_set_transaction_name_applies_proper_scopes
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        trace_execution_scoped('Custom/something') {}
        NewRelic::Agent.set_transaction_name('new_name')
      end
      assert engine.lookup_stats('Custom/something', 'Controller/new_name')
    end

    def test_set_transaction_name_sets_tt_name
      sampler = NewRelic::Agent.instance.transaction_sampler
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('new_name')
      end
      assert_equal 'Controller/new_name', sampler.last_sample.params[:path]
    end

    def test_set_transaction_name_gracefully_fails_when_frozen
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        NewRelic::Agent::Transaction.current.freeze_name
        NewRelic::Agent.set_transaction_name('new_name')
      end
      assert_nil engine.lookup_stats('Controller/new_name')
    end

    def test_set_transaction_name_applies_category
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('new_name', :category => :task)
      end
      assert engine.lookup_stats('OtherTransaction/Background/new_name')
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('new_name', :category => :rack)
      end
      assert engine.lookup_stats('Controller/Rack/new_name')
      Transactor.new.txn do
        NewRelic::Agent.set_transaction_name('new_name', :category => :sinatra)
      end
      assert engine.lookup_stats('Controller/Sinatra/new_name')
    end

    def test_set_transaction_name_uses_current_txn_category_default
      engine = NewRelic::Agent.instance.stats_engine
      engine.reset!
      Transactor.new.task_txn do
        NewRelic::Agent.set_transaction_name('new_name')
      end
      assert engine.lookup_stats('OtherTransaction/Background/new_name')
    end

    # It's not uncommon for customers to conclude a rescue block with a call to
    # notice_error.  We should always return nil, which mean less folks
    # unexpectedly get a noticed error Hash returned from their methods.
    def test_notice_error_returns_nil
      begin
        raise "WTF"
      rescue => e
        assert_equal nil, ::NewRelic::Agent.notice_error(e)
      end
    end

    def test_eventing_helpers
      called = false
      NewRelic::Agent.subscribe(:boo) { called = true }
      NewRelic::Agent.notify(:boo)
      assert called
    end

    private

    def mocked_agent
      agent = mock('agent')
      NewRelic::Agent.stubs(:agent).returns(agent)
      agent
    end

    def mocked_control
      server = NewRelic::Control::Server.new('localhost', 3000)
      control = OpenStruct.new(:license_key => 'abcdef',
                               :server => server)
      control.instance_eval do
        def [](key)
          nil
        end

        def fetch(k,d)
          nil
        end
      end

      NewRelic::Control.stubs(:instance).returns(control)
      control
    end
  end
end
