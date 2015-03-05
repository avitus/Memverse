# -*- encoding: utf-8 -*-
# stub: guard-minitest 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-minitest"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Yann Lugrin"]
  s.date = "2012-02-24"
  s.description = "Guard::Minitest automatically run your tests with MiniTest framework (much like autotest)"
  s.email = ["yann.lugrin@sans-savoir.net"]
  s.homepage = "http://rubygems.org/gems/guard-minitest"
  s.rdoc_options = ["--charset=UTF-8", "--main=README.rdoc", "--exclude='(lib|test|spec)|(Gem|Guard|Rake)file'"]
  s.rubyforge_project = "guard-minitest"
  s.rubygems_version = "2.4.6"
  s.summary = "Guard gem for MiniTest framework"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<guard>, [">= 0.4"])
      s.add_development_dependency(%q<minitest>, ["~> 2.1.0"])
      s.add_development_dependency(%q<bundler>, [">= 1.0.2"])
      s.add_development_dependency(%q<mocha>, [">= 0.9.8"])
    else
      s.add_dependency(%q<guard>, [">= 0.4"])
      s.add_dependency(%q<minitest>, ["~> 2.1.0"])
      s.add_dependency(%q<bundler>, [">= 1.0.2"])
      s.add_dependency(%q<mocha>, [">= 0.9.8"])
    end
  else
    s.add_dependency(%q<guard>, [">= 0.4"])
    s.add_dependency(%q<minitest>, ["~> 2.1.0"])
    s.add_dependency(%q<bundler>, [">= 1.0.2"])
    s.add_dependency(%q<mocha>, [">= 0.9.8"])
  end
end
