require_relative 'helper'

class TestVersion < Sidetiq::TestCase
  def test_major
    assert_instance_of Fixnum, Sidetiq::VERSION::MAJOR
  end

  def test_minor
    assert_instance_of Fixnum, Sidetiq::VERSION::MINOR
  end

  def test_patch
    assert_instance_of Fixnum, Sidetiq::VERSION::PATCH
  end

  def test_string
    assert_equal Sidetiq::VERSION::STRING, [Sidetiq::VERSION::MAJOR,
                                            Sidetiq::VERSION::MINOR, Sidetiq::VERSION::PATCH,
                                            Sidetiq::VERSION::SUFFIX].compact.join('.')
  end
end

