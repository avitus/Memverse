# -*- encoding: utf-8 -*-
# stub: fancybox2-rails 0.2.8 ruby lib

Gem::Specification.new do |s|
  s.name = "fancybox2-rails"
  s.version = "0.2.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Mattias Svedhem"]
  s.date = "2014-03-05"
  s.description = "This gem provides jQuery FancyBox 2 for your Rails 3.1/4.0 application. This gem is based on the gem for Fancybox 1.x by Chris Mytton"
  s.email = ["mattias@kyparn.se"]
  s.homepage = "https://github.com/kyparn/fancybox2-rails"
  s.licenses = ["MIT", "Creative Commons by-nc"]
  s.rubygems_version = "2.4.6"
  s.summary = "Use FancyBox 2 with Rails 3.1/4.0"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, ["< 5.0", ">= 3.1.0"])
      s.add_development_dependency(%q<rails>, [">= 3.1"])
      s.add_development_dependency(%q<jquery-rails>, [">= 0"])
      s.add_development_dependency(%q<coffee-rails>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<capybara>, [">= 0"])
      s.add_development_dependency(%q<capybara-webkit>, [">= 0"])
    else
      s.add_dependency(%q<railties>, ["< 5.0", ">= 3.1.0"])
      s.add_dependency(%q<rails>, [">= 3.1"])
      s.add_dependency(%q<jquery-rails>, [">= 0"])
      s.add_dependency(%q<coffee-rails>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<capybara>, [">= 0"])
      s.add_dependency(%q<capybara-webkit>, [">= 0"])
    end
  else
    s.add_dependency(%q<railties>, ["< 5.0", ">= 3.1.0"])
    s.add_dependency(%q<rails>, [">= 3.1"])
    s.add_dependency(%q<jquery-rails>, [">= 0"])
    s.add_dependency(%q<coffee-rails>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<capybara>, [">= 0"])
    s.add_dependency(%q<capybara-webkit>, [">= 0"])
  end
end
