require 'helper'
require 'sidekiq/cli'
require 'tempfile'

cli = Sidekiq::CLI.instance
def cli.die(code)
  @code = code
end

def cli.valid?
  !@code
end

class TestCli < Sidekiq::Test
  describe 'with cli' do

    before do
      @cli = Sidekiq::CLI.instance
    end

    it 'blows up with an invalid require' do
      assert_raises ArgumentError do
        @cli.parse(['sidekiq', '-r', 'foobar'])
      end
    end

    it 'requires the specified Ruby code' do
      @cli.parse(['sidekiq', '-r', './test/fake_env.rb'])
      assert($LOADED_FEATURES.any? { |x| x =~ /fake_env/ })
      assert @cli.valid?
    end

    it 'boots rails' do
      refute defined?(::Rails)
      @cli.parse(['sidekiq', '-r', './myapp'])
      assert defined?(::Rails)
    end

    it 'changes concurrency' do
      @cli.parse(['sidekiq', '-c', '60', '-r', './test/fake_env.rb'])
      assert_equal 60, Sidekiq.options[:concurrency]
    end

    it 'changes queues' do
      @cli.parse(['sidekiq', '-q', 'foo', '-r', './test/fake_env.rb'])
      assert_equal ['foo'], Sidekiq.options[:queues]
    end

    it 'accepts a process index' do
      @cli.parse(['sidekiq', '-i', '7', '-r', './test/fake_env.rb'])
      assert_equal 7, Sidekiq.options[:index]
    end

    it 'accepts a stringy process index' do
      @cli.parse(['sidekiq', '-i', 'worker.7', '-r', './test/fake_env.rb'])
      assert_equal 7, Sidekiq.options[:index]
    end

    it 'sets strictly ordered queues if weights are not present' do
      @cli.parse(['sidekiq', '-q', 'foo', '-q', 'bar', '-r', './test/fake_env.rb'])
      assert_equal true, !!Sidekiq.options[:strict]
    end

    it 'does not set strictly ordered queues if weights are present' do
      @cli.parse(['sidekiq', '-q', 'foo,3', '-r', './test/fake_env.rb'])
      assert_equal false, !!Sidekiq.options[:strict]
    end

    it 'does not set strictly ordered queues if weights are present with multiple queues' do
      @cli.parse(['sidekiq', '-q', 'foo,3', '-q', 'bar', '-r', './test/fake_env.rb'])
      assert_equal false, !!Sidekiq.options[:strict]
    end

    it 'changes timeout' do
      @cli.parse(['sidekiq', '-t', '30', '-r', './test/fake_env.rb'])
      assert_equal 30, Sidekiq.options[:timeout]
    end

    it 'handles multiple queues with weights' do
      @cli.parse(['sidekiq', '-q', 'foo,3', '-q', 'bar', '-r', './test/fake_env.rb'])
      assert_equal %w(foo foo foo bar), Sidekiq.options[:queues]
    end

    it 'handles queues with multi-word names' do
      @cli.parse(['sidekiq', '-q', 'queue_one', '-q', 'queue-two', '-r', './test/fake_env.rb'])
      assert_equal %w(queue_one queue-two), Sidekiq.options[:queues]
    end

    it 'handles queues with dots in the name' do
      @cli.parse(['sidekiq', '-q', 'foo.bar', '-r', './test/fake_env.rb'])
      assert_equal ['foo.bar'], Sidekiq.options[:queues]
    end

    it 'sets verbose' do
      old = Sidekiq.logger.level
      @cli.parse(['sidekiq', '-v', '-r', './test/fake_env.rb'])
      assert_equal Logger::DEBUG, Sidekiq.logger.level
      # If we leave the logger at DEBUG it'll add a lot of noise to the test output
      Sidekiq.options.delete(:verbose)
      Sidekiq.logger.level = old
    end

    describe 'with logfile' do
      before do
        @old_logger = Sidekiq.logger
        @tmp_log_path = '/tmp/sidekiq.log'
      end

      after do
        Sidekiq.logger = @old_logger
        Sidekiq.options.delete(:logfile)
        File.unlink @tmp_log_path if File.exists?(@tmp_log_path)
      end

      it 'sets the logfile path' do
        @cli.parse(['sidekiq', '-L', @tmp_log_path, '-r', './test/fake_env.rb'])

        assert_equal @tmp_log_path, Sidekiq.options[:logfile]
      end

      it 'creates and writes to a logfile' do
        @cli.parse(['sidekiq', '-L', @tmp_log_path, '-r', './test/fake_env.rb'])

        Sidekiq.logger.info('test message')

        assert_match(/test message/, File.read(@tmp_log_path), "didn't include the log message")
      end

      it 'appends messages to a logfile' do
        File.open(@tmp_log_path, 'w') do |f|
          f.puts 'already existant log message'
        end

        @cli.parse(['sidekiq', '-L', @tmp_log_path, '-r', './test/fake_env.rb'])

        Sidekiq.logger.info('test message')

        log_file_content = File.read(@tmp_log_path)
        assert_match(/already existant/, log_file_content, "didn't include the old message")
        assert_match(/test message/, log_file_content, "didn't include the new message")
      end
    end

    describe 'with pidfile' do
      before do
        @tmp_file = Tempfile.new('sidekiq-test')
        @tmp_path = @tmp_file.path
        @tmp_file.close!

        @cli.parse(['sidekiq', '-P', @tmp_path, '-r', './test/fake_env.rb'])
      end

      after do
        File.unlink @tmp_path if File.exist? @tmp_path
      end

      it 'sets pidfile path' do
        assert_equal @tmp_path, Sidekiq.options[:pidfile]
      end

      it 'writes pidfile' do
        assert_equal File.read(@tmp_path).strip.to_i, Process.pid
      end
    end

    describe 'with config file' do
      before do
        @cli.parse(['sidekiq', '-C', './test/config.yml'])
      end

      it 'takes a path' do
        assert_equal './test/config.yml', Sidekiq.options[:config_file]
      end

      it 'sets verbose' do
        refute Sidekiq.options[:verbose]
      end

      it 'sets require file' do
        assert_equal './test/fake_env.rb', Sidekiq.options[:require]
      end

      it 'does not set environment' do
        assert_equal nil, Sidekiq.options[:environment]
      end

      it 'sets concurrency' do
        assert_equal 50, Sidekiq.options[:concurrency]
      end

      it 'sets pid file' do
        assert_equal '/tmp/sidekiq-config-test.pid', Sidekiq.options[:pidfile]
      end

      it 'sets logfile' do
        assert_equal '/tmp/sidekiq.log', Sidekiq.options[:logfile]
      end

      it 'sets queues' do
        assert_equal 2, Sidekiq.options[:queues].count { |q| q == 'very_often' }
        assert_equal 1, Sidekiq.options[:queues].count { |q| q == 'seldom' }
      end
    end

    describe 'with env based config file' do
      before do
        @cli.parse(['sidekiq', '-e', 'staging', '-C', './test/env_based_config.yml'])
      end

      it 'takes a path' do
        assert_equal './test/env_based_config.yml', Sidekiq.options[:config_file]
      end

      it 'sets verbose' do
        refute Sidekiq.options[:verbose]
      end

      it 'sets require file' do
        assert_equal './test/fake_env.rb', Sidekiq.options[:require]
      end

      it 'sets environment' do
        assert_equal 'staging', Sidekiq.options[:environment]
      end

      it 'sets concurrency' do
        assert_equal 5, Sidekiq.options[:concurrency]
      end

      it 'sets pid file' do
        assert_equal '/tmp/sidekiq-config-test.pid', Sidekiq.options[:pidfile]
      end

      it 'sets logfile' do
        assert_equal '/tmp/sidekiq.log', Sidekiq.options[:logfile]
      end

      it 'sets queues' do
        assert_equal 2, Sidekiq.options[:queues].count { |q| q == 'very_often' }
        assert_equal 1, Sidekiq.options[:queues].count { |q| q == 'seldom' }
      end
    end

    describe 'with config file and flags' do
      before do
        # We need an actual file here.
        @tmp_lib_path = '/tmp/require-me.rb'
        File.open(@tmp_lib_path, 'w') do |f|
          f.puts "# do work"
        end

        @tmp_file = Tempfile.new('sidekiqr')
        @tmp_path = @tmp_file.path
        @tmp_file.close!

        @cli.parse(['sidekiq',
                    '-C', './test/config.yml',
                    '-e', 'snoop',
                    '-c', '100',
                    '-r', @tmp_lib_path,
                    '-P', @tmp_path,
                    '-q', 'often,7',
                    '-q', 'seldom,3'])
      end

      after do
        File.unlink @tmp_lib_path if File.exist? @tmp_lib_path
        File.unlink @tmp_path if File.exist? @tmp_path
      end

      it 'uses concurrency flag' do
        assert_equal 100, Sidekiq.options[:concurrency]
      end

      it 'uses require file flag' do
        assert_equal @tmp_lib_path, Sidekiq.options[:require]
      end

      it 'uses environment flag' do
        assert_equal 'snoop', Sidekiq.options[:environment]
      end

      it 'uses pidfile flag' do
        assert_equal @tmp_path, Sidekiq.options[:pidfile]
      end

      it 'sets queues' do
        assert_equal 7, Sidekiq.options[:queues].count { |q| q == 'often' }
        assert_equal 3, Sidekiq.options[:queues].count { |q| q == 'seldom' }
      end
    end

    describe 'Sidekiq::CLI#parse_queues' do
      describe 'when weight is present' do
        it 'concatenates queues by factor of weight and sets strict to false' do
          opts = { strict: true }
          @cli.__send__ :parse_queues, opts, [['often', 7], ['repeatedly', 3]]
          @cli.__send__ :parse_queues, opts, [['once']]
          assert_equal (%w[often] * 7 + %w[repeatedly] * 3 + %w[once]), opts[:queues]
          assert !opts[:strict]
        end
      end

      describe 'when weight is not present' do
        it 'returns queues and sets strict' do
          opts = { strict: true }
          @cli.__send__ :parse_queues, opts, [['once'], ['one_time']]
          @cli.__send__ :parse_queues, opts, [['einmal']]
          assert_equal %w[once one_time einmal], opts[:queues]
          assert opts[:strict]
        end
      end
    end

    describe 'Sidekiq::CLI#parse_queue' do
      describe 'when weight is present' do
        it 'concatenates queue to opts[:queues] weight number of times and sets strict to false' do
          opts = { strict: true }
          @cli.__send__ :parse_queue, opts, 'often', 7
          assert_equal %w[often] * 7, opts[:queues]
          assert !opts[:strict]
        end
      end

      describe 'when weight is not present' do
        it 'concatenates queue to opts[:queues] once and leaves strict true' do
          opts = { strict: true }
          @cli.__send__ :parse_queue, opts, 'once', nil
          assert_equal %w[once], opts[:queues]
          assert opts[:strict]
        end
      end
    end
  end

end
