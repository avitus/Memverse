# -*- encoding: utf-8 -*-
# stub: afm 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "afm"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jan Krutisch"]
  s.date = "2010-09-29"
  s.description = "a simple library to read afm files and use the data conveniently"
  s.email = "jan@krutisch.de"
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/halfbyte/afm"
  s.rdoc_options = ["--charset=UTF-8"]
  s.rubygems_version = "2.4.6"
  s.summary = "reading Adobe Font Metrics (afm) files"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end
