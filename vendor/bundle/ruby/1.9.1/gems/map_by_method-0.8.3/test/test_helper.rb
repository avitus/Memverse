require 'test/unit'
require File.dirname(__FILE__) + '/../lib/map_by_method'

begin
  require 'active_support'
rescue LoadError
  require 'rubygems'
  gem 'activesupport'
  require 'active_support'
end