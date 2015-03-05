# -*- encoding: utf-8 -*-
# stub: swagger-docs 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "swagger-docs"
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Rich Hollis"]
  s.cert_chain = ["certs/gem-public_cert.pem"]
  s.date = "2015-03-05"
  s.description = "Generates json files for rails apps to use with swagger-ui"
  s.email = ["richhollis@gmail.com"]
  s.files = [".gitignore", "Appraisals", "CHANGELOG.md", "Gemfile", "LICENSE.txt", "README.md", "Rakefile", "certs/gem-public_cert.pem", "lib/swagger/docs.rb", "lib/swagger/docs/config.rb", "lib/swagger/docs/dsl.rb", "lib/swagger/docs/generator.rb", "lib/swagger/docs/impotent_methods.rb", "lib/swagger/docs/methods.rb", "lib/swagger/docs/task.rb", "lib/swagger/docs/version.rb", "lib/tasks/swagger.rake", "pec", "spec/fixtures/controllers/application_controller.rb", "spec/fixtures/controllers/ignored_controller.rb", "spec/fixtures/controllers/sample_controller.rb", "spec/lib/swagger/docs/generator_spec.rb", "spec/spec_helper.rb", "swagger-docs.gemspec"]
  s.homepage = "https://github.com/richhollis/swagger-docs"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Generates swagger-ui json files for rails apps with APIs. You add the swagger DSL to your controller classes and then run one rake task to generate the json files."
  s.test_files = ["spec/fixtures/controllers/application_controller.rb", "spec/fixtures/controllers/ignored_controller.rb", "spec/fixtures/controllers/sample_controller.rb", "spec/lib/swagger/docs/generator_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rails>, [">= 0"])
      s.add_development_dependency(%q<appraisal>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rails>, [">= 0"])
      s.add_dependency(%q<appraisal>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rails>, [">= 0"])
    s.add_dependency(%q<appraisal>, [">= 0"])
  end
end
