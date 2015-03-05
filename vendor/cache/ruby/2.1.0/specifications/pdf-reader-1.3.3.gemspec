# -*- encoding: utf-8 -*-
# stub: pdf-reader 1.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "pdf-reader"
  s.version = "1.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["James Healy"]
  s.date = "2013-04-07"
  s.description = "The PDF::Reader library implements a PDF parser conforming as much as possible to the PDF specification from Adobe"
  s.email = ["jimmy@deefa.com"]
  s.executables = ["pdf_object", "pdf_text", "pdf_list_callbacks", "pdf_callbacks"]
  s.extra_rdoc_files = ["README.rdoc", "TODO", "CHANGELOG", "MIT-LICENSE"]
  s.files = ["CHANGELOG", "MIT-LICENSE", "README.rdoc", "TODO", "bin/pdf_callbacks", "bin/pdf_list_callbacks", "bin/pdf_object", "bin/pdf_text"]
  s.homepage = "http://github.com/yob/pdf-reader"
  s.post_install_message = "\n  ********************************************\n\n  v1.0.0 of PDF::Reader introduced a new page-based API. There are extensive\n  examples showing how to use it in the README and examples directory.\n\n  For detailed documentation, check the rdocs for the PDF::Reader,\n  PDF::Reader::Page and PDF::Reader::ObjectHash classes.\n\n  The old API is marked as deprecated but will continue to work with no\n  visible warnings for now.\n\n  ********************************************\n\n"
  s.rdoc_options = ["--title", "PDF::Reader Documentation", "--main", "README.rdoc", "-q"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = "2.4.6"
  s.summary = "A library for accessing the content of PDF files"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3"])
      s.add_development_dependency(%q<ZenTest>, ["~> 4.4.2"])
      s.add_development_dependency(%q<cane>, ["~> 2.2.3"])
      s.add_development_dependency(%q<morecane>, [">= 0"])
      s.add_development_dependency(%q<ir_b>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, [">= 0"])
      s.add_runtime_dependency(%q<Ascii85>, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<ruby-rc4>, [">= 0"])
      s.add_runtime_dependency(%q<hashery>, ["~> 2.0"])
      s.add_runtime_dependency(%q<ttfunk>, [">= 0"])
      s.add_runtime_dependency(%q<afm>, ["~> 0.2.0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.3"])
      s.add_dependency(%q<ZenTest>, ["~> 4.4.2"])
      s.add_dependency(%q<cane>, ["~> 2.2.3"])
      s.add_dependency(%q<morecane>, [">= 0"])
      s.add_dependency(%q<ir_b>, [">= 0"])
      s.add_dependency(%q<rdoc>, [">= 0"])
      s.add_dependency(%q<Ascii85>, ["~> 1.0.0"])
      s.add_dependency(%q<ruby-rc4>, [">= 0"])
      s.add_dependency(%q<hashery>, ["~> 2.0"])
      s.add_dependency(%q<ttfunk>, [">= 0"])
      s.add_dependency(%q<afm>, ["~> 0.2.0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.3"])
    s.add_dependency(%q<ZenTest>, ["~> 4.4.2"])
    s.add_dependency(%q<cane>, ["~> 2.2.3"])
    s.add_dependency(%q<morecane>, [">= 0"])
    s.add_dependency(%q<ir_b>, [">= 0"])
    s.add_dependency(%q<rdoc>, [">= 0"])
    s.add_dependency(%q<Ascii85>, ["~> 1.0.0"])
    s.add_dependency(%q<ruby-rc4>, [">= 0"])
    s.add_dependency(%q<hashery>, ["~> 2.0"])
    s.add_dependency(%q<ttfunk>, [">= 0"])
    s.add_dependency(%q<afm>, ["~> 0.2.0"])
  end
end
