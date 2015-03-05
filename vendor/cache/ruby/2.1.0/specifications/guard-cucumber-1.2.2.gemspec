# -*- encoding: utf-8 -*-
# stub: guard-cucumber 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-cucumber"
  s.version = "1.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Kessler"]
  s.date = "2012-10-31"
  s.description = "Guard::Cucumber automatically run your features (much like autotest)"
  s.email = ["michi@netzpiraten.ch"]
  s.homepage = "http://github.com/netzpirat/guard-cucumber"
  s.rubyforge_project = "guard-cucumber"
  s.rubygems_version = "2.4.6"
  s.summary = "Guard plugin for Cucumber"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<guard>, [">= 1.1.0"])
      s.add_runtime_dependency(%q<cucumber>, [">= 1.2.0"])
    else
      s.add_dependency(%q<guard>, [">= 1.1.0"])
      s.add_dependency(%q<cucumber>, [">= 1.2.0"])
    end
  else
    s.add_dependency(%q<guard>, [">= 1.1.0"])
    s.add_dependency(%q<cucumber>, [">= 1.2.0"])
  end
end
