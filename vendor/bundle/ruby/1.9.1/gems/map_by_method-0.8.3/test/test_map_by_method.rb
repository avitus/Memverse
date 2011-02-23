require File.dirname(__FILE__) + '/test_helper.rb'
require 'ostruct'

class TestMapByMethod < Test::Unit::TestCase

  def setup
  end
  
  def test_map
    assert_equal ['1','2','3'], [1,2,3].map_to_s
    assert_equal ['1','2','3'], [1,2,3].map_by_to_s
  end
  
  def test_collect
    assert_equal ['1','2','3'], [1,2,3].collect_to_s
    assert_equal ['1','2','3'], [1,2,3].collect_by_to_s
  end
  
  def test_reject
    assert_equal [1,3], [1,nil,3].reject_nil?
    assert_equal [1,3], [1,nil,3].reject_by_nil?
    assert_equal [1,3], [1,0,3].reject_zero?
    assert_equal [1,3], [1,0,3].reject_by_zero?
  end
  
  def test_select
    assert_equal [nil], [1,nil,3].select_nil?
    assert_equal ['1','3'], ['1','','3'].select_any?
    assert_equal ['1','3'], ['1','','3'].select_by_any?
  end
  
  def test_sort_by
    original = [OpenStruct.new(:name => "ZZZ"), OpenStruct.new(:name => "AAA")]
    expected = [OpenStruct.new(:name => "AAA"), OpenStruct.new(:name => "ZZZ")]
    assert_equal expected, original.sort_by_name
  end
  
  def test_group_by
    original = [
      OpenStruct.new(:name => "ZZZ", :group => "letters"), 
      OpenStruct.new(:name => "AAA", :group => "letters")
    ]
    expected = {"letters" => original.clone}
    assert_equal expected, original.group_by_group
  end

  def test_index_by
    original = [
      OpenStruct.new(:name => "ZZZ"), 
      OpenStruct.new(:name => "AAA")
    ]
    expected = {
      "ZZZ" => OpenStruct.new(:name => "ZZZ"), 
      "AAA" => OpenStruct.new(:name => "AAA")
    }
    assert_equal expected, original.index_by_name
  end
  
  def test_pass_args
    original = ["hello world", "hallo wereld", "ciao mondo"]
    expected = %w[hell hall ciao]
    assert_equal(expected, original.map_by_slice(0,4))
  end
  
  def test_pass_block
    original = ["hello world", "hallo wereld", "ciao mondo"]
    expected = ["[hello ]world", "[hallo ]wereld", "[ciao ]mondo"]
    assert_equal(expected, original.map_by_gsub(/^(.*)\s/) {|first_word| "[#{first_word}]" })
  end
  
end