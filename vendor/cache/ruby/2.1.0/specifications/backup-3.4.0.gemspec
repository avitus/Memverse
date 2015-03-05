# -*- encoding: utf-8 -*-
# stub: backup 3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "backup"
  s.version = "3.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael van Rooijen"]
  s.date = "2013-04-29"
  s.description = "Backup is a RubyGem, written for UNIX-like operating systems, that allows you to easily perform backup operations on both your remote and local environments. It provides you with an elegant DSL in Ruby for modeling your backups. Backup has built-in support for various databases, storage protocols/services, syncers, compressors, encryptors and notifiers which you can mix and match. It was built with modularity, extensibility and simplicity in mind."
  s.email = "meskyanichi@gmail.com"
  s.executables = ["backup"]
  s.files = ["bin/backup"]
  s.homepage = "https://github.com/meskyanichi/backup"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Provides an elegant DSL in Ruby for performing backups on UNIX-like systems."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<thor>, ["< 2", ">= 0.15.4"])
      s.add_runtime_dependency(%q<open4>, ["~> 1.3.0"])
    else
      s.add_dependency(%q<thor>, ["< 2", ">= 0.15.4"])
      s.add_dependency(%q<open4>, ["~> 1.3.0"])
    end
  else
    s.add_dependency(%q<thor>, ["< 2", ">= 0.15.4"])
    s.add_dependency(%q<open4>, ["~> 1.3.0"])
  end
end
