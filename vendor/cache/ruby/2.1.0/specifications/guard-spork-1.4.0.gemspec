# -*- encoding: utf-8 -*-
# stub: guard-spork 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-spork"
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Thibaud Guillaume-Gentil"]
  s.date = "2012-11-30"
  s.description = "Guard::Spork automatically manage Spork DRb servers."
  s.email = ["thibaud@thibaud.me"]
  s.homepage = "http://rubygems.org/gems/guard-spork"
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubyforge_project = "guard-spork"
  s.rubygems_version = "2.4.6"
  s.summary = "Guard gem for Spork"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<guard>, [">= 1.1"])
      s.add_runtime_dependency(%q<spork>, [">= 0.8.4"])
      s.add_runtime_dependency(%q<childprocess>, [">= 0.2.3"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.10"])
      s.add_development_dependency(%q<guard-rspec>, ["~> 1.0"])
    else
      s.add_dependency(%q<guard>, [">= 1.1"])
      s.add_dependency(%q<spork>, [">= 0.8.4"])
      s.add_dependency(%q<childprocess>, [">= 0.2.3"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<rspec>, ["~> 2.10"])
      s.add_dependency(%q<guard-rspec>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<guard>, [">= 1.1"])
    s.add_dependency(%q<spork>, [">= 0.8.4"])
    s.add_dependency(%q<childprocess>, [">= 0.2.3"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<rspec>, ["~> 2.10"])
    s.add_dependency(%q<guard-rspec>, ["~> 1.0"])
  end
end
