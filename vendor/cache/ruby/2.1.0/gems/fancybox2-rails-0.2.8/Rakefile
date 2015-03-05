# encoding: UTF-8
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

# For checking remote fancybox version.
require 'open-uri'
require 'json'

# Path to fancybox bower.json.
$fancybox_bower = "https://raw.github.com/fancyapps/fancyBox/master/bower.json"

Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

task :default => :test

namespace :fancybox do
  desc "Get the local and remote fancybox versions."
  task :version do
    local = local_version
    remote = remote_version

    puts "local: v#{local}"
    puts "remote: v#{remote}"

    if local != remote
      warn "\nthere is a newer remote version available"
    end
  end
end

# Get the current local version of the vendored fancybox library.
#
# Returns the String representing the local version.
def local_version
  `grep ' * version:' vendor/assets/javascripts/jquery.fancybox.js | \
  cut -d ' ' -f 4`.chomp
end

# Get the current version of the remote version of the library. Uses
# the library's bower.json file to parse the version.
#
# Returns the String representing the remote version.
def remote_version
  JSON.parse(open($fancybox_bower).read)["version"]
end

task :travis do
  puts "Starting to run rake travis"
  system("export DISPLAY=:99.0 && bundle exec rake")
  raise "rake travis failed!" unless $?.exitstatus == 0
end
