# -*- encoding: utf-8 -*-
# stub: decorators 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "decorators"
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Philip Arndt"]
  s.date = "2013-02-12"
  s.description = "Manages the process of loading decorators into your Rails application."
  s.email = "parndt@gmail.com"
  s.homepage = "http://philiparndt.name"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Rails decorators plugin."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, ["!= 3.1.0", "!= 3.1.1", "!= 3.1.2", "!= 3.1.3", "!= 3.1.4", "!= 3.1.5", "!= 3.1.6", "!= 3.1.7", "!= 3.1.8", "!= 3.1.9", "!= 3.2.0", "!= 3.2.1", "!= 3.2.10", "!= 3.2.2", "!= 3.2.3", "!= 3.2.4", "!= 3.2.5", "!= 3.2.6", "!= 3.2.7", "!= 3.2.8", "!= 3.2.9", ">= 3.0.19"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<railties>, ["!= 3.1.0", "!= 3.1.1", "!= 3.1.2", "!= 3.1.3", "!= 3.1.4", "!= 3.1.5", "!= 3.1.6", "!= 3.1.7", "!= 3.1.8", "!= 3.1.9", "!= 3.2.0", "!= 3.2.1", "!= 3.2.10", "!= 3.2.2", "!= 3.2.3", "!= 3.2.4", "!= 3.2.5", "!= 3.2.6", "!= 3.2.7", "!= 3.2.8", "!= 3.2.9", ">= 3.0.19"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<railties>, ["!= 3.1.0", "!= 3.1.1", "!= 3.1.2", "!= 3.1.3", "!= 3.1.4", "!= 3.1.5", "!= 3.1.6", "!= 3.1.7", "!= 3.1.8", "!= 3.1.9", "!= 3.2.0", "!= 3.2.1", "!= 3.2.10", "!= 3.2.2", "!= 3.2.3", "!= 3.2.4", "!= 3.2.5", "!= 3.2.6", "!= 3.2.7", "!= 3.2.8", "!= 3.2.9", ">= 3.0.19"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
