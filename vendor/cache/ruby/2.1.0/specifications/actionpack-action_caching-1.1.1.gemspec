# -*- encoding: utf-8 -*-
# stub: actionpack-action_caching 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "actionpack-action_caching"
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["David Heinemeier Hansson"]
  s.date = "2014-01-02"
  s.description = "Action caching for Action Pack (removed from core in Rails 4.0)"
  s.email = "david@loudthinking.com"
  s.homepage = "https://github.com/rails/actionpack-action_caching"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Action caching for Action Pack (removed from core in Rails 4.0)"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, ["< 5.0", ">= 4.0.0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<activerecord>, ["< 5", ">= 4.0.0.beta"])
    else
      s.add_dependency(%q<actionpack>, ["< 5.0", ">= 4.0.0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<activerecord>, ["< 5", ">= 4.0.0.beta"])
    end
  else
    s.add_dependency(%q<actionpack>, ["< 5.0", ">= 4.0.0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<activerecord>, ["< 5", ">= 4.0.0.beta"])
  end
end
