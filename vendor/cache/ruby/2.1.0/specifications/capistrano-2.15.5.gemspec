# -*- encoding: utf-8 -*-
# stub: capistrano 2.15.5 ruby lib

Gem::Specification.new do |s|
  s.name = "capistrano"
  s.version = "2.15.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jamis Buck", "Lee Hambley"]
  s.date = "2013-07-04"
  s.description = "Capistrano is a utility and framework for executing commands in parallel on multiple remote machines, via SSH."
  s.email = ["jamis@jamisbuck.org", "lee.hambley@gmail.com"]
  s.executables = ["cap", "capify"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "bin/cap", "bin/capify"]
  s.homepage = "http://github.com/capistrano/capistrano"
  s.rubygems_version = "2.4.6"
  s.summary = "Capistrano - Welcome to easy deployment with Ruby over SSH"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<highline>, [">= 0"])
      s.add_runtime_dependency(%q<net-ssh>, [">= 2.0.14"])
      s.add_runtime_dependency(%q<net-sftp>, [">= 2.0.0"])
      s.add_runtime_dependency(%q<net-scp>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<net-ssh-gateway>, [">= 1.1.0"])
      s.add_development_dependency(%q<mocha>, ["= 0.9.12"])
    else
      s.add_dependency(%q<highline>, [">= 0"])
      s.add_dependency(%q<net-ssh>, [">= 2.0.14"])
      s.add_dependency(%q<net-sftp>, [">= 2.0.0"])
      s.add_dependency(%q<net-scp>, [">= 1.0.0"])
      s.add_dependency(%q<net-ssh-gateway>, [">= 1.1.0"])
      s.add_dependency(%q<mocha>, ["= 0.9.12"])
    end
  else
    s.add_dependency(%q<highline>, [">= 0"])
    s.add_dependency(%q<net-ssh>, [">= 2.0.14"])
    s.add_dependency(%q<net-sftp>, [">= 2.0.0"])
    s.add_dependency(%q<net-scp>, [">= 1.0.0"])
    s.add_dependency(%q<net-ssh-gateway>, [">= 1.1.0"])
    s.add_dependency(%q<mocha>, ["= 0.9.12"])
  end
end
