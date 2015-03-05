# -*- encoding: utf-8 -*-
# stub: td-logger 0.3.23 ruby lib

Gem::Specification.new do |s|
  s.name = "td-logger"
  s.version = "0.3.23"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Sadayuki Furuhashi"]
  s.date = "2013-09-19"
  s.description = "Treasure Data logging library for Rails"
  s.rubygems_version = "2.4.6"
  s.summary = "Treasure Data logging library for Rails"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<msgpack>, ["!= 0.5.0", "!= 0.5.1", "!= 0.5.2", "!= 0.5.3", "< 0.6.0", ">= 0.4.4"])
      s.add_runtime_dependency(%q<td-client>, ["~> 0.8.51"])
      s.add_runtime_dependency(%q<fluent-logger>, ["~> 0.4.6"])
      s.add_development_dependency(%q<rake>, [">= 0.9.2"])
      s.add_development_dependency(%q<rspec>, [">= 2.7.0"])
    else
      s.add_dependency(%q<msgpack>, ["!= 0.5.0", "!= 0.5.1", "!= 0.5.2", "!= 0.5.3", "< 0.6.0", ">= 0.4.4"])
      s.add_dependency(%q<td-client>, ["~> 0.8.51"])
      s.add_dependency(%q<fluent-logger>, ["~> 0.4.6"])
      s.add_dependency(%q<rake>, [">= 0.9.2"])
      s.add_dependency(%q<rspec>, [">= 2.7.0"])
    end
  else
    s.add_dependency(%q<msgpack>, ["!= 0.5.0", "!= 0.5.1", "!= 0.5.2", "!= 0.5.3", "< 0.6.0", ">= 0.4.4"])
    s.add_dependency(%q<td-client>, ["~> 0.8.51"])
    s.add_dependency(%q<fluent-logger>, ["~> 0.4.6"])
    s.add_dependency(%q<rake>, [">= 0.9.2"])
    s.add_dependency(%q<rspec>, [">= 2.7.0"])
  end
end
