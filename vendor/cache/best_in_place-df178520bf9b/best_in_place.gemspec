# -*- encoding: utf-8 -*-
# stub: best_in_place 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "best_in_place"
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Bernat Farrero"]
  s.date = "2015-03-05"
  s.description = "BestInPlace is a jQuery script and a Rails 3 helper that provide the method best_in_place to display any object field easily editable for the user by just clicking on it. It supports input data, text data, boolean data and custom dropdown data. It works with RESTful controllers."
  s.email = ["bernat@itnig.net"]
  s.files = [".gitignore", ".rspec", ".travis.yml", "CHANGELOG.md", "Gemfile", "README.md", "Rakefile", "best_in_place.gemspec", "lib/assets/javascripts/best_in_place.js", "lib/assets/javascripts/best_in_place.purr.js", "lib/assets/javascripts/jquery.purr.js", "lib/best_in_place.rb", "lib/best_in_place/check_version.rb", "lib/best_in_place/controller_extensions.rb", "lib/best_in_place/display_methods.rb", "lib/best_in_place/engine.rb", "lib/best_in_place/helper.rb", "lib/best_in_place/railtie.rb", "lib/best_in_place/test_helpers.rb", "lib/best_in_place/utils.rb", "lib/best_in_place/version.rb", "spec/helpers/best_in_place_spec.rb", "spec/integration/double_init_spec.rb", "spec/integration/js_spec.rb", "spec/integration/live_spec.rb", "spec/integration/text_area_spec.rb", "spec/spec_helper.rb", "spec/support/retry_on_timeout.rb", "test_app/Gemfile", "test_app/README", "test_app/Rakefile", "test_app/app/assets/images/no.png", "test_app/app/assets/images/red_pen.png", "test_app/app/assets/images/ui-bg_diagonals-thick_18_b81900_40x40.png", "test_app/app/assets/images/ui-bg_diagonals-thick_20_666666_40x40.png", "test_app/app/assets/images/ui-bg_flat_10_000000_40x100.png", "test_app/app/assets/images/ui-bg_glass_100_f6f6f6_1x400.png", "test_app/app/assets/images/ui-bg_glass_100_fdf5ce_1x400.png", "test_app/app/assets/images/ui-bg_glass_65_ffffff_1x400.png", "test_app/app/assets/images/ui-bg_gloss-wave_35_f6a828_500x100.png", "test_app/app/assets/images/ui-bg_highlight-soft_100_eeeeee_1x100.png", "test_app/app/assets/images/ui-bg_highlight-soft_75_ffe45c_1x100.png", "test_app/app/assets/images/ui-icons_222222_256x240.png", "test_app/app/assets/images/ui-icons_228ef1_256x240.png", "test_app/app/assets/images/ui-icons_ef8c08_256x240.png", "test_app/app/assets/images/ui-icons_ffd27a_256x240.png", "test_app/app/assets/images/ui-icons_ffffff_256x240.png", "test_app/app/assets/images/yes.png", "test_app/app/assets/javascripts/application.js", "test_app/app/assets/stylesheets/.gitkeep", "test_app/app/assets/stylesheets/jquery-ui-1.8.16.custom.css.erb", "test_app/app/assets/stylesheets/scaffold.css", "test_app/app/assets/stylesheets/style.css.erb", "test_app/app/controllers/admin/users_controller.rb", "test_app/app/controllers/application_controller.rb", "test_app/app/controllers/cuca/cars_controller.rb", "test_app/app/controllers/users_controller.rb", "test_app/app/helpers/application_helper.rb", "test_app/app/helpers/users_helper.rb", "test_app/app/models/cuca/car.rb", "test_app/app/models/user.rb", "test_app/app/views/admin/users/show.html.erb", "test_app/app/views/cuca/cars/show.html.erb", "test_app/app/views/layouts/application.html.erb", "test_app/app/views/users/_form.html.erb", "test_app/app/views/users/double_init.html.erb", "test_app/app/views/users/edit.html.erb", "test_app/app/views/users/email_field.html.erb", "test_app/app/views/users/index.html.erb", "test_app/app/views/users/new.html.erb", "test_app/app/views/users/show.html.erb", "test_app/app/views/users/show_ajax.html.erb", "test_app/config.ru", "test_app/config/application.rb", "test_app/config/boot.rb", "test_app/config/database.yml", "test_app/config/environment.rb", "test_app/config/environments/development.rb", "test_app/config/environments/production.rb", "test_app/config/environments/test.rb", "test_app/config/initializers/backtrace_silencers.rb", "test_app/config/initializers/countries.rb", "test_app/config/initializers/default_date_format.rb", "test_app/config/initializers/inflections.rb", "test_app/config/initializers/mime_types.rb", "test_app/config/initializers/secret_token.rb", "test_app/config/initializers/session_store.rb", "test_app/config/locales/en.yml", "test_app/config/routes.rb", "test_app/db/migrate/20101206205922_create_users.rb", "test_app/db/migrate/20101212170114_add_receive_email_to_user.rb", "test_app/db/migrate/20110115204441_add_description_to_user.rb", "test_app/db/migrate/20111210084202_add_favorite_color_to_users.rb", "test_app/db/migrate/20111210084251_add_favorite_books_to_users.rb", "test_app/db/migrate/20111217215935_add_birth_date_to_users.rb", "test_app/db/migrate/20111224181356_add_money_to_user.rb", "test_app/db/migrate/20120513003308_create_cars.rb", "test_app/db/migrate/20120607172609_add_favorite_movie_to_users.rb", "test_app/db/migrate/20120616170454_add_money_proc_to_users.rb", "test_app/db/migrate/20120620165212_add_height_to_user.rb", "test_app/db/migrate/20130213224102_add_favorite_locale_to_users.rb", "test_app/db/schema.rb", "test_app/db/seeds.rb", "test_app/doc/README_FOR_APP", "test_app/lib/tasks/.gitkeep", "test_app/lib/tasks/cron.rake", "test_app/public/404.html", "test_app/public/422.html", "test_app/public/500.html", "test_app/public/favicon.ico", "test_app/public/robots.txt", "test_app/script/rails", "test_app/test/fixtures/users.yml", "test_app/test/functional/users_controller_test.rb", "test_app/test/performance/browsing_test.rb", "test_app/test/test_helper.rb", "test_app/test/unit/helpers/users_helper_test.rb", "test_app/test/unit/user_test.rb", "test_app/vendor/plugins/.gitkeep"]
  s.homepage = "http://github.com/bernat/best_in_place"
  s.rubyforge_project = "best_in_place"
  s.rubygems_version = "2.4.6"
  s.summary = "It makes any field in place editable by clicking on it, it works for inputs, textareas, select dropdowns and checkboxes"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 3.1"])
      s.add_runtime_dependency(%q<jquery-rails>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.8.0"])
      s.add_development_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<capybara>, ["~> 1.1.2"])
    else
      s.add_dependency(%q<rails>, [">= 3.1"])
      s.add_dependency(%q<jquery-rails>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.8.0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<capybara>, ["~> 1.1.2"])
    end
  else
    s.add_dependency(%q<rails>, [">= 3.1"])
    s.add_dependency(%q<jquery-rails>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.8.0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<capybara>, ["~> 1.1.2"])
  end
end
