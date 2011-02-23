require File.dirname(__FILE__) + '/test_helper.rb'
begin
  require 'rubygems'
  require 'active_record'
  gem 'mocha'
  require 'mocha'
rescue LoadError
  puts "MapByMethod tests require ActiveRecord and Mocha gems, even if you don't use them personally, the tests test them"
  exit 0
end

class Company < ActiveRecord::Base
end

class Employee < ActiveRecord::Base
end

class TestArAssociationProxy < Test::Unit::TestCase

  def setup
    Company.stubs(:columns).returns([
      stub(:name =>'id', :type => :integer, :default => 1, :type_cast_code => 1, :"number?" => true, :"text?" => false), 
      stub(:name =>'name', :type => :string, :default => nil, :"number?" => false, :type_cast_code => nil, :"text?" => true)])
    Company.stubs(:table_name).returns('companies')
    Company.stubs(:primary_key).returns('id')

    Employee.stubs(:columns).returns([
      stub(:name =>'id', :type => :integer, :default => 1, :type_cast_code => 1, :"number?" => true, :"text?" => false), 
      stub(:name =>'company_id', :type => :integer, :default => nil, :"number?" => true, :type_cast_code => nil, :"text?" => false), 
      stub(:name =>'name', :type => :string, :default => nil, :"number?" => false, :type_cast_code => nil, :"text?" => true)])
    Employee.stubs(:table_name).returns('employees')
    Employee.stubs(:primary_key).returns('id')

    connection = stub(:tables => @table_names, :quote => nil)
    ActiveRecord::Base.stubs(:connection).returns(connection)
    Company.stubs(:connection).returns(connection)
    Employee.stubs(:connection).returns(connection)

    Company.has_many :employees
    Employee.belongs_to :company
    
    @company = Company.new :name => "Dr Nic Academy", :id => 1
    @emp1 = Employee.new :name => "Dr Nic", :id => 1, :company_id => 1
    @emp1.stubs(:read_attribute).with("name").returns('Dr Nic')
    @emp2 = Employee.new :name => "Banjo", :id => 2, :company_id => 1
    @emp2.stubs(:read_attribute).with("name").returns('Banjo')

    @company.stubs(:"new_record?").returns(false)
    Employee.stubs(:find).returns([@emp1, @emp2]) # this will do since only the above data to mock
  end
  
  def test_map_by_association_attribute
    expected = ['Dr Nic', 'Banjo']
    assert_equal(expected, @company.employees.map_by_name)
  end
  
  def test_normal_map_by_association_attribute
    expected = ['Dr Nic', 'Banjo']
    assert_equal(expected, @company.employees.map {|emp| emp.name})
  end
  
end
