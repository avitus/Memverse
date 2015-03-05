# -*- encoding: utf-8 -*-
# stub: sidetiq 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sidetiq"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Tobias Svensson"]
  s.date = "2013-11-26"
  s.description = "Recurring jobs for Sidekiq"
  s.email = ["tob@tobiassvensson.co.uk"]
  s.homepage = "http://github.com/tobiassvn/sidetiq"
  s.licenses = ["3-clause BSD"]
  s.rubygems_version = "2.4.6"
  s.summary = "Recurring jobs for Sidekiq"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sidekiq>, [">= 2.16.0"])
      s.add_runtime_dependency(%q<celluloid>, [">= 0.14.1"])
      s.add_runtime_dependency(%q<ice_cube>, ["~> 0.11.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<sinatra>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.0.7"])
      s.add_development_dependency(%q<coveralls>, [">= 0"])
    else
      s.add_dependency(%q<sidekiq>, [">= 2.16.0"])
      s.add_dependency(%q<celluloid>, [">= 0.14.1"])
      s.add_dependency(%q<ice_cube>, ["~> 0.11.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 5.0.7"])
      s.add_dependency(%q<coveralls>, [">= 0"])
    end
  else
    s.add_dependency(%q<sidekiq>, [">= 2.16.0"])
    s.add_dependency(%q<celluloid>, [">= 0.14.1"])
    s.add_dependency(%q<ice_cube>, ["~> 0.11.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 5.0.7"])
    s.add_dependency(%q<coveralls>, [">= 0"])
  end
end
