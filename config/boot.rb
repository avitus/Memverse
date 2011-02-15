require 'rubygems'

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  
  # RubyGems 1.5.0 seems to force use of the psych yaml parser if you
  # have it in your system. If you are having trouble parsing some yaml
  # files, or if you have yaml files which use merge keys (
  # http://redmine.ruby-lang.org/issues/show/4300 ), then you might need to
  # revert to using syck instead of psych.
  # 
  # I have libyaml installed, rvm builds 1.9.2 with libyaml, so its part
  # of my system. But ruby 1.9.2 doesnt make it the default yet. All worked
  # fine till 1.5.0, which by directly requiring psych cause it to get
  # loaded first and set as system yaml parser.
  # 
  # My workaround was to do the following early in the rails boot
  # sequence:
  # 
  #     require 'yaml'
  #     YAML::ENGINE.yamler= 'syck'   
  require 'yaml'
  YAML::ENGINE.yamler= 'syck'
  
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
  rescue Bundler::GemNotFound => e
    STDERR.puts e.message
    STDERR.puts "Try running `bundle install`."
    exit!
  end if File.exist?(gemfile)
