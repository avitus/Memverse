##
# rake-compiler plugin for hoe c-extensions.
#
# This plugin is for extconf.rb based projects that want to use
# rake-compiler to deal with packaging binary gems. It expects a
# standard extconf setup, namely that your extconf.rb and c source is
# located in: ext/project-name.
#
# === Tasks Provided:
#
# compile::     Compile your c-extension.

module Hoe::Compiler

  ##
  # Optional: Defines what tasks need to be compile first. [default: test]

  attr_accessor :compile_tasks

  ##
  # Initialize variables for compiler plugin.

  def initialize_compiler
    self.compile_tasks = [:multi, :test]
    self.spec_extras   = { :extensions => ["ext/#{self.name}/extconf.rb"] }

    extra_dev_deps << ["rake-compiler", "~> 0.7"]
  end

  ##
  # Define tasks for compiler plugin.

  def define_compiler_tasks
    require "rake/extensiontask"

    Rake::ExtensionTask.new self.name, spec do |ext|
      ext.lib_dir = File.join(*["lib", self.name, ENV["FAT_DIR"]].compact)
    end

    compile_tasks.each do |t|
      task t => :compile
    end
  end
end
