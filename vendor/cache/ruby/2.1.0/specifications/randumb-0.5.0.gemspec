# -*- encoding: utf-8 -*-
# stub: randumb 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "randumb"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Zachary Kloepping"]
  s.date = "2014-03-22"
  s.homepage = "https://github.com/spilliton/randumb"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Adds the ability to pull random records from ActiveRecord"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_development_dependency(%q<sqlite3>, ["= 1.3.7"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<factory_girl>, ["~> 3.0"])
      s.add_development_dependency(%q<faker>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_dependency(%q<sqlite3>, ["= 1.3.7"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<factory_girl>, ["~> 3.0"])
      s.add_dependency(%q<faker>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<activerecord>, [">= 3.0.0"])
    s.add_dependency(%q<sqlite3>, ["= 1.3.7"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<factory_girl>, ["~> 3.0"])
    s.add_dependency(%q<faker>, [">= 0"])
  end
end
