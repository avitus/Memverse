# -*- encoding: utf-8 -*-
# stub: rocket_pants 1.9.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rocket_pants"
  s.version = "1.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Darcy Laycock"]
  s.date = "2013-09-18"
  s.description = "Rocket Pants adds JSON API love to Rails and ActionController, making it simpler to build API-oriented controllers."
  s.email = ["sutto@sutto.net"]
  s.homepage = "http://github.com/filtersquad"
  s.rubygems_version = "2.4.6"
  s.summary = "JSON API love for Rails and ActionController"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, ["< 5.0", ">= 3.0"])
      s.add_runtime_dependency(%q<railties>, ["< 5.0", ">= 3.0"])
      s.add_runtime_dependency(%q<will_paginate>, ["~> 3.0"])
      s.add_runtime_dependency(%q<hashie>, ["< 3", ">= 1.0"])
      s.add_runtime_dependency(%q<api_smith>, [">= 0"])
      s.add_runtime_dependency(%q<moneta>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.4"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.4"])
      s.add_development_dependency(%q<rr>, ["~> 1.0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<activerecord>, ["< 5.0", ">= 3.0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<reversible_data>, ["~> 1.0"])
      s.add_development_dependency(%q<kaminari>, [">= 0"])
    else
      s.add_dependency(%q<actionpack>, ["< 5.0", ">= 3.0"])
      s.add_dependency(%q<railties>, ["< 5.0", ">= 3.0"])
      s.add_dependency(%q<will_paginate>, ["~> 3.0"])
      s.add_dependency(%q<hashie>, ["< 3", ">= 1.0"])
      s.add_dependency(%q<api_smith>, [">= 0"])
      s.add_dependency(%q<moneta>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.4"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.4"])
      s.add_dependency(%q<rr>, ["~> 1.0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<activerecord>, ["< 5.0", ">= 3.0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<reversible_data>, ["~> 1.0"])
      s.add_dependency(%q<kaminari>, [">= 0"])
    end
  else
    s.add_dependency(%q<actionpack>, ["< 5.0", ">= 3.0"])
    s.add_dependency(%q<railties>, ["< 5.0", ">= 3.0"])
    s.add_dependency(%q<will_paginate>, ["~> 3.0"])
    s.add_dependency(%q<hashie>, ["< 3", ">= 1.0"])
    s.add_dependency(%q<api_smith>, [">= 0"])
    s.add_dependency(%q<moneta>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.4"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.4"])
    s.add_dependency(%q<rr>, ["~> 1.0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<activerecord>, ["< 5.0", ">= 3.0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<reversible_data>, ["~> 1.0"])
    s.add_dependency(%q<kaminari>, [">= 0"])
  end
end
