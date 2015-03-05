# -*- encoding: utf-8 -*-
# stub: innertube 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "innertube"
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Sean Cribbs", "Kyle Kingsbury"]
  s.date = "2013-07-29"
  s.description = "Because everyone needs their own pool library."
  s.email = ["sean@basho.com", "aphyr@aphyr.com"]
  s.homepage = "http://github.com/basho/innertube"
  s.rubygems_version = "2.4.6"
  s.summary = "A thread-safe resource pool, originally borne in riak-client (Ripple)."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.10.0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.10.0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.10.0"])
  end
end
