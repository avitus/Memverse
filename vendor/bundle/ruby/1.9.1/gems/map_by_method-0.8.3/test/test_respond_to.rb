require File.dirname(__FILE__) + '/test_helper'

class TestRespondTo < Test::Unit::TestCase
  def test_should_not_respond_to_each_pair_for_non_empty_array
    assert(![{}].respond_to?(:each_pair), "Arrays should not respond_to?(each_pair)")
  end
end
