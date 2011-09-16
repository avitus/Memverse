MemverseApp::Application.routes.draw do
  
  resources :blogs do
    
    resources :blog_posts do     
      
      collection do
        get :pending
        post :create_asset
      end
      
      member do
        get :close
      end
    
    end
   
    member do
      get :feed
    end
   
  end	
	
	resources :blog_categories
	resources :blog_assets
	resources :blog_comments, :member => { :approve => :get }
	
	match  'blog/:blog_url_id_or_id',     :to => 'blog_posts#index'
	match  'blog/:blog_url_id_or_id/:id', :to => 'blog_posts#show'
	match  'blog',                        :to => 'blog_posts#index', :as => 'blog', :blog_url_id_or_id => 'main'

end

 