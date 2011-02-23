# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{map_by_method}
  s.version = "0.8.3"

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Dr Nic Williams"]
  s.cert_chain = nil
  s.date = %q{2007-11-15}
  s.description = %q{Replacement for map {|obj| obj.action} and Symbol.to_proc which is much cleaner and prettier NOW WORKS with ActiveRecord Associations!!}
  s.email = %q{drnicwilliams@gmail.com}
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "README.txt", "website/index.txt"]
  s.files = ["History.txt", "License.txt", "Manifest.txt", "README.txt", "Rakefile", "Rakefile.old", "config/hoe.rb", "config/requirements.rb", "install.rb", "lib/map_by_method.rb", "lib/map_by_method/version.rb", "log/debug.log", "script/destroy", "script/generate", "script/txt2html", "setup.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/website.rake", "test/test_ar_association_proxy.rb", "test/test_helper.rb", "test/test_map_by_method.rb", "test/test_multiple_methods.rb", "test/test_respond_to.rb", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.rhtml"]
  s.homepage = %q{http://drnicutilities.rubyforge.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubyforge_project = %q{drnicutilities}
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{Replacement for map {|obj| obj.action} and Symbol.to_proc which is much cleaner and prettier NOW WORKS with ActiveRecord Associations!!}
  s.test_files = ["test/test_ar_association_proxy.rb", "test/test_helper.rb", "test/test_map_by_method.rb", "test/test_multiple_methods.rb", "test/test_respond_to.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 1

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
