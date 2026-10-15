# Bloggity::BlogsController (avitus/bloggity gem) ships without an authorization
# filter, so anyone - even anonymous visitors - could create, edit or destroy a
# blog. Restrict everything except the public show and feed actions to users who
# can modify blogs (admins), the same policy Bloggity::BlogCategoriesController uses.
Rails.application.config.to_prepare do
  Bloggity::BlogsController.class_eval do
    include Bloggity::ApplicationHelper

    before_action :can_modify_blogs_or_redirect, except: [:show, :feed]
  end
end
