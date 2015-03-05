# -*- encoding: utf-8 -*-
# stub: riddle 1.5.11 ruby lib

Gem::Specification.new do |s|
  s.name = "riddle"
  s.version = "1.5.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Pat Allan"]
  s.date = "2014-04-19"
  s.description = "A Ruby API and configuration helper for the Sphinx search service."
  s.email = ["pat@freelancing-gods.com"]
  s.homepage = "http://pat.github.io/riddle/"
  s.licenses = ["MIT"]
  s.rubyforge_project = "riddle"
  s.rubygems_version = "2.4.6"
  s.summary = "An API for Sphinx, written in and for Ruby."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.9.2"])
      s.add_development_dependency(%q<rspec>, [">= 2.5.0"])
      s.add_development_dependency(%q<yard>, [">= 0.7.2"])
    else
      s.add_dependency(%q<rake>, [">= 0.9.2"])
      s.add_dependency(%q<rspec>, [">= 2.5.0"])
      s.add_dependency(%q<yard>, [">= 0.7.2"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.9.2"])
    s.add_dependency(%q<rspec>, [">= 2.5.0"])
    s.add_dependency(%q<yard>, [">= 0.7.2"])
  end
end
