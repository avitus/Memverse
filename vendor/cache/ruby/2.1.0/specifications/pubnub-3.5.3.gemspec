# -*- encoding: utf-8 -*-
# stub: pubnub 3.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "pubnub"
  s.version = "3.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["PubNub"]
  s.date = "2014-04-14"
  s.description = "Ruby anywhere in the world in 250ms with PubNub!"
  s.email = "support@pubnub.com"
  s.homepage = "http://github.com/pubnub/ruby"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "PubNub Official Ruby gem"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
      s.add_runtime_dependency(%q<net-http-persistent>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<net-http-persistent>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<net-http-persistent>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
  end
end
