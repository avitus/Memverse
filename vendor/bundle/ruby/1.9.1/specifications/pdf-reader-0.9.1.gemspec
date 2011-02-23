# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pdf-reader}
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Healy"]
  s.date = %q{2010-12-20}
  s.description = %q{The PDF::Reader library implements a PDF parser conforming as much as possible to the PDF specification from Adobe}
  s.email = ["jimmy@deefa.com"]
  s.executables = ["pdf_object", "pdf_text", "pdf_list_callbacks"]
  s.extra_rdoc_files = ["README.rdoc", "TODO", "CHANGELOG", "MIT-LICENSE"]
  s.files = ["examples/page_counter_naive.rb", "examples/rspec.rb", "examples/metadata.rb", "examples/extract_bates.rb", "examples/hash.rb", "examples/callbacks.rb", "examples/text.rb", "examples/version.rb", "examples/page_counter_improved.rb", "examples/extract_images.rb", "lib/pdf/reader/glyphlist.txt", "lib/pdf/reader/error.rb", "lib/pdf/reader/font.rb", "lib/pdf/reader/lzw.rb", "lib/pdf/reader/print_receiver.rb", "lib/pdf/reader/reference.rb", "lib/pdf/reader/filter.rb", "lib/pdf/reader/text_receiver.rb", "lib/pdf/reader/pages_strategy.rb", "lib/pdf/reader/abstract_strategy.rb", "lib/pdf/reader/encoding.rb", "lib/pdf/reader/stream.rb", "lib/pdf/reader/register_receiver.rb", "lib/pdf/reader/object_hash.rb", "lib/pdf/reader/token.rb", "lib/pdf/reader/xref.rb", "lib/pdf/reader/cmap.rb", "lib/pdf/reader/object_stream.rb", "lib/pdf/reader/metadata_strategy.rb", "lib/pdf/reader/buffer.rb", "lib/pdf/reader/encodings/zapf_dingbats.txt", "lib/pdf/reader/encodings/standard.txt", "lib/pdf/reader/encodings/mac_roman.txt", "lib/pdf/reader/encodings/mac_expert.txt", "lib/pdf/reader/encodings/win_ansi.txt", "lib/pdf/reader/encodings/symbol.txt", "lib/pdf/reader/encodings/pdf_doc.txt", "lib/pdf/reader/parser.rb", "lib/pdf/hash.rb", "lib/pdf/reader.rb", "lib/pdf-reader.rb", "Rakefile", "README.rdoc", "TODO", "CHANGELOG", "MIT-LICENSE", "bin/pdf_object", "bin/pdf_text", "bin/pdf_list_callbacks"]
  s.homepage = %q{http://github.com/yob/pdf-reader}
  s.rdoc_options = ["--title", "PDF::Reader Documentation", "--main", "README.rdoc", "-q"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{A library for accessing the content of PDF files}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<roodi>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.1"])
      s.add_runtime_dependency(%q<Ascii85>, [">= 0.9"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<roodi>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.1"])
      s.add_dependency(%q<Ascii85>, [">= 0.9"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<roodi>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.1"])
    s.add_dependency(%q<Ascii85>, [">= 0.9"])
  end
end
