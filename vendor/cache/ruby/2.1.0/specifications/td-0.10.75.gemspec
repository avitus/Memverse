# -*- encoding: utf-8 -*-
# stub: td 0.10.75 ruby lib

Gem::Specification.new do |s|
  s.name = "td"
  s.version = "0.10.75"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Treasure Data, Inc."]
  s.date = "2013-04-09"
  s.description = "CLI to manage data on Treasure Data, the Hadoop-based cloud data warehousing"
  s.email = "support@treasure-data.com"
  s.executables = ["td"]
  s.files = ["bin/td"]
  s.homepage = "http://treasure-data.com/"
  s.rubygems_version = "2.4.6"
  s.summary = "CLI to manage data on Treasure Data, the Hadoop-based cloud data warehousing"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<msgpack>, ["~> 0.4.4"])
      s.add_runtime_dependency(%q<yajl-ruby>, ["~> 1.1.0"])
      s.add_runtime_dependency(%q<hirb>, [">= 0.4.5"])
      s.add_runtime_dependency(%q<parallel>, ["~> 0.5.19"])
      s.add_runtime_dependency(%q<td-client>, ["~> 0.8.46"])
      s.add_runtime_dependency(%q<td-logger>, ["~> 0.3.16"])
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
      s.add_development_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.5.4"])
    else
      s.add_dependency(%q<msgpack>, ["~> 0.4.4"])
      s.add_dependency(%q<yajl-ruby>, ["~> 1.1.0"])
      s.add_dependency(%q<hirb>, [">= 0.4.5"])
      s.add_dependency(%q<parallel>, ["~> 0.5.19"])
      s.add_dependency(%q<td-client>, ["~> 0.8.46"])
      s.add_dependency(%q<td-logger>, ["~> 0.3.16"])
      s.add_dependency(%q<rake>, ["~> 0.9"])
      s.add_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_dependency(%q<simplecov>, ["~> 0.5.4"])
    end
  else
    s.add_dependency(%q<msgpack>, ["~> 0.4.4"])
    s.add_dependency(%q<yajl-ruby>, ["~> 1.1.0"])
    s.add_dependency(%q<hirb>, [">= 0.4.5"])
    s.add_dependency(%q<parallel>, ["~> 0.5.19"])
    s.add_dependency(%q<td-client>, ["~> 0.8.46"])
    s.add_dependency(%q<td-logger>, ["~> 0.3.16"])
    s.add_dependency(%q<rake>, ["~> 0.9"])
    s.add_dependency(%q<rspec>, ["~> 2.11.0"])
    s.add_dependency(%q<simplecov>, ["~> 0.5.4"])
  end
end
