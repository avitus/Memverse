# -*- encoding: utf-8 -*-
# stub: redis-namespace 1.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-namespace"
  s.version = "1.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Chris Wanstrath", "Terence Lee", "Steve Klabnik"]
  s.date = "2013-12-03"
  s.description = "Adds a Redis::Namespace class which can be used to namespace calls\nto Redis. This is useful when using a single instance of Redis with\nmultiple, different applications.\n"
  s.email = ["chris@ozmm.org", "hone02@gmail.com", "steve@steveklabnik.com"]
  s.homepage = "http://github.com/resque/redis-namespace"
  s.rubygems_version = "2.4.6"
  s.summary = "Namespaces Redis commands."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>, ["~> 3.0.4"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<redis>, ["~> 3.0.4"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<redis>, ["~> 3.0.4"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
