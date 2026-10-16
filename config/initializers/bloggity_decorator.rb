# Bloggity::BlogsController (avitus/bloggity gem) ships without an authorization
# filter, so anyone - even anonymous visitors - could create, edit or destroy a
# blog. Restrict everything except the public show and feed actions to users who
# can modify blogs (admins), the same policy Bloggity::BlogCategoriesController uses.
#
# The gem's blog_params also omits feedburner_url, which its edit form submits,
# so that field was silently dropped on update.
Rails.application.config.to_prepare do
  Bloggity::BlogsController.class_eval do
    include Bloggity::ApplicationHelper

    before_action :can_modify_blogs_or_redirect, except: [:show, :feed]

    private def blog_params
      params.require(:blog).permit(:title, :subtitle, :url_identifier, :stylesheet, :feedburner_url)
    end
  end
end
