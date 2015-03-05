# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))
require 'new_relic/agent/audit_logger'
require 'new_relic/agent/null_logger'

class AuditLoggerTest < Minitest::Test
  def setup
    NewRelic::Agent.config.apply_config(:'audit_log.enabled' => true)

    @uri = "http://really.notreal"
    @marshaller = NewRelic::Agent::NewRelicService::Marshaller.new
    @dummy_data = {
      'foo' => [1, 2, 3],
      'bar' => {
        'baz' => 'qux',
        'jingle' => 'bells'
      }
    }
  end

  def setup_fake_logger
    @fakelog = StringIO.new
    @logger = NewRelic::Agent::AuditLogger.new
    @logger.stubs(:ensure_log_path).returns(@fakelog)
  end

  def assert_log_contains_string(str)
    @fakelog.rewind
    log_body = @fakelog.read
    assert(log_body.include?(str), "Expected log to contain string '#{str}'")
  end

  def test_never_setup_if_disabled
    with_config(:'audit_log.enabled' => false) do
      logger = NewRelic::Agent::AuditLogger.new
      logger.log_request(@uri, "hi there", @marshaller)
      assert(!logger.setup?, "Expected logger to not have been setup")
    end
  end

  def test_never_prepare_if_disabled
    with_config(:'audit_log.enabled' => false) do
      logger = NewRelic::Agent::AuditLogger.new
      marshaller = NewRelic::Agent::NewRelicService::Marshaller.new
      marshaller.expects(:prepare).never
      logger.log_request(@uri, "hi there", @marshaller)
    end
  end

  def test_log_formatter
    Socket.stubs(:gethostname).returns('dummyhost')
    formatter = NewRelic::Agent::AuditLogger.new.create_log_formatter
    time = '2012-01-01 00:00:00'
    msg = 'hello'
    result = formatter.call(Logger::INFO, time, 'bleh', msg)
    expected = "[2012-01-01 00:00:00 dummyhost (#{$$})] : hello\n"
    assert_equal(expected, result)
  end

  def test_ensure_path_returns_nil_with_bogus_path
    with_config(:'audit_log.path' => '/really/really/not/a/path') do
      FileUtils.stubs(:mkdir_p).raises(SystemCallError, "i'd rather not")
      logger = NewRelic::Agent::AuditLogger.new
      assert_nil(logger.ensure_log_path)
    end
  end

  def test_setup_logger_creates_null_logger_when_ensure_path_fails
    null_logger = NewRelic::Agent::NullLogger.new
    NewRelic::Agent::NullLogger.expects(:new).returns(null_logger)
    logger = NewRelic::Agent::AuditLogger.new
    logger.stubs(:ensure_log_path).returns(nil)

    logger.setup_logger
    logger.log_request(@uri, 'whatever', @marshaller)
  end

  def test_log_request_captures_system_call_errors
    logger = NewRelic::Agent::AuditLogger.new
    dummy_sink = StringIO.new
    dummy_sink.stubs(:write).raises(SystemCallError, "nope")
    logger.stubs(:ensure_log_path).returns(dummy_sink)

    # In 1.9.2 and later, Logger::LogDevice#write captures any errors during
    # writing and spits them out with Kernel#warn.
    # This just silences that output to keep the test output uncluttered.
    Logger::LogDevice.any_instance.stubs(:warn)

    logger.log_request(@uri, 'whatever', @marshaller)
  end

  def test_prepares_data_with_identity_encoder
    setup_fake_logger
    data = { 'foo' => 'bar' }
    identity_encoder = NewRelic::Agent::NewRelicService::Encoders::Identity
    @marshaller.expects(:prepare).with(data, { :encoder => identity_encoder })
    @logger.log_request(@uri, data, @marshaller)
  end

  def test_logs_inspect_with_pruby_marshaller
    setup_fake_logger
    pruby_marshaller = NewRelic::Agent::NewRelicService::PrubyMarshaller.new
    @logger.log_request(@uri, @dummy_data, pruby_marshaller)
    assert_log_contains_string(@dummy_data.inspect)
  end

  def test_logs_json_with_json_marshaller
    marshaller_cls = NewRelic::Agent::NewRelicService::JsonMarshaller
    if marshaller_cls.is_supported?
      setup_fake_logger
      json_marshaller = marshaller_cls.new
      @logger.log_request(@uri, @dummy_data, json_marshaller)
      assert_log_contains_string(JSON.dump(@dummy_data))
    end
  end

  def test_should_cache_hostname
    Socket.expects(:gethostname).once.returns('cachey-mccaherson')
    setup_fake_logger
    3.times do
      @logger.log_request(@uri, @dummy_data, @marshaller)
    end
    assert_log_contains_string('cachey-mccaherson')
  end
end
