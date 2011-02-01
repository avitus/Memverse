MemverseApp::Application.routes.draw do |map|
  map.resources :blogs, :member => { :feed => :get } do |blogs|
		blogs.resources :blog_posts, :collection => { :create_asset => :post, :pending => :get }, :member => { :close => :get }
  end
	
	resources :blog_categories
	resources :blog_assets
	resources :blog_comments, :member => { :approve => :get }
	
	match  'blog/:blog_url_id_or_id',     :to => 'blog_posts#index'
	match  'blog/:blog_url_id_or_id/:id', :to => 'blog_posts#show'
	match  'blog',                        :to => 'blog_posts#index', :as => 'blog', :blog_url_id_or_id => 'main'
end