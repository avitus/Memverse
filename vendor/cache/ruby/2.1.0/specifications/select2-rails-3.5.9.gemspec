# -*- encoding: utf-8 -*-
# stub: select2-rails 3.5.9 ruby lib

Gem::Specification.new do |s|
  s.name = "select2-rails"
  s.version = "3.5.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Rogerio Medeiros", "Pedro Nascimento"]
  s.date = "2014-07-05"
  s.description = "Select2 is a jQuery based replacement for select boxes. It supports searching, remote data sets, and infinite scrolling of results. This gem integrates Select2 with Rails asset pipeline for easy of use."
  s.email = ["argerim@gmail.com", "pnascimento@gmail.com"]
  s.homepage = "https://github.com/argerim/select2-rails"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Integrate Select2 javascript library with Rails asset pipeline"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<thor>, ["~> 0.14"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<rails>, [">= 3.0"])
      s.add_development_dependency(%q<httpclient>, ["~> 2.2"])
    else
      s.add_dependency(%q<thor>, ["~> 0.14"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<rails>, [">= 3.0"])
      s.add_dependency(%q<httpclient>, ["~> 2.2"])
    end
  else
    s.add_dependency(%q<thor>, ["~> 0.14"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<rails>, [">= 3.0"])
    s.add_dependency(%q<httpclient>, ["~> 2.2"])
  end
end
