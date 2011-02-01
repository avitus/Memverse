MemverseApp::Application.routes.draw do
 
  # Restful Authentication Rewrites
  
  match '/login',                       :to => 'sessions#new',      :as => 'login'
  match '/logout',                      :to => 'sessions#destroy',  :as => 'logout'
  match '/register',                    :to => 'users#create',      :as => 'register'
  match '/signup',                      :to => 'users#new',         :as => 'signup'
  match '/activate/:activation_code',   :to => 'users#activate',    :as => 'activate',  :activation_code => nil
  match '/forgot_password',             :to => 'passwords#new',     :as => 'forgot_password'
  match '/change_password/:reset_code', :to => 'passwords#reset',   :as => 'change_password'

  match '/opensession',                 :to => 'sessions#create',   :as => 'open_id_complete',  :via => [:get]
  match '/opencreate',                  :to => 'users#create',      :as => 'open_id_create',    :via => [:get]

  
  # Restful Authentication Resources
  resources :users
  resources :passwords
  resource  :session
  resources :uberverses
# resources :pastors
  resources :sermons
  resources :quests

  
  # My Mappings
  match '/add_verse',             :to => 'memverses#add_verse',             :as => 'add_verse'
  match '/quick_add',             :to => 'memverses#quick_add',             :as => 'quick_add'
  match '/test_verse',            :to => 'memverses#test_verse',            :as => 'test_verse'
  match '/test_verse_quick',      :to => 'memverses#test_verse_quick',      :as => 'test_verse_quick'
  match '/mark_test',             :to => 'memverses#mark_test',             :as => 'mark_test'
  match '/mark_test_quick',       :to => 'memverses#mark_test_quick',       :as => 'mark_test_quick'
  match '/test_ref',              :to => 'memverses#test_ref',              :as => 'test_ref'
  match '/start_ref_test',        :to => 'memverses#load_test_ref',         :as => 'start_ref_test'
  match '/exam',                  :to => 'memverses#load_exam',             :as => 'load_exam'
  match '/pre_exam',              :to => 'memverses#explain_exam',          :as => 'pre_exam'
  match '/pre_chapter',           :to => 'memverses#chapter_explanation',   :as => 'pre_chapter'
  match '/drill_verse',           :to => 'memverses#drill_verse',           :as => 'drill_verse'
  match '/mark_test',             :to => 'memverses#mark_test',             :as => 'mark_test'
  match '/mark_drill',            :to => 'memverses#mark_drill',            :as => 'mark_drill'
  match '/show_all_my_verses',    :to => 'memverses#show_all_my_verses',    :as => 'show_all_my_verses'
  match '/user_stats',            :to => 'memverses#user_stats',            :as => 'user_stats'
  match '/progress',              :to => 'memverses#show_progress',         :as => 'progress'
  match '/popular_verses',        :to => 'memverses#pop_verses',            :as => 'popular_verses'
  match '/home',                  :to => 'memverses#index',                 :as => 'index'
  match '/starter_pack',          :to => 'memverses#starter_pack',          :as => 'starter_pack'
  match '/memory_verse/:id',      :to => 'memverses#show',                  :as => 'memory_verse'
  
  match '/tag_cloud',             :to => 'verses#tag_cloud',                :as => 'tag_cloud'
  match '/check_verses',          :to => 'verses#check_verses',             :as => 'check_verses'
  
  match '/show_user_info',        :to => 'admin#show_user_info',            :as => 'show_user_info'
  match '/show_tags',             :to => 'admin#show_tags',                 :as => 'show_tags'
  
  
  # Doesn't require a login
  match '/contact',               :to => 'info#contact',                    :as => 'contact'   
  match '/faq',                   :to => 'info#faq',                        :as => 'faq'
  match '/tutorial',              :to => 'info#tutorial',                   :as => 'tutorial'
  match '/volunteer',             :to => 'info#volunteer',                  :as => 'volunteer'
  match '/popular',               :to => 'info#pop_verses',                 :as => 'popular'
  match '/supermemo',             :to => 'info#sm_description',             :as => 'supermemo'
  match '/demo',                  :to => 'info#demo_test_verse',            :as => 'demo'
  match '/leaderboard',           :to => 'info#leaderboard',                :as => 'leaderboard'
  match '/churchboard',           :to => 'info#churchboard',                :as => 'churchboard'
  match '/stateboard',            :to => 'info#stateboard',                 :as => 'stateboard'
  match '/countryboard',          :to => 'info#countryboard',               :as => 'countryboard'
  match '/memverse_clock',        :to => 'info#memverse_clock',             :as => 'memverse_clock'
  match '/referralboard',         :to => 'info#referralboard',              :as => 'referralboard'
  match '/news',                  :to => 'info#news',                       :as => 'news'
 
  match '/update_profile',        :to => 'profile#update_profile',          :as => 'update_profile'
  match '/church',                :to => 'profile#show_church',             :as => 'church'
  match '/referrals/:id',         :to => 'profile#referrals',               :as => 'referrals'
  match '/unsubscribe/*email',    :to => 'profile#unsubscribe',             :as => 'unsubscribe'
  
  match '/edit_tag/:id',          :to => 'tag#edit_tag',                    :as => 'edit_tag'

  # Tweet routes
  match '/tweets',                :to => 'tweets#index',                    :as => 'tweets'  

  # Game routes  
  match '/verse_scramble',        :to => 'games#verse_scramble',            :as => 'verse_scramble'  
  
  # Blog routes
  # map.blog                '/blog',                      :controller => 'blog_posts',    :action => 'index'
  match '/blog_comments_new',    :to => 'blog_comments#recent_comments',   :as => 'blog_comments_new'
  
  # Routes for Ziya graphs
  match '/load_progress/:user',  :to => 'chart#load_progress',             :as => 'load_progress'
  match '/load_memverse_clock',  :to => 'chart#load_memverse_clock',       :as => 'load_memverse_clock' 
  
  # Root Home Page
  root :to => 'sessions#new', :as => 'home'

  # Install the default routes as the lowest priority. 
  match '/:controller(/:action(/:id))'
  
  # Route for random pages
  # match.page                ':action',                    :controller => 'pages'    
end
