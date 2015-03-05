# -*- encoding: utf-8 -*-
# stub: actionpack-page_caching 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "actionpack-page_caching"
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["David Heinemeier Hansson"]
  s.date = "2013-11-15"
  s.description = "Static page caching for Action Pack (removed from core in Rails 4.0)"
  s.email = "david@loudthinking.com"
  s.homepage = "https://github.com/rails/actionpack-page_caching"
  s.rubygems_version = "2.4.6"
  s.summary = "Static page caching for Action Pack (removed from core in Rails 4.0)"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, ["< 5", ">= 4.0.0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<actionpack>, ["< 5", ">= 4.0.0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<actionpack>, ["< 5", ">= 4.0.0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end
