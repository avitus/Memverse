# -*- encoding: utf-8 -*-
# stub: best_in_place 3.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "best_in_place"
  s.version = "3.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Bernat Farrero"]
  s.date = "2016-06-01"
  s.description = "  BestInPlace is a jQuery script and a Rails helper that provide the method best_in_place to display\n  any object field easily editable for the user by just clicking on it. It supports input data,\n  text data, boolean data and custom dropdown data. It works with RESTful controllers.\n"
  s.email = ["bernat@itnig.net"]
  s.files = [".gitignore", ".rspec", ".travis.yml", "Appraisals", "CHANGELOG.md", "Gemfile", "README.md", "Rakefile", "best_in_place.gemspec", "config.ru", "gemfiles/rails_3.2.gemfile", "gemfiles/rails_4.0.gemfile", "gemfiles/rails_4.1.gemfile", "gemfiles/rails_4.2.gemfile", "gemfiles/rails_edge.gemfile", "lib/assets/javascripts/best_in_place.jquery-ui.js", "lib/assets/javascripts/best_in_place.js", "lib/assets/javascripts/best_in_place.purr.js", "lib/best_in_place.rb", "lib/best_in_place/controller_extensions.rb", "lib/best_in_place/display_methods.rb", "lib/best_in_place/engine.rb", "lib/best_in_place/helper.rb", "lib/best_in_place/railtie.rb", "lib/best_in_place/test_helpers.rb", "lib/best_in_place/utils.rb", "lib/best_in_place/version.rb", "spec/helper_spec.rb", "spec/integration/double_init_spec.rb", "spec/integration/js_spec.rb", "spec/integration/live_spec.rb", "spec/integration/placeholder_spec.rb", "spec/integration/text_area_spec.rb", "spec/internal/app/assets/images/info.png", "spec/internal/app/assets/images/no.png", "spec/internal/app/assets/images/purrBottom.png", "spec/internal/app/assets/images/purrClose.png", "spec/internal/app/assets/images/purrTop.png", "spec/internal/app/assets/images/red_pen.png", "spec/internal/app/assets/images/ui-bg_diagonals-thick_18_b81900_40x40.png", "spec/internal/app/assets/images/ui-bg_diagonals-thick_20_666666_40x40.png", "spec/internal/app/assets/images/ui-bg_flat_10_000000_40x100.png", "spec/internal/app/assets/images/ui-bg_glass_100_f6f6f6_1x400.png", "spec/internal/app/assets/images/ui-bg_glass_100_fdf5ce_1x400.png", "spec/internal/app/assets/images/ui-bg_glass_65_ffffff_1x400.png", "spec/internal/app/assets/images/ui-bg_gloss-wave_35_f6a828_500x100.png", "spec/internal/app/assets/images/ui-bg_highlight-soft_100_eeeeee_1x100.png", "spec/internal/app/assets/images/ui-bg_highlight-soft_75_ffe45c_1x100.png", "spec/internal/app/assets/images/ui-icons_222222_256x240.png", "spec/internal/app/assets/images/ui-icons_228ef1_256x240.png", "spec/internal/app/assets/images/ui-icons_ef8c08_256x240.png", "spec/internal/app/assets/images/ui-icons_ffd27a_256x240.png", "spec/internal/app/assets/images/ui-icons_ffffff_256x240.png", "spec/internal/app/assets/images/yes.png", "spec/internal/app/assets/javascripts/application.js", "spec/internal/app/assets/stylesheets/.gitkeep", "spec/internal/app/assets/stylesheets/jquery-ui-1.8.16.custom.css.erb", "spec/internal/app/assets/stylesheets/scaffold.css", "spec/internal/app/assets/stylesheets/style.css", "spec/internal/app/controllers/admin/users_controller.rb", "spec/internal/app/controllers/application_controller.rb", "spec/internal/app/controllers/cuca/cars_controller.rb", "spec/internal/app/controllers/users_controller.rb", "spec/internal/app/helpers/application_helper.rb", "spec/internal/app/helpers/users_helper.rb", "spec/internal/app/models/cuca/car.rb", "spec/internal/app/models/user.rb", "spec/internal/app/views/admin/users/show.html.erb", "spec/internal/app/views/cuca/cars/show.html.erb", "spec/internal/app/views/layouts/application.html.erb", "spec/internal/app/views/users/_form.html.erb", "spec/internal/app/views/users/double_init.html.erb", "spec/internal/app/views/users/edit.html.erb", "spec/internal/app/views/users/email_field.html.erb", "spec/internal/app/views/users/index.html.erb", "spec/internal/app/views/users/new.html.erb", "spec/internal/app/views/users/show.html.erb", "spec/internal/app/views/users/show_ajax.html.erb", "spec/internal/config/database.yml", "spec/internal/config/initializers/countries.rb", "spec/internal/config/initializers/default_date_format.rb", "spec/internal/config/initializers/development.rb", "spec/internal/config/routes.rb", "spec/internal/db/schema.rb", "spec/internal/public/favicon.ico", "spec/rails_helper.rb", "spec/support/retry_on_timeout.rb", "spec/support/screenshot.rb", "spec/utils_spec.rb", "vendor/assets/javascripts/jquery.autosize.js", "vendor/assets/javascripts/jquery.purr.js"]
  s.homepage = "http://github.com/bernat/best_in_place"
  s.rubygems_version = "2.5.1"
  s.summary = "It makes any field in place editable by clicking on it, it works for inputs, textareas, select dropdowns and checkboxes"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>, [">= 3.2"])
      s.add_runtime_dependency(%q<railties>, [">= 3.2"])
    else
      s.add_dependency(%q<actionpack>, [">= 3.2"])
      s.add_dependency(%q<railties>, [">= 3.2"])
    end
  else
    s.add_dependency(%q<actionpack>, [">= 3.2"])
    s.add_dependency(%q<railties>, [">= 3.2"])
  end
end
