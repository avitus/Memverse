# -*- encoding: utf-8 -*-
# stub: rack-utf8_sanitizer 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-utf8_sanitizer"
  s.version = "1.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Peter Zotov"]
  s.date = "2014-07-10"
  s.description = "Rack::UTF8Sanitizer is a Rack middleware which cleans up invalid UTF8 characters in request URI and headers."
  s.email = ["whitequark@whitequark.org"]
  s.homepage = "http://github.com/whitequark/rack-utf8_sanitizer"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.rubygems_version = "2.4.6"
  s.summary = "Rack::UTF8Sanitizer is a Rack middleware which cleans up invalid UTF8 characters in request URI and headers."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, ["~> 1.0"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<bacon-colored_output>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<rack>, ["~> 1.0"])
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<bacon-colored_output>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, ["~> 1.0"])
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<bacon-colored_output>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
