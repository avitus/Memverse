class Doorkeeper::InstallGenerator < ::Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  desc "Installs Doorkeeper."

  def install
    template "initializer.rb", "config/initializers/doorkeeper.rb"
    copy_file "../../../../config/locales/en.yml", "config/locales/doorkeeper.en.yml"
    route "use_doorkeeper"
    readme "README"
  end
end
