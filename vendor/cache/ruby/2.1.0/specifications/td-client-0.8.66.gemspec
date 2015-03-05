# -*- encoding: utf-8 -*-
# stub: td-client 0.8.66 ruby lib

Gem::Specification.new do |s|
  s.name = "td-client"
  s.version = "0.8.66"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Treasure Data, Inc."]
  s.date = "2014-10-16"
  s.description = "Treasure Data API library for Ruby"
  s.email = "support@treasure-data.com"
  s.homepage = "http://treasuredata.com/"
  s.rubygems_version = "2.4.6"
  s.summary = "Treasure Data API library for Ruby"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<msgpack>, ["!= 0.5.0", "!= 0.5.1", "!= 0.5.2", "!= 0.5.3", "< 0.6.0", ">= 0.4.4"])
      s.add_runtime_dependency(%q<json>, [">= 1.7.6"])
      s.add_runtime_dependency(%q<httpclient>, ["~> 2.4.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.8"])
      s.add_development_dependency(%q<webmock>, ["~> 1.16"])
      s.add_development_dependency(%q<simplecov>, [">= 0.5.4"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<msgpack>, ["!= 0.5.0", "!= 0.5.1", "!= 0.5.2", "!= 0.5.3", "< 0.6.0", ">= 0.4.4"])
      s.add_dependency(%q<json>, [">= 1.7.6"])
      s.add_dependency(%q<httpclient>, ["~> 2.4.0"])
      s.add_dependency(%q<rspec>, ["~> 2.8"])
      s.add_dependency(%q<webmock>, ["~> 1.16"])
      s.add_dependency(%q<simplecov>, [">= 0.5.4"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<msgpack>, ["!= 0.5.0", "!= 0.5.1", "!= 0.5.2", "!= 0.5.3", "< 0.6.0", ">= 0.4.4"])
    s.add_dependency(%q<json>, [">= 1.7.6"])
    s.add_dependency(%q<httpclient>, ["~> 2.4.0"])
    s.add_dependency(%q<rspec>, ["~> 2.8"])
    s.add_dependency(%q<webmock>, ["~> 1.16"])
    s.add_dependency(%q<simplecov>, [">= 0.5.4"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
