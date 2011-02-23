
require File.join(File.dirname(__FILE__), %w[setup])

module TestLogging

  class TestLogEvent < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super

      @appender = EventAppender.new('test')
      @logger = ::Logging::Logger['TestLogger']
      @logger.add_appenders @appender

      @logger.info 'message 1'
      @event = @appender.event
    end

    def test_data
      assert_equal 'message 1', @event.data
    end

    def test_data_eq
      @event.data = 'message 2'
      assert_equal 'message 2', @event.data
    end

    def test_file
      assert_equal '', @event.file

      @logger.trace = true
      @logger.warn 'warning message'
      assert_match %r/test_log_event.rb\z/, @appender.event.file
    end

    def test_level
      assert_equal 1, @event.level
    end

    def test_level_eq
      @event.level = 3
      assert_equal 3, @event.level
    end

    def test_line
      assert_equal '', @event.file

      @logger.trace = true
      @logger.error 'error message'
      assert_equal 50, @appender.event.line
    end

    def test_logger
      assert_equal 'TestLogger', @event.logger
    end

    def test_logger_eq
      @event.logger = 'MyLogger'
      assert_equal 'MyLogger', @event.logger
    end

    def test_method
      assert_equal '', @event.file

      @logger.trace = true
      @logger.debug 'debug message'
      assert_equal 'test_method', @appender.event.method
    end

  end  # class TestLogEvent

  class EventAppender < ::Logging::Appender
    attr_reader :event
    def append( event ) @event = event end
  end

end  # module TestLogging

# EOF
