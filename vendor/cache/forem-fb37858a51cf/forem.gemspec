# -*- encoding: utf-8 -*-
# stub: forem 1.0.0.beta1 ruby lib

Gem::Specification.new do |s|
  s.name = "forem"
  s.version = "1.0.0.beta1"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ryan Bigg", "Philip Arndt", "Josh Adams"]
  s.date = "2016-06-01"
  s.description = "The best Rails forum engine in the world."
  s.files = [".gitignore", ".rspec", ".travis.yml", ".zeus.rb", "CONTRIBUTING.md", "Gemfile", "MIT-LICENSE", "README.md", "Rakefile", "app/assets/javascripts/forem.js.erb", "app/assets/stylesheets/forem/base.css", "app/controllers/forem/admin/base_controller.rb", "app/controllers/forem/admin/categories_controller.rb", "app/controllers/forem/admin/forums_controller.rb", "app/controllers/forem/admin/groups_controller.rb", "app/controllers/forem/admin/members_controller.rb", "app/controllers/forem/admin/topics_controller.rb", "app/controllers/forem/admin/users_controller.rb", "app/controllers/forem/application_controller.rb", "app/controllers/forem/categories_controller.rb", "app/controllers/forem/forums_controller.rb", "app/controllers/forem/moderation_controller.rb", "app/controllers/forem/posts_controller.rb", "app/controllers/forem/topics_controller.rb", "app/decorators/controllers/application_controller_decorator.rb", "app/decorators/lib/forem/user_class_decorator.rb", "app/helpers/forem/admin/groups_helper.rb", "app/helpers/forem/admin/members_helper.rb", "app/helpers/forem/admin/moderators_helper.rb", "app/helpers/forem/admin/users_helper.rb", "app/helpers/forem/application_helper.rb", "app/helpers/forem/categories_helper.rb", "app/helpers/forem/formatting_helper.rb", "app/helpers/forem/forums_helper.rb", "app/helpers/forem/moderation_helper.rb", "app/helpers/forem/posts_helper.rb", "app/helpers/forem/topics_helper.rb", "app/mailers/forem/subscription_mailer.rb", "app/models/forem/ability.rb", "app/models/forem/category.rb", "app/models/forem/concerns/.keep", "app/models/forem/concerns/nil_user.rb", "app/models/forem/concerns/viewable.rb", "app/models/forem/forum.rb", "app/models/forem/group.rb", "app/models/forem/membership.rb", "app/models/forem/moderator_group.rb", "app/models/forem/nil_user.rb", "app/models/forem/post.rb", "app/models/forem/subscription.rb", "app/models/forem/topic.rb", "app/models/forem/view.rb", "app/views/forem/admin/base/index.html.erb", "app/views/forem/admin/categories/_form.html.erb", "app/views/forem/admin/categories/edit.html.erb", "app/views/forem/admin/categories/index.html.erb", "app/views/forem/admin/categories/new.html.erb", "app/views/forem/admin/forums/_form.html.erb", "app/views/forem/admin/forums/edit.html.erb", "app/views/forem/admin/forums/index.html.erb", "app/views/forem/admin/forums/new.html.erb", "app/views/forem/admin/groups/_form.html.erb", "app/views/forem/admin/groups/index.html.erb", "app/views/forem/admin/groups/new.html.erb", "app/views/forem/admin/groups/show.html.erb", "app/views/forem/admin/topics/_form.html.erb", "app/views/forem/admin/topics/edit.html.erb", "app/views/forem/categories/_category.html.erb", "app/views/forem/categories/show.html.erb", "app/views/forem/forums/_forum.html.erb", "app/views/forem/forums/_head.html.erb", "app/views/forem/forums/_listing.html.erb", "app/views/forem/forums/index.html.erb", "app/views/forem/forums/show.atom.builder", "app/views/forem/forums/show.html.erb", "app/views/forem/moderation/_options.html.erb", "app/views/forem/moderation/index.html.erb", "app/views/forem/posts/_form.html.erb", "app/views/forem/posts/_moderation_tools.html.erb", "app/views/forem/posts/_post.html.erb", "app/views/forem/posts/_reply_to_post.html.erb", "app/views/forem/posts/edit.html.erb", "app/views/forem/posts/new.html.erb", "app/views/forem/subscription_mailer/topic_reply.text.erb", "app/views/forem/topics/_form.html.erb", "app/views/forem/topics/_head.html.erb", "app/views/forem/topics/_topic.html.erb", "app/views/forem/topics/new.html.erb", "app/views/forem/topics/show.html.erb", "app/views/layouts/forem/default.html.erb", "bin/rails", "config/initializers/will_paginate.rb", "config/locales/ar.yml", "config/locales/bg.yml", "config/locales/bs.yml", "config/locales/cs.yml", "config/locales/de.yml", "config/locales/en.yml", "config/locales/es.yml", "config/locales/et.yml", "config/locales/fa.yml", "config/locales/fr.yml", "config/locales/it.yml", "config/locales/ja.yml", "config/locales/ko.yml", "config/locales/lt.yml", "config/locales/nl.yml", "config/locales/pl.yml", "config/locales/pt-BR.yml", "config/locales/pt-PT.yml", "config/locales/ru.yml", "config/locales/sk.yml", "config/locales/sv.yml", "config/locales/tr.yml", "config/locales/vi.yml", "config/locales/zh-CN.yml", "config/locales/zh-TW.yml", "config/routes.rb", "db/migrate/20110214221555_create_forem_forums.rb", "db/migrate/20110221092741_create_forem_topics.rb", "db/migrate/20110221094502_create_forem_posts.rb", "db/migrate/20110228084940_add_reply_to_to_forem_posts.rb", "db/migrate/20110519210300_add_locked_to_forem_topics.rb", "db/migrate/20110519222000_add_pinned_to_forem_topics.rb", "db/migrate/20110520150056_add_forem_views.rb", "db/migrate/20110626150056_add_updated_at_and_count_to_forem_views.rb", "db/migrate/20110626160056_add_hidden_to_forem_topics.rb", "db/migrate/20111026143136_add_indexes_to_topics_posts_views.rb", "db/migrate/20111103210835_create_forem_categories.rb", "db/migrate/20111103214432_add_category_id_to_forums.rb", "db/migrate/20111208014437_create_forem_subscriptions.rb", "db/migrate/20120221195806_add_pending_review_to_forem_posts.rb", "db/migrate/20120221195807_add_pending_review_to_forem_topics.rb", "db/migrate/20120222000227_add_forem_topics_last_post_at.rb", "db/migrate/20120222155549_create_forem_groups.rb", "db/migrate/20120222204450_create_forem_memberships.rb", "db/migrate/20120223162058_create_forem_moderator_groups.rb", "db/migrate/20120227195911_remove_pending_review_add_state_to_forem_posts.rb", "db/migrate/20120227202639_remove_pending_review_from_forem_topics_add_state.rb", "db/migrate/20120228194653_approve_all_topics_and_posts.rb", "db/migrate/20120228202859_add_notified_to_forem_posts.rb", "db/migrate/20120229165013_make_forem_views_polymorphic.rb", "db/migrate/20120302152918_add_forem_view_fields.rb", "db/migrate/20120616193446_add_forem_admin.rb", "db/migrate/20120616193447_add_forem_state.rb", "db/migrate/20120616193448_add_forem_auto_subscribe.rb", "db/migrate/20120718073130_add_friendly_id_slugs.rb", "db/migrate/20121203093719_rename_title_to_name_on_forem_forums.rb", "db/migrate/20140917034000_add_position_to_categories.rb", "db/migrate/20140917201619_add_position_to_forums.rb", "db/seeds.rb", "doc/theme.png", "forem.gemspec", "lib/forem.rb", "lib/forem/autocomplete.rb", "lib/forem/default_permissions.rb", "lib/forem/engine.rb", "lib/forem/platform.rb", "lib/forem/sanitizer.rb", "lib/forem/state_workflow.rb", "lib/forem/testing_support/factories.rb", "lib/forem/testing_support/factories/categories.rb", "lib/forem/testing_support/factories/forums.rb", "lib/forem/testing_support/factories/groups.rb", "lib/forem/testing_support/factories/posts.rb", "lib/forem/testing_support/factories/subscriptions.rb", "lib/forem/testing_support/factories/topics.rb", "lib/forem/testing_support/factories/users.rb", "lib/forem/testing_support/factories/views.rb", "lib/forem/version.rb", "lib/generators/forem/install/templates/initializer.rb", "lib/generators/forem/install_generator.rb", "lib/generators/forem/views_generator.rb", "lib/tasks/forem_tasks.rake", "script/rails", "spec/configuration_spec.rb", "spec/controllers/admin/forums_controller_spec.rb", "spec/controllers/moderation_controller_spec.rb", "spec/controllers/posts_controller_spec.rb", "spec/controllers/topics_controller_spec.rb", "spec/features/admin/authentication_spec.rb", "spec/features/admin/categories_spec.rb", "spec/features/admin/forum_moderators_spec.rb", "spec/features/admin/forums_spec.rb", "spec/features/admin/groups_spec.rb", "spec/features/admin/topics_spec.rb", "spec/features/authentication_spec.rb", "spec/features/categories_spec.rb", "spec/features/formatting_spec.rb", "spec/features/forums_spec.rb", "spec/features/moderation/approved_users_spec.rb", "spec/features/moderation/new_users_spec.rb", "spec/features/moderation/post_moderation_spec.rb", "spec/features/moderation/spam_users_spec.rb", "spec/features/moderation/topic_moderation_spec.rb", "spec/features/permissions/categories_spec.rb", "spec/features/permissions/forums_spec.rb", "spec/features/permissions/posts_spec.rb", "spec/features/posts_spec.rb", "spec/features/topic_listing_spec.rb", "spec/features/topics_spec.rb", "spec/features/user_link_spec.rb", "spec/generators/install_generator_spec.rb", "spec/generators/views_generator_spec.rb", "spec/helpers/application_helper_spec.rb", "spec/helpers/formatting_helper_spec.rb", "spec/helpers/posts_helper_spec.rb", "spec/lib/generators/forem/dummy/dummy_generator.rb", "spec/lib/generators/forem/dummy/templates/Rakefile", "spec/lib/generators/forem/dummy/templates/app/assets/javascripts/application.js", "spec/lib/generators/forem/dummy/templates/app/assets/stylesheets/application.css", "spec/lib/generators/forem/dummy/templates/app/controllers/application_controller.rb", "spec/lib/generators/forem/dummy/templates/app/controllers/fake_controller.rb", "spec/lib/generators/forem/dummy/templates/app/controllers/home_controller.rb", "spec/lib/generators/forem/dummy/templates/app/controllers/users_controller.rb", "spec/lib/generators/forem/dummy/templates/app/helpers/application_helper.rb", "spec/lib/generators/forem/dummy/templates/app/models/admin.rb", "spec/lib/generators/forem/dummy/templates/app/models/refunery/yooser.rb", "spec/lib/generators/forem/dummy/templates/app/models/user.rb", "spec/lib/generators/forem/dummy/templates/app/views/fake/sign_in.html.erb", "spec/lib/generators/forem/dummy/templates/app/views/home/index.html.erb", "spec/lib/generators/forem/dummy/templates/app/views/layouts/application.html.erb", "spec/lib/generators/forem/dummy/templates/config/application.rb", "spec/lib/generators/forem/dummy/templates/config/boot.rb", "spec/lib/generators/forem/dummy/templates/config/database.yml", "spec/lib/generators/forem/dummy/templates/config/initializers/devise.rb", "spec/lib/generators/forem/dummy/templates/config/initializers/simple_form.rb", "spec/lib/generators/forem/dummy/templates/config/routes.rb", "spec/lib/generators/forem/dummy/templates/db/migrate/1_create_users.rb", "spec/lib/generators/forem/dummy/templates/db/migrate/2_create_admins.rb", "spec/lib/generators/forem/dummy/templates/db/migrate/3_create_refunery_yoosers.rb", "spec/lib/tasks/forem_spec_tasks.rake", "spec/mailers/subscription_mailer_spec.rb", "spec/migrations/add_forem_admin_spec.rb", "spec/migrations/add_forem_auto_subscribe_spec.rb", "spec/migrations/add_forem_state_spec.rb", "spec/models/admin_spec.rb", "spec/models/category_spec.rb", "spec/models/forum_spec.rb", "spec/models/post_spec.rb", "spec/models/refunery_yooser_spec.rb", "spec/models/subscription_spec.rb", "spec/models/topic_spec.rb", "spec/models/user_spec.rb", "spec/models/view_spec.rb", "spec/spec_helper.rb", "spec/support/automatically_add_metadata.rb", "spec/support/capybara_ext.rb", "spec/support/controller_hacks.rb", "spec/support/database_cleaner.rb", "spec/support/devise.rb", "spec/support/factory_girl.rb", "spec/support/forem_formatters.rb", "spec/support/generator_macros.rb", "spec/support/mailer_macros.rb", "spec/support/migration_macros.rb", "spec/support/permission_helpers.rb", "spec/support/random_spec_order.rb", "spec/support/routes.rb", "spec/support/shared_context_for_migrations.rb", "spec/support/sign_in_helpers.rb", "spec/support/spec_logger.rb", "spec/views/forem/forums/_head.html.erb_spec.rb", "spec/views/forem/posts/_post.html.erb_spec.rb"]
  s.rubygems_version = "2.5.1"
  s.summary = "The best Rails forum engine in the world."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<launchy>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 3.2"])
      s.add_development_dependency(%q<rspec-activemodel-mocks>, ["~> 1.0.1"])
      s.add_development_dependency(%q<capybara>, ["= 2.3.0"])
      s.add_development_dependency(%q<jquery-rails>, [">= 0"])
      s.add_development_dependency(%q<factory_girl_rails>, ["~> 4.4.1"])
      s.add_development_dependency(%q<database_cleaner>, ["~> 1.0.0"])
      s.add_development_dependency(%q<devise>, ["~> 3.4.0"])
      s.add_development_dependency(%q<kaminari>, ["~> 0.15.0"])
      s.add_development_dependency(%q<timecop>, ["~> 0.6.1"])
      s.add_development_dependency(%q<sass-rails>, ["~> 4.0"])
      s.add_development_dependency(%q<coffee-rails>, ["~> 4.0"])
      s.add_runtime_dependency(%q<rails>, ["!= 4.2.0", "!= 4.2.1", "!= 4.2.2", "!= 4.2.3", "~> 4.0"])
      s.add_runtime_dependency(%q<simple_form>, ["~> 3.0"])
      s.add_runtime_dependency(%q<sanitize>, ["= 2.0.6"])
      s.add_runtime_dependency(%q<workflow>, ["= 1.0.0"])
      s.add_runtime_dependency(%q<gemoji>, ["= 2.1.0"])
      s.add_runtime_dependency(%q<decorators>, ["~> 1.0.2"])
      s.add_runtime_dependency(%q<select2-rails>, ["~> 3.5.4"])
      s.add_runtime_dependency(%q<friendly_id>, ["~> 5.0.0"])
      s.add_runtime_dependency(%q<cancancan>, ["~> 1.7"])
    else
      s.add_dependency(%q<launchy>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, ["~> 3.2"])
      s.add_dependency(%q<rspec-activemodel-mocks>, ["~> 1.0.1"])
      s.add_dependency(%q<capybara>, ["= 2.3.0"])
      s.add_dependency(%q<jquery-rails>, [">= 0"])
      s.add_dependency(%q<factory_girl_rails>, ["~> 4.4.1"])
      s.add_dependency(%q<database_cleaner>, ["~> 1.0.0"])
      s.add_dependency(%q<devise>, ["~> 3.4.0"])
      s.add_dependency(%q<kaminari>, ["~> 0.15.0"])
      s.add_dependency(%q<timecop>, ["~> 0.6.1"])
      s.add_dependency(%q<sass-rails>, ["~> 4.0"])
      s.add_dependency(%q<coffee-rails>, ["~> 4.0"])
      s.add_dependency(%q<rails>, ["!= 4.2.0", "!= 4.2.1", "!= 4.2.2", "!= 4.2.3", "~> 4.0"])
      s.add_dependency(%q<simple_form>, ["~> 3.0"])
      s.add_dependency(%q<sanitize>, ["= 2.0.6"])
      s.add_dependency(%q<workflow>, ["= 1.0.0"])
      s.add_dependency(%q<gemoji>, ["= 2.1.0"])
      s.add_dependency(%q<decorators>, ["~> 1.0.2"])
      s.add_dependency(%q<select2-rails>, ["~> 3.5.4"])
      s.add_dependency(%q<friendly_id>, ["~> 5.0.0"])
      s.add_dependency(%q<cancancan>, ["~> 1.7"])
    end
  else
    s.add_dependency(%q<launchy>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, ["~> 3.2"])
    s.add_dependency(%q<rspec-activemodel-mocks>, ["~> 1.0.1"])
    s.add_dependency(%q<capybara>, ["= 2.3.0"])
    s.add_dependency(%q<jquery-rails>, [">= 0"])
    s.add_dependency(%q<factory_girl_rails>, ["~> 4.4.1"])
    s.add_dependency(%q<database_cleaner>, ["~> 1.0.0"])
    s.add_dependency(%q<devise>, ["~> 3.4.0"])
    s.add_dependency(%q<kaminari>, ["~> 0.15.0"])
    s.add_dependency(%q<timecop>, ["~> 0.6.1"])
    s.add_dependency(%q<sass-rails>, ["~> 4.0"])
    s.add_dependency(%q<coffee-rails>, ["~> 4.0"])
    s.add_dependency(%q<rails>, ["!= 4.2.0", "!= 4.2.1", "!= 4.2.2", "!= 4.2.3", "~> 4.0"])
    s.add_dependency(%q<simple_form>, ["~> 3.0"])
    s.add_dependency(%q<sanitize>, ["= 2.0.6"])
    s.add_dependency(%q<workflow>, ["= 1.0.0"])
    s.add_dependency(%q<gemoji>, ["= 2.1.0"])
    s.add_dependency(%q<decorators>, ["~> 1.0.2"])
    s.add_dependency(%q<select2-rails>, ["~> 3.5.4"])
    s.add_dependency(%q<friendly_id>, ["~> 5.0.0"])
    s.add_dependency(%q<cancancan>, ["~> 1.7"])
  end
end
