# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{Ascii85}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Johannes HolzfuÃ\u009F"]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDKjCCAhKgAwIBAgIBADANBgkqhkiG9w0BAQUFADA7MRAwDgYDVQQDDAdfcmFu\nZ29uMRMwEQYKCZImiZPyLGQBGRYDZ214MRIwEAYKCZImiZPyLGQBGRYCZGUwHhcN\nMDkwMjE0MTgxNDM5WhcNMTAwMjE0MTgxNDM5WjA7MRAwDgYDVQQDDAdfcmFuZ29u\nMRMwEQYKCZImiZPyLGQBGRYDZ214MRIwEAYKCZImiZPyLGQBGRYCZGUwggEiMA0G\nCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDa7HRW1pPBbx8k9GLOzYBwHNLAOvHc\nkWfq5E99plLhxKobF7xSValm2csTPQqF8549JJUADGrmeSyFx4z241JtDATjFdYI\n5LaBXqvxR/c6BfPqPOIuZqc6o1VEpMEVsgKqcL0wjmOaNXMDL7vWj2+LyizWqMXJ\nY2Hj6GlR6kYzoUyOoAPO+FG363YT++tFvOaOmba314dL40r/Spc730gr1utS8pHA\nt8Gl+Z0EC5gmcUvfDT2sVAF8k9qQhGGqOuOM2HDP+ZrJ368UJznVBxp9YhUveGc2\nMPXvntkrN2XLfGjV2Tr418v7OBP+0IgnZVBM8O7q+iMJmuv/yt2M53H/AgMBAAGj\nOTA3MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBT83GfQpOoJZm8B\ngY6lweCTOsu0QTANBgkqhkiG9w0BAQUFAAOCAQEAAT33NPbPZVy3tgPsl1TicU9q\neBen2WkXfrCO8jP1ivuFQqMHl5b+MpG2LIwEB45QLLnoXmcW+C4ihGdkYG078uor\nZskHRETlHJ791l6PyGw5j1oFSwbeYwYIFBWcRrq0KdcZO4CZb7rln2S06ZJWQIMg\n930O6/WuJyRQLr1PaTJcUGoHUC9cd4CE7ARuck3V38vNR4azjAznCa01mgSkp9UQ\nxPVAMuP9qOp6+OFiuL7DDCHgGI52vDFlUSU+hMcsSSDbYSFcilSPlZ3WLTlOhM4d\n5FGhYN16QZS8VKLApBtxxP9XmwFASMyJLNizTN2q6hCCy/MjoTzHWzodPaWm0Q==\n-----END CERTIFICATE-----\n"]
  s.date = %q{2009-12-24}
  s.default_executable = %q{ascii85}
  s.description = %q{Ascii85 is a simple gem that provides methods for encoding/decoding Adobe's
binary-to-text encoding of the same name.

See http://www.adobe.com/products/postscript/pdfs/PLRM.pdf page 131 and
http://en.wikipedia.org/wiki/Ascii85 for more information about the format.}
  s.email = ["Drangon@gmx.de"]
  s.executables = ["ascii85"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/ascii85", "lib/ascii85.rb", "spec/ascii85_spec.rb"]
  s.homepage = %q{http://ascii85.rubyforge.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ascii85}
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{Ascii85 is a simple gem that provides methods for encoding/decoding Adobe's binary-to-text encoding of the same name}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 2.4.0"])
    else
      s.add_dependency(%q<hoe>, [">= 2.4.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 2.4.0"])
  end
end
