require_relative 'helper'

class TestConfig < Sidetiq::TestCase
  def setup
    @saved = Sidetiq.config
    Sidetiq.config = OpenStruct.new
  end

  def teardown
    Sidetiq.config = @saved
  end

  def test_configure
    Sidetiq.configure do |config|
      config.test = 42
    end

    assert_equal 42, Sidetiq.config.test
  end
end

