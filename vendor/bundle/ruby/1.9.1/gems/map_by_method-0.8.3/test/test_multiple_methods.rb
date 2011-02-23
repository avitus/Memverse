require File.dirname(__FILE__) + '/test_helper.rb'
require 'ostruct'

class TestMultipleMethods < Test::Unit::TestCase

  def setup
    @data = [
      OpenStruct.new(:name => 'Dr Nic', :amount => 300),
      OpenStruct.new(:name => 'Banjo', :amount => 500)
    ]
  end
  
  def test_map_normal
    assert_equal ['Dr Nic','Banjo'], @data.map_name
    assert_equal [300,500], @data.map_amount
  end
  
  def test_map_ands
    assert_equal [['Dr Nic',300],['Banjo',500]], @data.map_name_and_amount
    assert_equal [[300,'Dr Nic'],[500,'Banjo']], @data.map_amount_and_name
  end
  
end
