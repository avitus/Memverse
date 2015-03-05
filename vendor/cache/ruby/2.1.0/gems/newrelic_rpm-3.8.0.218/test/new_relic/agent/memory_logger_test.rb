# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))
require 'new_relic/agent/memory_logger'

class MemoryLoggerTest < Minitest::Test
  LEVELS = [:fatal, :error, :warn, :info, :debug]

  def setup
    @logger = NewRelic::Agent::MemoryLogger.new
  end

  def test_proxies_messages_to_real_logger_on_dump
    LEVELS.each do |level|
      @logger.send(level, "message at #{level}")
    end

    real_logger = mock

    # This is needed for the expectation on #warn (also defined in Kernel) to
    # work with old versions of Mocha.
    def real_logger.warn(*); end

    real_logger.expects(:fatal).with("message at fatal")
    real_logger.expects(:error).with("message at error")
    real_logger.expects(:warn).with("message at warn")
    real_logger.expects(:info).with("message at info")
    real_logger.expects(:debug).with("message at debug")

    @logger.dump(real_logger)
  end

  def test_proxies_multiple_messages_with_a_single_call
    @logger.info('a', 'b', 'c')

    real_logger = stub
    real_logger.expects(:info).with('a', 'b', 'c')

    @logger.dump(real_logger)
  end

  def test_proxies_through_calls_to_log_exception
    e = Exception.new
    @logger.log_exception(:fatal, e, :error)

    real_logger = stub
    real_logger.expects(:log_exception).with(:fatal, e, :error)

    @logger.dump(real_logger)
  end
end
