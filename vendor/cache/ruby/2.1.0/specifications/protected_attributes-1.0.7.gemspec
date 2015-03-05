# -*- encoding: utf-8 -*-
# stub: protected_attributes 1.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "protected_attributes"
  s.version = "1.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["David Heinemeier Hansson"]
  s.date = "2014-03-13"
  s.description = "Protect attributes from mass assignment"
  s.email = ["david@loudthinking.com"]
  s.homepage = "https://github.com/rails/protected_attributes"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Protect attributes from mass assignment in Active Record models"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activemodel>, ["< 5.0", ">= 4.0.1"])
      s.add_development_dependency(%q<activerecord>, ["< 5.0", ">= 4.0.1"])
      s.add_development_dependency(%q<actionpack>, ["< 5.0", ">= 4.0.1"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<activemodel>, ["< 5.0", ">= 4.0.1"])
      s.add_dependency(%q<activerecord>, ["< 5.0", ">= 4.0.1"])
      s.add_dependency(%q<actionpack>, ["< 5.0", ">= 4.0.1"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<activemodel>, ["< 5.0", ">= 4.0.1"])
    s.add_dependency(%q<activerecord>, ["< 5.0", ">= 4.0.1"])
    s.add_dependency(%q<actionpack>, ["< 5.0", ">= 4.0.1"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end
