# -*- encoding: utf-8 -*-
# stub: middleware 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "middleware"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Mitchell Hashimoto"]
  s.date = "2012-03-16"
  s.description = "Generalized implementation of the middleware abstraction for Ruby."
  s.email = ["mitchell.hashimoto@gmail.com"]
  s.homepage = "https://github.com/mitchellh/middleware"
  s.rubygems_version = "2.4.6"
  s.summary = "Generalized implementation of the middleware abstraction for Ruby."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<redcarpet>, ["~> 2.1.0"])
      s.add_development_dependency(%q<rspec-core>, ["~> 2.8.0"])
      s.add_development_dependency(%q<rspec-expectations>, ["~> 2.8.0"])
      s.add_development_dependency(%q<rspec-mocks>, ["~> 2.8.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.7.5"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<redcarpet>, ["~> 2.1.0"])
      s.add_dependency(%q<rspec-core>, ["~> 2.8.0"])
      s.add_dependency(%q<rspec-expectations>, ["~> 2.8.0"])
      s.add_dependency(%q<rspec-mocks>, ["~> 2.8.0"])
      s.add_dependency(%q<yard>, ["~> 0.7.5"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<redcarpet>, ["~> 2.1.0"])
    s.add_dependency(%q<rspec-core>, ["~> 2.8.0"])
    s.add_dependency(%q<rspec-expectations>, ["~> 2.8.0"])
    s.add_dependency(%q<rspec-mocks>, ["~> 2.8.0"])
    s.add_dependency(%q<yard>, ["~> 0.7.5"])
  end
end
