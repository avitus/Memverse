# coding: utf-8
MemverseApp::Application.routes.draw do
 
  # Restful Authentication Rewrites
  
  match '/login',                       :to => 'sessions#new',      :as => 'login'
  match '/logout',                      :to => 'sessions#destroy',  :as => 'logout'
  match '/register',                    :to => 'users#create',      :as => 'register'
  match '/signup',                      :to => 'users#new',         :as => 'signup'
  match '/activate/:activation_code',   :to => 'users#activate',    :as => 'activate',  :activation_code => nil
  match '/forgot_password',             :to => 'passwords#new',     :as => 'forgot_password'
  match '/change_password/:reset_code', :to => 'passwords#reset',   :as => 'change_password'

  # Remove open_id_authentication to solve problem with empty params hash
  # match '/opensession',                 :to => 'sessions#create',   :as => 'open_id_complete',  :via => [:get]
  # match '/opencreate',                  :to => 'users#create',      :as => 'open_id_create',    :via => [:get]

  
  # Restful Authentication Resources
  resources :users
  resources :passwords
  resource  :session
  resources :uberverses
# resources :pastors
  resources :sermons
  resources :quests
  resources :memverses

  
  # My Mappings
  match '/add_verse',             :to => 'memverses#add_verse',             :as => 'add_verse'
  match '/quick_add',             :to => 'memverses#quick_add',             :as => 'quick_add'
  match '/avail_translations',    :to => 'memverses#avail_translations',    :as => 'avail_translations'
  match '/edit_verse/:id',    	  :to => 'memverses#edit_verse',    		:as => 'edit_verse'
  match '/test_verse',            :to => 'memverses#test_verse',            :as => 'test_verse'
  match '/feedback',              :to => 'memverses#feedback',              :as => 'feedback'
  match '/upcoming_verses',       :to => 'memverses#upcoming_verses',       :as => 'upcoming_verses'
  match '/test_verse_quick',      :to => 'memverses#test_verse_quick',      :as => 'test_verse_quick'
  match '/test_next_verse',       :to => 'memverses#test_next_verse',       :as => 'test_next_verse'
  match '/mark_test',             :to => 'memverses#mark_test',             :as => 'mark_test'
  match '/mark_test_quick',       :to => 'memverses#mark_test_quick',       :as => 'mark_test_quick'
  match '/test_ref',              :to => 'memverses#test_ref',              :as => 'test_ref'
  match '/reftest_results',       :to => 'memverses#reftest_results',       :as => 'reftest_results'
  match '/start_ref_test',        :to => 'memverses#load_test_ref',         :as => 'start_ref_test'
  match '/exam',                  :to => 'memverses#load_exam',             :as => 'exam'
  match '/pre_exam',              :to => 'memverses#explain_exam',          :as => 'pre_exam'
  match '/pre_chapter',           :to => 'memverses#chapter_explanation',   :as => 'pre_chapter'
  match '/test_chapter',          :to => 'memverses#test_chapter',			:as => 'test_chapter'
  match '/drill_verse',           :to => 'memverses#drill_verse',           :as => 'drill_verse'
  match '/mark_test',             :to => 'memverses#mark_test',             :as => 'mark_test'
  match '/mark_drill',            :to => 'memverses#mark_drill',            :as => 'mark_drill'
  match '/manage_verses',         :to => 'memverses#manage_verses',         :as => 'manage_verses'
  match '/show_all_my_verses',    :to => 'memverses#manage_verses',         :as => 'manage_verses'
  match '/user_stats',            :to => 'memverses#user_stats',            :as => 'user_stats'
  match '/progress',              :to => 'memverses#show_progress',         :as => 'progress'
  match '/save_progress_report',  :to => 'memverses#save_progress_report',  :as => 'save_progress_report'
  match '/popular_verses',        :to => 'memverses#pop_verses',            :as => 'popular_verses'
  match '/home',                  :to => 'memverses#index',                 :as => 'index'
  match '/starter_pack',          :to => 'memverses#starter_pack',          :as => 'starter_pack'
  match '/memory_verse/:id',      :to => 'memverses#show',                  :as => 'memory_verse'
  match '/memverse_counter',      :to => 'memverses#memverse_counter',      :as => 'memverse_counter'

  
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
  match '/search_user',    		  :to => 'profile#search_user',             :as => 'search_user'
  
  match '/edit_tag/:id',          :to => 'tag#edit_tag',                    :as => 'edit_tag'

  # Tweet routes
  match '/tweets',                :to => 'tweets#index',                    :as => 'tweets'  

  # Game routes  
  match '/verse_scramble',        :to => 'games#verse_scramble',            :as => 'verse_scramble'  
  
  # Blog routes
  match '/blog',                 :to => 'blog_posts#index',                :as => 'blog'
  match '/blog_comments_new',    :to => 'blog_comments#recent_comments',   :as => 'blog_comments_new'
  
  # Routes for Ziya graphs
  match '/load_progress/:user',  :to => 'chart#load_progress',             :as => 'load_progress'
  match '/load_memverse_clock',  :to => 'chart#load_memverse_clock',       :as => 'load_memverse_clock' 
  
  # Root and Home Page
  root :to => 'sessions#new'
  match '/home',                  :to => 'sessions#new'

  # Install the default routes as the lowest priority. 
  match '/:controller(/:action(/:id))'

  # Route for random pages
  match '/:action',                 :to => 'pages#:action' 
  
end
