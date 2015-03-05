# -*- encoding: utf-8 -*-
# stub: rails_admin 0.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rails_admin"
  s.version = "0.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.8.11") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Erik Michaels-Ober", "Bogdan Gaza", "Petteri Kaapa", "Benoit Benezech"]
  s.date = "2014-04-04"
  s.description = "RailsAdmin is a Rails engine that provides an easy-to-use interface for managing your data."
  s.email = ["sferik@gmail.com", "bogdan@cadmio.org", "petteri.kaapa@gmail.com"]
  s.homepage = "https://github.com/sferik/rails_admin"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.6"
  s.summary = "Admin for Rails"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, ["~> 3.1"])
      s.add_runtime_dependency(%q<coffee-rails>, ["~> 4.0"])
      s.add_runtime_dependency(%q<font-awesome-rails>, [">= 3.0"])
      s.add_runtime_dependency(%q<haml>, ["~> 4.0"])
      s.add_runtime_dependency(%q<jquery-rails>, ["~> 3.0"])
      s.add_runtime_dependency(%q<jquery-ui-rails>, ["~> 4.0"])
      s.add_runtime_dependency(%q<kaminari>, ["~> 0.14"])
      s.add_runtime_dependency(%q<nested_form>, ["~> 0.3"])
      s.add_runtime_dependency(%q<rack-pjax>, ["~> 0.7"])
      s.add_runtime_dependency(%q<rails>, ["~> 4.0"])
      s.add_runtime_dependency(%q<remotipart>, ["~> 1.0"])
      s.add_runtime_dependency(%q<safe_yaml>, ["~> 1.0"])
      s.add_runtime_dependency(%q<sass-rails>, ["~> 4.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
    else
      s.add_dependency(%q<builder>, ["~> 3.1"])
      s.add_dependency(%q<coffee-rails>, ["~> 4.0"])
      s.add_dependency(%q<font-awesome-rails>, [">= 3.0"])
      s.add_dependency(%q<haml>, ["~> 4.0"])
      s.add_dependency(%q<jquery-rails>, ["~> 3.0"])
      s.add_dependency(%q<jquery-ui-rails>, ["~> 4.0"])
      s.add_dependency(%q<kaminari>, ["~> 0.14"])
      s.add_dependency(%q<nested_form>, ["~> 0.3"])
      s.add_dependency(%q<rack-pjax>, ["~> 0.7"])
      s.add_dependency(%q<rails>, ["~> 4.0"])
      s.add_dependency(%q<remotipart>, ["~> 1.0"])
      s.add_dependency(%q<safe_yaml>, ["~> 1.0"])
      s.add_dependency(%q<sass-rails>, ["~> 4.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<builder>, ["~> 3.1"])
    s.add_dependency(%q<coffee-rails>, ["~> 4.0"])
    s.add_dependency(%q<font-awesome-rails>, [">= 3.0"])
    s.add_dependency(%q<haml>, ["~> 4.0"])
    s.add_dependency(%q<jquery-rails>, ["~> 3.0"])
    s.add_dependency(%q<jquery-ui-rails>, ["~> 4.0"])
    s.add_dependency(%q<kaminari>, ["~> 0.14"])
    s.add_dependency(%q<nested_form>, ["~> 0.3"])
    s.add_dependency(%q<rack-pjax>, ["~> 0.7"])
    s.add_dependency(%q<rails>, ["~> 4.0"])
    s.add_dependency(%q<remotipart>, ["~> 1.0"])
    s.add_dependency(%q<safe_yaml>, ["~> 1.0"])
    s.add_dependency(%q<sass-rails>, ["~> 4.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
  end
end
