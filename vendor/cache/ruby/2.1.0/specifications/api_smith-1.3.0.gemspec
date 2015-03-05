# -*- encoding: utf-8 -*-
# stub: api_smith 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "api_smith"
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Darcy Laycock", "Steve Webb"]
  s.date = "2013-07-01"
  s.description = "APISmith provides tools to make working with structured HTTP-based apis even easier."
  s.email = ["sutto@thefrontiergroup.com.au"]
  s.homepage = "http://github.com/thefrontiergroup"
  s.rubygems_version = "2.4.6"
  s.summary = "A simple layer on top of HTTParty for building API's"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httparty>, [">= 0"])
      s.add_runtime_dependency(%q<hashie>, ["< 3.0", ">= 1.0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.0"])
    else
      s.add_dependency(%q<httparty>, [">= 0"])
      s.add_dependency(%q<hashie>, ["< 3.0", ">= 1.0"])
      s.add_dependency(%q<rr>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<httparty>, [">= 0"])
    s.add_dependency(%q<hashie>, ["< 3.0", ">= 1.0"])
    s.add_dependency(%q<rr>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.0"])
  end
end
