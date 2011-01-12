Memverse::Application.routes.draw do |map|
  map.resources :blogs, :member => { :feed => :get } do |blogs|
		blogs.resources :blog_posts, :collection => { :create_asset => :post, :pending => :get }, :member => { :close => :get }
	end
	
	map.resources :blog_categories
	map.resources :blog_assets
	map.resources :blog_comments, :member => { :approve => :get }
	
	map.connect  'blog/:blog_url_id_or_id',     :controller => 'blog_posts', :action => 'index'
	map.connect  'blog/:blog_url_id_or_id/:id', :controller => 'blog_posts', :action => 'show'
	map.blog     'blog',                        :controller => 'blog_posts', :action => 'index', :blog_url_id_or_id => 'main'
end

# Useful URL's for handling routing of blog resources
# https://rails.lighthouseapp.com/projects/8994/tickets/267-form_for-for-singular-resource-will-products-plural-invokes
# http://www.hostingrails.com/undefined-method-to_sym-for-nil-NilClass-error
# http://www.ruby-forum.com/topic/165511
# http://guides.rubyonrails.org/routing.html