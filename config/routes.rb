ActionController::Routing::Routes.draw do |map|
 
  # Restful Authentication Rewrites
  map.logout            '/logout',                      :controller => 'sessions',    :action => 'destroy'
  map.login             '/login',                       :controller => 'sessions',    :action => 'new'
  map.register          '/register',                    :controller => 'users',       :action => 'create'
  map.signup            '/signup',                      :controller => 'users',       :action => 'new'
  map.activate          '/activate/:activation_code',   :controller => 'users',       :action => 'activate',  :activation_code => nil
  map.forgot_password   '/forgot_password',             :controller => 'passwords',   :action => 'new'
  map.change_password   '/change_password/:reset_code', :controller => 'passwords',   :action => 'reset'
  map.open_id_complete  '/opensession',                 :controller => "sessions",    :action => "create",    :requirements => { :method => :get }
  map.open_id_create    '/opencreate',                  :controller => "users",       :action => "create",    :requirements => { :method => :get }
  
  # Restful Authentication Resources
  map.resources :users
  map.resources :passwords
  map.resource  :session
  map.resources :uberverses
  map.resources :pastors
  map.resources :sermons
  map.resources :quests
  map.resources :collections  
  
  # My Mappings
  map.add_verse           '/add_verse',                 :controller => 'memverses',   :action => 'add_verse'
  map.quick_add           '/quick_add',                 :controller => 'memverses',   :action => 'quick_add'
  map.test_verse          '/test_verse',                :controller => 'memverses',   :action => 'test_verse' 
  map.mark_test           '/mark_test',                 :controller => 'memverses',   :action => 'mark_test' 
  map.test_ref            '/test_ref',                  :controller => 'memverses',   :action => 'test_ref'   
  map.start_ref_test      '/start_ref_test',            :controller => 'memverses',   :action => 'load_test_ref'
  map.exam                '/test_yourself',             :controller => 'memverses',   :action => 'load_exam'
  map.pre_exam            '/accuracy_explanation',      :controller => 'memverses',   :action => 'explain_exam'
  map.pre_chapter         '/chapter_review',            :controller => 'memverses',   :action => 'chapter_explanation'
  map.drill_verse         '/drill_verse',               :controller => 'memverses',   :action => 'drill_verse'
  map.mark_test           '/mark_test',                 :controller => 'memverses',   :action => 'mark_test'    
  map.mark_drill          '/mark_drill',                :controller => 'memverses',   :action => 'mark_drill'
  map.show_all_my_verses  '/show_all_my_verses',        :controller => 'memverses',   :action => 'show_all_my_verses'
  map.user_stats          '/user_stats',                :controller => 'memverses',   :action => 'user_stats'
  map.progress            '/progress',                  :controller => 'memverses',   :action => 'show_progress'
  map.popular_verses      '/popular_verses',            :controller => 'memverses',   :action => 'pop_verses'
  map.home                '/home',                      :controller => 'memverses',   :action => 'index'
  map.starter_pack        '/starter_pack',              :controller => 'memverses',   :action => 'starter_pack'
  map.memory_verse        '/memory_verse/:id',          :controller => 'memverses',   :action => 'show'
  
  map.tag_cloud           '/tag_cloud',                 :controller => 'verses',      :action => 'tag_cloud'
  
  map.show_user_info      '/show_user_info',            :controller => 'admin',       :action => 'show_user_info' 
  map.show_tags           '/show_tags',                 :controller => 'admin',       :action => 'show_tags'
  
  
  # Doesn't require a login
  map.contact             '/contact',                   :controller => 'info',        :action => 'contact'   
  map.tutorial            '/tutorial',                  :controller => 'info',        :action => 'tutorial'  
  map.volunteer           '/volunteer',                 :controller => 'info',        :action => 'volunteer' 
  map.popular             '/popular',                   :controller => 'info',        :action => 'pop_verses'
  map.supermemo           '/supermemo',                 :controller => 'info',        :action => 'sm_description'
  map.demo                '/demo',                      :controller => 'info',        :action => 'demo_test_verse' 
  map.leaderboard         '/leaderboard',               :controller => 'info',        :action => 'leaderboard'
  map.churchboard         '/churchboard',               :controller => 'info',        :action => 'churchboard'
  map.stateboard          '/stateboard',                :controller => 'info',        :action => 'stateboard'
  map.countryboard        '/countryboard',              :controller => 'info',        :action => 'countryboard'  
  map.memverse_clock      '/memverse_clock',            :controller => 'info',        :action => 'memverse_clock'  
  map.news                '/news',                      :controller => 'info',        :action => 'news'
 
  map.update_profile      '/update_profile',            :controller => 'profile',     :action => 'update_profile'
  map.church              '/church',                    :controller => 'profile',     :action => 'show_church'
  map.referrals           '/referrals/:id',             :controller => 'profile',     :action => 'referrals'
  map.unsubscribe         '/unsubscribe/*email',        :controller => 'profile',     :action => 'unsubscribe'
  
  map.edit_tag           '/edit_tag/:id',               :controller => 'tag',         :action => 'edit_tag'

  # Tweet routes
  map.tweets              '/tweets',                    :controller => 'tweets',      :action => 'index'  
  
  
  # Blog routes
  map.blog                '/blog',                      :controller => 'blog_posts',    :action => 'index'
  map.blog_comments_new   '/blog_comments_new',         :controller => 'blog_comments', :action => 'recent_comments'
  
  
  # Routes for Ziya graphs
  map.load_progress       '/chart/load_progress/:user', :controller => 'chart',       :action => 'load_progress'
  map.load_memverse_clock '/chart/load_memverse_clock', :controller => 'chart',       :action => 'load_memverse_clock'
  
  # Home Page
  map.root :controller => 'sessions', :action => 'new'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
