# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "forem-textile_formatter/version"

Gem::Specification.new do |s|
  s.name        = "forem-textile_formatter"
  s.version     = Forem::TextileFormatter::VERSION
  s.authors     = ["Nicholas Rutherford"]
  s.email       = ["nick.rutherford@gmail.com"]
  s.homepage    = "https://github.com/nruth/forem-textile_formatter"
  s.summary     = %q{Textile formatting for forem posts}
  s.description = %q{Replaces the forem Rails engine's default formatting with Textile}

  s.rubyforge_project = "forem-textile_formatter"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "RedCloth"
  s.add_runtime_dependency "forem"
end
