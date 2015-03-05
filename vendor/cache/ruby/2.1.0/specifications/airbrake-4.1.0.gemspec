# -*- encoding: utf-8 -*-
# stub: airbrake 4.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "airbrake"
  s.version = "4.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Airbrake"]
  s.date = "2014-09-04"
  s.email = "support@airbrake.io"
  s.executables = ["airbrake"]
  s.files = ["bin/airbrake"]
  s.homepage = "http://www.airbrake.io"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Send your application errors to our hosted service and reclaim your inbox."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>, [">= 0"])
      s.add_development_dependency(%q<bourne>, ["~> 1.4.0"])
      s.add_development_dependency(%q<cucumber-rails>, ["~> 1.1.1"])
      s.add_development_dependency(%q<fakeweb>, ["~> 1.3.0"])
      s.add_development_dependency(%q<nokogiri>, ["~> 1.5.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_development_dependency(%q<sham_rack>, ["~> 1.3.0"])
      s.add_development_dependency(%q<json-schema>, ["~> 1.0.12"])
      s.add_development_dependency(%q<capistrano>, ["~> 2.0"])
      s.add_development_dependency(%q<aruba>, [">= 0"])
      s.add_development_dependency(%q<appraisal>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<girl_friday>, [">= 0"])
      s.add_development_dependency(%q<sucker_punch>, ["= 1.0.2"])
      s.add_development_dependency(%q<shoulda-matchers>, [">= 0"])
      s.add_development_dependency(%q<shoulda-context>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<coveralls>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 4.0"])
    else
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<multi_json>, [">= 0"])
      s.add_dependency(%q<bourne>, ["~> 1.4.0"])
      s.add_dependency(%q<cucumber-rails>, ["~> 1.1.1"])
      s.add_dependency(%q<fakeweb>, ["~> 1.3.0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.5.0"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_dependency(%q<sham_rack>, ["~> 1.3.0"])
      s.add_dependency(%q<json-schema>, ["~> 1.0.12"])
      s.add_dependency(%q<capistrano>, ["~> 2.0"])
      s.add_dependency(%q<aruba>, [">= 0"])
      s.add_dependency(%q<appraisal>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<girl_friday>, [">= 0"])
      s.add_dependency(%q<sucker_punch>, ["= 1.0.2"])
      s.add_dependency(%q<shoulda-matchers>, [">= 0"])
      s.add_dependency(%q<shoulda-context>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<coveralls>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 4.0"])
    end
  else
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<multi_json>, [">= 0"])
    s.add_dependency(%q<bourne>, ["~> 1.4.0"])
    s.add_dependency(%q<cucumber-rails>, ["~> 1.1.1"])
    s.add_dependency(%q<fakeweb>, ["~> 1.3.0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.5.0"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    s.add_dependency(%q<sham_rack>, ["~> 1.3.0"])
    s.add_dependency(%q<json-schema>, ["~> 1.0.12"])
    s.add_dependency(%q<capistrano>, ["~> 2.0"])
    s.add_dependency(%q<aruba>, [">= 0"])
    s.add_dependency(%q<appraisal>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<girl_friday>, [">= 0"])
    s.add_dependency(%q<sucker_punch>, ["= 1.0.2"])
    s.add_dependency(%q<shoulda-matchers>, [">= 0"])
    s.add_dependency(%q<shoulda-context>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<coveralls>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 4.0"])
  end
end
