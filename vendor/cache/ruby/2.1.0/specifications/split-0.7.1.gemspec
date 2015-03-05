# -*- encoding: utf-8 -*-
# stub: split 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "split"
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Andrew Nesbitt"]
  s.date = "2014-03-20"
  s.email = ["andrewnez@gmail.com"]
  s.homepage = "https://github.com/andrew/split"
  s.licenses = ["MIT"]
  s.rubyforge_project = "split"
  s.rubygems_version = "2.4.6"
  s.summary = "Rack based split testing framework"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>, [">= 2.1"])
      s.add_runtime_dependency(%q<redis-namespace>, [">= 1.1.0"])
      s.add_runtime_dependency(%q<sinatra>, [">= 1.2.6"])
      s.add_runtime_dependency(%q<simple-random>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.14"])
      s.add_development_dependency(%q<rack-test>, [">= 0.5.7"])
      s.add_development_dependency(%q<coveralls>, [">= 0"])
    else
      s.add_dependency(%q<redis>, [">= 2.1"])
      s.add_dependency(%q<redis-namespace>, [">= 1.1.0"])
      s.add_dependency(%q<sinatra>, [">= 1.2.6"])
      s.add_dependency(%q<simple-random>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rspec>, ["~> 2.14"])
      s.add_dependency(%q<rack-test>, [">= 0.5.7"])
      s.add_dependency(%q<coveralls>, [">= 0"])
    end
  else
    s.add_dependency(%q<redis>, [">= 2.1"])
    s.add_dependency(%q<redis-namespace>, [">= 1.1.0"])
    s.add_dependency(%q<sinatra>, [">= 1.2.6"])
    s.add_dependency(%q<simple-random>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rspec>, ["~> 2.14"])
    s.add_dependency(%q<rack-test>, [">= 0.5.7"])
    s.add_dependency(%q<coveralls>, [">= 0"])
  end
end
