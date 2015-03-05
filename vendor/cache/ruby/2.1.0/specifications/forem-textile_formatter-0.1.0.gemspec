# -*- encoding: utf-8 -*-
# stub: forem-textile_formatter 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "forem-textile_formatter"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Nicholas Rutherford"]
  s.date = "2011-10-27"
  s.description = "Replaces the forem Rails engine's default formatting with Textile"
  s.email = ["nick.rutherford@gmail.com"]
  s.homepage = "https://github.com/nruth/forem-textile_formatter"
  s.rubyforge_project = "forem-textile_formatter"
  s.rubygems_version = "2.4.6"
  s.summary = "Textile formatting for forem posts"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<RedCloth>, [">= 0"])
      s.add_runtime_dependency(%q<forem>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<RedCloth>, [">= 0"])
      s.add_dependency(%q<forem>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<RedCloth>, [">= 0"])
    s.add_dependency(%q<forem>, [">= 0"])
  end
end
