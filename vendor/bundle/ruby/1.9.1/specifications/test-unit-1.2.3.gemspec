# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{test-unit}
  s.version = "1.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kouhei Sutou", "Ryan Davis"]
  s.date = %q{2008-03-20}
  s.default_executable = %q{testrb}
  s.description = %q{Test::Unit (Classic) - Nathaniel Talbott's originial test-unit, externalized from the ruby project as a gem (for tool developers).}
  s.email = ["kou@cozmixng.org", "ryand-ruby@zenspider.com"]
  s.executables = ["testrb"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/testrb", "lib/test/unit.rb", "lib/test/unit/assertionfailederror.rb", "lib/test/unit/assertions.rb", "lib/test/unit/autorunner.rb", "lib/test/unit/collector.rb", "lib/test/unit/collector/dir.rb", "lib/test/unit/collector/objectspace.rb", "lib/test/unit/error.rb", "lib/test/unit/failure.rb", "lib/test/unit/testcase.rb", "lib/test/unit/testresult.rb", "lib/test/unit/testsuite.rb", "lib/test/unit/ui/console/testrunner.rb", "lib/test/unit/ui/fox/testrunner.rb", "lib/test/unit/ui/gtk/testrunner.rb", "lib/test/unit/ui/gtk2/testrunner.rb", "lib/test/unit/ui/testrunnermediator.rb", "lib/test/unit/ui/testrunnerutilities.rb", "lib/test/unit/ui/tk/testrunner.rb", "lib/test/unit/util/backtracefilter.rb", "lib/test/unit/util/observable.rb", "lib/test/unit/util/procwrapper.rb", "lib/test/unit/version.rb", "sample/adder.rb", "sample/subtracter.rb", "sample/tc_adder.rb", "sample/tc_subtracter.rb", "sample/ts_examples.rb", "test/collector/test_dir.rb", "test/collector/test_objectspace.rb", "test/runit/test_assert.rb", "test/runit/test_testcase.rb", "test/runit/test_testresult.rb", "test/runit/test_testsuite.rb", "test/test_assertions.rb", "test/test_error.rb", "test/test_failure.rb", "test/test_testcase.rb", "test/test_testresult.rb", "test/test_testsuite.rb", "test/util/test_backtracefilter.rb", "test/util/test_observable.rb", "test/util/test_procwrapper.rb"]
  s.homepage = %q{http://rubyforge.org/projects/test-unit/}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{test-unit}
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{Test::Unit (Classic) - Nathaniel Talbott's originial test-unit, externalized from the ruby project as a gem (for tool developers).}
  s.test_files = ["test/collector/test_dir.rb", "test/collector/test_objectspace.rb", "test/runit/test_assert.rb", "test/runit/test_testcase.rb", "test/runit/test_testresult.rb", "test/runit/test_testsuite.rb", "test/test_assertions.rb", "test/test_error.rb", "test/test_failure.rb", "test/test_testcase.rb", "test/test_testresult.rb", "test/test_testsuite.rb", "test/util/test_backtracefilter.rb", "test/util/test_observable.rb", "test/util/test_procwrapper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hoe>, [">= 1.5.1"])
    else
      s.add_dependency(%q<hoe>, [">= 1.5.1"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.5.1"])
  end
end
