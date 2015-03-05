#!/usr/bin/env ruby
# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

# This makes sure that the Multiverse environment loads with the gem
# version of Minitest, which we use throughout, not the one in stdlib on
# Rubies starting with 1.9.x
require 'rubygems'
require 'base64'

require File.expand_path(File.join(File.dirname(__FILE__), 'environment'))

module Multiverse
  class Suite
    include Color
    attr_accessor :directory, :opts

    def initialize(directory, opts={})
      self.directory  = directory
      self.opts       = opts
      ENV["VERBOSE"]  = '1' if opts[:verbose]
    end

    def self.encode_options(decoded_opts)
      Base64.encode64(Marshal.dump(decoded_opts)).gsub("\n", "")
    end

    def self.decode_options(encoded_opts)
      Marshal.load(Base64.decode64(encoded_opts))
    end

    def suite
      File.basename(directory)
    end

    def seed
      opts.fetch(:seed, "")
    end

    def debug
      opts.fetch(:debug, false)
    end

    def names
      opts.fetch(:names, [])
    end

    def filter_env
      value = opts.fetch(:env, nil)
      value = value.to_i if value
    end

    def filter_file
      opts.fetch(:file, nil)
    end

    def clean_gemfiles(env_index)
      FileUtils.rm_rf File.join(directory, "Gemfile.#{env_index}")
      FileUtils.rm_rf File.join(directory, "Gemfile.#{env_index}.lock")
    end


    def environments
      @environments ||= (
        Dir.chdir directory
        Envfile.new(File.join(directory, 'Envfile'))
      )
    end

    # load the environment for this suite after we've forked
    def load_dependencies(gemfile_text, env_index)
      ENV["BUNDLE_GEMFILE"] = "Gemfile.#{env_index}"
      clean_gemfiles(env_index)
      begin
        generate_gemfile(gemfile_text, env_index)
        bundle
      rescue => e
        puts "#{e.class}: #{e}"
        puts "Fast local bundle failed.  Attempting to install from rubygems.org"
        clean_gemfiles(env_index)
        generate_gemfile(gemfile_text, env_index, false)
        bundle
      end
      print_environment
    end

    def bundle
      require 'rubygems'
      require 'bundler'
      bundler_out = `bundle`
      puts bundler_out if verbose? || $? != 0
      raise "bundle command failed with (#{$?})" unless $? == 0
      Bundler.require
    end

    def generate_gemfile(gemfile_text, env_index, local = true)
      gemfile = File.join(Dir.pwd, "Gemfile.#{env_index}")
      File.open(gemfile,'w') do |f|
        f.puts '  source :rubygems' unless local
        f.print gemfile_text
        f.puts newrelic_gemfile_line unless gemfile_text =~ /^\s*gem .newrelic_rpm./
        f.puts jruby_openssl_line unless gemfile_text =~ /^\s*gem .jruby-openssl./
        f.puts minitest_line unless gemfile_text =~ /^\s*gem .minitest[^_]./

        rbx_gemfile_lines(f, gemfile_text)

        f.puts "  gem 'mocha', '0.14.0', :require => false"

        if debug
          f.puts "  gem 'pry'"
        end
      end
      puts yellow("Gemfile.#{env_index} set to:") if verbose?
      puts File.open(gemfile).read if verbose?
    end

    def newrelic_gemfile_line
      line = ENV['NEWRELIC_GEMFILE_LINE'] if ENV['NEWRELIC_GEMFILE_LINE']
      path = ENV['NEWRELIC_GEM_PATH'] || '../../../..'
      line ||= "  gem 'newrelic_rpm', :path => '#{path}'"
      line
    end

    def rbx_gemfile_lines(f, gemfile_text)
      return unless is_rbx?

      f.puts "gem 'rubysl', :platforms => [:rbx]" unless gemfile_text =~ /^\s*gem .rubysl./
      f.puts "gem 'json', :platforms => [:rbx]" unless gemfile_text =~ /^\s*gem .json./
      f.puts "gem 'racc', :platforms => [:rbx]" unless gemfile_text =~ /^\s*gem .racc./
    end

    def is_rbx?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
    end

    def jruby_openssl_line
      "gem 'jruby-openssl', :require => false, :platforms => [:jruby]"
    end

    def minitest_line
      "gem 'minitest', '~> 4.7.5', :require => false"
    end

    def print_environment
      puts yellow("Environment loaded with:") if verbose?
      gems = Bundler.definition.specs.inject([]) do |m, s|
        next m if s.name == 'bundler'
        m.push "#{s.name} (#{s.version})"
        m
      end.sort
      puts(gems.join(', '))
    end

    def execute_child_environment(env_index)
      with_clean_env do
        log_test_running_process
        configure_before_bundling

        gemfile_text = environments[env_index]

        load_dependencies(gemfile_text, env_index)

        configure_child_environment
        execute_ruby_files
        trigger_test_run
      end
    end

    def log_test_running_process
      puts yellow("Starting tests in child PID #{Process.pid}\n")
    end

    def should_serialize?
      ENV['SERIALIZE'] || debug
    end

    # Load the test suite's environment and execute it.
    #
    # Normally we fork to do this, and wait for the child to exit, to avoid
    # polluting the parent process with test dependencies.  JRuby doesn't
    # implement #fork so we resort to a hack.  We exec this lib file, which
    # loads a new JVM for the tests to run in.
    def execute
      if environments.condition && !environments.condition.call
        puts yellow("SKIPPED #{directory.inspect}: #{environments.skip_message}")
        return
      end

      label = should_serialize? ? 'serial' : 'parallel'
      env_count = filter_env ? 1 : environments.size
      puts yellow("\nRunning #{directory.inspect} in #{env_count} environments in #{label}")

      environments.before.call if environments.before
      if should_serialize?
        execute_serial
      else
        execute_parallel
      end
      environments.after.call if environments.after
    end

    def execute_serial
      with_each_environment do |_, i|
        if debug
          execute_in_foreground(i)
        else
          execute_in_background(i)
        end
      end
    end

    def execute_parallel
      threads = []
      with_each_environment do |_, i|
        threads << Thread.new { execute_in_background(i) }
      end
      threads.each {|t| t.join}
    end

    def with_each_environment
      environments.each_with_index do |gemfile_text, i|
        next unless should_run_environment?(i)
        yield gemfile_text, i
      end
    end

    def should_run_environment?(index)
      return true unless filter_env
      return filter_env == index
    end

    def with_clean_env
      if defined?(Bundler)
        # clear $BUNDLE_GEMFILE and $RUBYOPT so that the ruby subprocess can run
        # in the context of another bundle.
        Bundler.with_clean_env { yield }
      else
        yield
      end
    end

    def execute_in_foreground(env)
      with_clean_env do
        puts yellow("Running #{suite.inspect} for Envfile entry #{env}\n")
        system(child_command_line(env))
        check_for_failure(env)
      end
    end

    def execute_in_background(env)
      with_clean_env do
        OutputCollector.write(suite, env, yellow("Running #{suite.inspect} for Envfile entry #{env}\n"))

        IO.popen(child_command_line(env)) do |io|
          until io.eof do
            chars = io.read
            OutputCollector.write(suite, env, chars)
          end
          OutputCollector.suite_report(suite, env)
        end

        check_for_failure(env)
      end
    end

    def child_command_line(env)
      "#{__FILE__} #{directory} #{env} '#{Suite.encode_options(opts)}'"
    end

    def check_for_failure(env)
      if $? != 0
        OutputCollector.write(suite, env, red("#{suite.inspect} for Envfile entry #{env} failed!"))
        OutputCollector.failed(suite, env)
      end
      Multiverse::Runner.notice_exit_status $?
    end

    def trigger_test_run
      # We drive everything manually ourselves through MiniTest.
      #
      # Autorun behaves differently across the different Ruby version we have
      # to support, so this is simplest for making our test running consistent
      options = []
      options << "-v" if verbose?
      options << "--seed=#{seed}" unless seed == ""
      options << "--name=/#{names.map {|n| n + ".*"}.join("|")}/" unless names == []

      original_options = options.dup

      # MiniTest 5.0 moved things around, so choose which way to run it
      if ::MiniTest.respond_to?(:run)
        test_run = ::MiniTest.run(options)
      else
        test_run = ::MiniTest::Unit.new.run(options)
      end

      if test_run
        exit(test_run)
      else
        puts "No tests found with those options."
        puts "options: #{original_options}"
        exit(1)
      end
    end

    def configure_before_bundling
      disable_harvest_thread
      configure_fake_collector
    end

    def configure_child_environment
      require 'minitest/unit'
      patch_minitest_base_for_old_versions
      prevent_minitest_auto_run
      require_mocha
    end

    def patch_minitest_base_for_old_versions
      unless defined?(Minitest::Test)
        ::Minitest.class_eval do
          const_set(:Test, ::MiniTest::Unit::TestCase)
        end
      end
    end

    # Rails and minitest_tu_shim both want to do MiniTest::Unit.autorun for us
    # We can't sidestep, so just gut the method to avoid doubled test runs
    def prevent_minitest_auto_run
      # MiniTest 4.x
      ::MiniTest::Unit.class_eval do
        def self.autorun
          # NO-OP
        end
      end

      # MiniTest 5.x
      ::MiniTest.class_eval do
        def self.autorun
          # NO-OP
        end
      end
    end

    def require_mocha
      require 'mocha/setup'
    end

    def disable_harvest_thread
      # We don't want to have additional harvest threads running in our multiverse
      # tests. The tests explicitly manage their lifecycle--resetting and harvesting
      # to check results against the FakeCollector--so the harvest thread is actually
      # destabilizing if it's running. Also, multiple restarts result in lots of
      # threads running in some test suites.

      ENV["NEWRELIC_DISABLE_HARVEST_THREAD"] = "true"
    end

    def configure_fake_collector
      ENV["NEWRELIC_OMIT_FAKE_COLLECTOR"] = "true" if environments.omit_collector
    end

    def execute_ruby_files
      Dir.chdir directory
      ordered_ruby_files(directory).each do |file|
        puts yellow("Executing #{file.inspect}") if verbose?
        load file
      end
    end

    def ordered_ruby_files(directory)
      files = Dir[File.join(directory, '*.rb')]

      before = files.find { |file| File.basename(file) == "before_suite.rb" }
      after  = files.find { |file| File.basename(file) == "after_suite.rb" }

      files.delete(before)
      files.delete(after)

      # Important that we filter after removing before/after so they don't get
      # tromped for not matching our pattern!
      files.select! {|file| file.include?(filter_file) } if filter_file

      files.insert(0, before) if before
      files.insert(-1, after) if after

      files
    end

    def verbose?
      ENV['VERBOSE']
    end
  end
end

# Execute the suite.  We need this if we want to execute a suite by spawning a
# new process instead of forking.
if $0 == __FILE__ && $already_running.nil?
  # Suite might get re-required, but don't execute again
  $already_running = true

  # Redirect stderr to stdout so that we can capture both in the popen that
  # feeds into the OutputCollector above.
  $stderr.reopen($stdout)

  # Ugly, but seralized args passed along to #popen when kicking child off
  dir, env_index, encoded_opts, _ = *ARGV
  opts = Multiverse::Suite.decode_options(encoded_opts)
  suite = Multiverse::Suite.new(dir, opts)
  suite.execute_child_environment(env_index.to_i)
end
