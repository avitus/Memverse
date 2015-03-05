require_relative 'helper'

class TestSubclassTracking < Sidetiq::TestCase
  class Foo
    extend Sidetiq::SubclassTracking
  end

  class Bar < Foo
  end

  class Baz < Bar
  end

  def test_subclasses_non_recursive
    assert_equal [Bar], Foo.subclasses
  end

  def test_subclasses_recursive
    assert_equal [Bar, Baz], Foo.subclasses(true)
  end
end

