# -*- encoding: utf-8 -*-
# stub: devise-encryptable 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "devise-encryptable"
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Carlos Antonio da Silva", "Jos\u{e9} Valim", "Rodrigo Flores"]
  s.date = "2013-05-07"
  s.description = "Encryption solution for salted-encryptors on Devise"
  s.email = "contact@plataformatec.com.br"
  s.homepage = "http://github.com/plataformatec/devise-encryptable"
  s.rubygems_version = "2.4.6"
  s.summary = "Encryption solution for salted-encryptors on Devise"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<devise>, [">= 2.1.0"])
    else
      s.add_dependency(%q<devise>, [">= 2.1.0"])
    end
  else
    s.add_dependency(%q<devise>, [">= 2.1.0"])
  end
end
