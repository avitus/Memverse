# -*- encoding: utf-8 -*-
# stub: sass-rails 4.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "sass-rails"
  s.version = "4.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["wycats", "chriseppstein"]
  s.date = "2014-04-04"
  s.description = "Sass adapter for the Rails asset pipeline."
  s.email = ["wycats@gmail.com", "chris@eppsteins.net"]
  s.homepage = "https://github.com/rails/sass-rails"
  s.licenses = ["MIT"]
  s.rubyforge_project = "sass-rails"
  s.rubygems_version = "2.4.6"
  s.summary = "Sass adapter for the Rails asset pipeline."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sass>, ["~> 3.2.0"])
      s.add_runtime_dependency(%q<railties>, ["< 5.0", ">= 4.0.0"])
      s.add_runtime_dependency(%q<sprockets-rails>, ["~> 2.0"])
      s.add_runtime_dependency(%q<sprockets>, ["<= 2.11.0", "~> 2.8"])
    else
      s.add_dependency(%q<sass>, ["~> 3.2.0"])
      s.add_dependency(%q<railties>, ["< 5.0", ">= 4.0.0"])
      s.add_dependency(%q<sprockets-rails>, ["~> 2.0"])
      s.add_dependency(%q<sprockets>, ["<= 2.11.0", "~> 2.8"])
    end
  else
    s.add_dependency(%q<sass>, ["~> 3.2.0"])
    s.add_dependency(%q<railties>, ["< 5.0", ">= 4.0.0"])
    s.add_dependency(%q<sprockets-rails>, ["~> 2.0"])
    s.add_dependency(%q<sprockets>, ["<= 2.11.0", "~> 2.8"])
  end
end
