# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{logging}
  s.version = "1.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Pease"]
  s.date = %q{2010-05-30}
  s.description = %q{Logging is a flexible logging library for use in Ruby programs based on the
design of Java's log4j library. It features a hierarchical logging system,
custom level names, multiple output destinations per log event, custom
formatting, and more.}
  s.email = %q{tim.pease@gmail.com}
  s.extra_rdoc_files = ["History.txt", "README.rdoc", "version.txt"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "data/bad_logging_1.rb", "data/bad_logging_2.rb", "data/logging.rb", "data/logging.yaml", "data/simple_logging.rb", "examples/appenders.rb", "examples/classes.rb", "examples/consolidation.rb", "examples/fork.rb", "examples/formatting.rb", "examples/hierarchies.rb", "examples/layouts.rb", "examples/loggers.rb", "examples/names.rb", "examples/simple.rb", "lib/logging.rb", "lib/logging/appender.rb", "lib/logging/appenders.rb", "lib/logging/appenders/buffering.rb", "lib/logging/appenders/console.rb", "lib/logging/appenders/email.rb", "lib/logging/appenders/file.rb", "lib/logging/appenders/growl.rb", "lib/logging/appenders/io.rb", "lib/logging/appenders/rolling_file.rb", "lib/logging/appenders/string_io.rb", "lib/logging/appenders/syslog.rb", "lib/logging/config/configurator.rb", "lib/logging/config/yaml_configurator.rb", "lib/logging/layout.rb", "lib/logging/layouts.rb", "lib/logging/layouts/basic.rb", "lib/logging/layouts/parseable.rb", "lib/logging/layouts/pattern.rb", "lib/logging/log_event.rb", "lib/logging/logger.rb", "lib/logging/repository.rb", "lib/logging/root_logger.rb", "lib/logging/stats.rb", "lib/logging/utils.rb", "lib/spec/logging_helper.rb", "test/appenders/test_buffered_io.rb", "test/appenders/test_console.rb", "test/appenders/test_email.rb", "test/appenders/test_file.rb", "test/appenders/test_growl.rb", "test/appenders/test_io.rb", "test/appenders/test_rolling_file.rb", "test/appenders/test_syslog.rb", "test/benchmark.rb", "test/config/test_configurator.rb", "test/config/test_yaml_configurator.rb", "test/layouts/test_basic.rb", "test/layouts/test_json.rb", "test/layouts/test_pattern.rb", "test/layouts/test_yaml.rb", "test/setup.rb", "test/test_appender.rb", "test/test_consolidate.rb", "test/test_layout.rb", "test/test_log_event.rb", "test/test_logger.rb", "test/test_logging.rb", "test/test_repository.rb", "test/test_root_logger.rb", "test/test_stats.rb", "test/test_utils.rb", "version.txt"]
  s.homepage = %q{http://rubygems.org/gems/logging}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{logging}
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{A flexible and extendable logging library for Ruby}
  s.test_files = ["test/appenders/test_buffered_io.rb", "test/appenders/test_console.rb", "test/appenders/test_email.rb", "test/appenders/test_file.rb", "test/appenders/test_growl.rb", "test/appenders/test_io.rb", "test/appenders/test_rolling_file.rb", "test/appenders/test_syslog.rb", "test/config/test_configurator.rb", "test/config/test_yaml_configurator.rb", "test/layouts/test_basic.rb", "test/layouts/test_json.rb", "test/layouts/test_pattern.rb", "test/layouts/test_yaml.rb", "test/test_appender.rb", "test/test_consolidate.rb", "test/test_layout.rb", "test/test_log_event.rb", "test/test_logger.rb", "test/test_logging.rb", "test/test_repository.rb", "test/test_root_logger.rb", "test/test_stats.rb", "test/test_utils.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<little-plugger>, [">= 1.1.2"])
      s.add_development_dependency(%q<flexmock>, [">= 0.8.6"])
      s.add_development_dependency(%q<bones-git>, [">= 1.1.2"])
      s.add_development_dependency(%q<bones-extras>, [">= 1.2.3"])
      s.add_development_dependency(%q<bones>, [">= 3.4.3"])
    else
      s.add_dependency(%q<little-plugger>, [">= 1.1.2"])
      s.add_dependency(%q<flexmock>, [">= 0.8.6"])
      s.add_dependency(%q<bones-git>, [">= 1.1.2"])
      s.add_dependency(%q<bones-extras>, [">= 1.2.3"])
      s.add_dependency(%q<bones>, [">= 3.4.3"])
    end
  else
    s.add_dependency(%q<little-plugger>, [">= 1.1.2"])
    s.add_dependency(%q<flexmock>, [">= 0.8.6"])
    s.add_dependency(%q<bones-git>, [">= 1.1.2"])
    s.add_dependency(%q<bones-extras>, [">= 1.2.3"])
    s.add_dependency(%q<bones>, [">= 3.4.3"])
  end
end
