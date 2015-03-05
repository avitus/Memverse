# -*- encoding: utf-8 -*-
# stub: prawnto_2 0.2.6 ruby lib

Gem::Specification.new do |s|
  s.name = "prawnto_2"
  s.version = "0.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jobber", "Forrest Zeisler", "Nathan Youngman"]
  s.date = "2013-04-16"
  s.description = "Simple PDF generation using the prawn library."
  s.email = ["forrest@getjobber.com"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc"]
  s.rubygems_version = "2.4.6"
  s.summary = "This gem allows you to use the PDF mime-type and the simple prawn syntax to generate impressive looking PDFs."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 3.1"])
      s.add_runtime_dependency(%q<prawn>, [">= 0.6.0"])
    else
      s.add_dependency(%q<rails>, [">= 3.1"])
      s.add_dependency(%q<prawn>, [">= 0.6.0"])
    end
  else
    s.add_dependency(%q<rails>, [">= 3.1"])
    s.add_dependency(%q<prawn>, [">= 0.6.0"])
  end
end
