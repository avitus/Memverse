MemverseApp::Application.routes.draw do
  
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  # match '/login',                       :to => 'home#index',        :as => 'login'
  # match '/logout',                      :to => 'sessions#destroy',  :as => 'logout'
  # match '/register',                    :to => 'users#create',      :as => 'register'
  # match '/signup',                      :to => 'users#new',         :as => 'signup'
  # match '/activate/:activation_code',   :to => 'users#activate',    :as => 'activate',  :activation_code => nil
  # match '/forgot_password',             :to => 'passwords#new',     :as => 'forgot_password'
  # match '/change_password/:reset_code', :to => 'passwords#reset',   :as => 'change_password'

  devise_for :users

  resources :users, :only => :show
#  resources :passwords
#  resource  :session
  resources :uberverses
# resources :pastors
  resources :sermons
  resources :quests
  resources :quizzes
  resources :quizquestions
  resources :verses
# resources :memverses

  authenticated do
    root      :to => 'memverses#index'
  end  
  root        :to => 'home#index' 

  # Memverse Mappings
  match '/reset_schedule',         :to => 'users#reset_schedule',            :as => 'reset_schedule'
  
  match '/add_verse',              :to => 'memverses#add_verse',             :as => 'add_verse'
  match '/add/:id',                :to => 'memverses#ajax_add',              :as => 'add'
  match '/quick_add/:vs',          :to => 'memverses#quick_add',             :as => 'quick_add'
  match '/quick_add_chapter',      :to => 'memverses#quick_add_chapter',     :as => 'quick_add_chapter'
  match '/avail_translations',     :to => 'memverses#avail_translations',    :as => 'avail_translations'
  match '/edit_verse/:id',         :to => 'memverses#edit_verse',            :as => 'edit_verse'
  match '/test_verse',             :to => 'memverses#test_verse',            :as => 'test_verse'
  match '/feedback',               :to => 'memverses#feedback',              :as => 'feedback'
  match '/upcoming_verses',        :to => 'memverses#upcoming_verses',       :as => 'upcoming_verses'
  match '/test_verse_quick',       :to => 'memverses#test_verse_quick',      :as => 'test_verse_quick'
  match '/test_next_verse',        :to => 'memverses#test_next_verse',       :as => 'test_next_verse'
  match '/mark_test',              :to => 'memverses#mark_test',             :as => 'mark_test'
  match '/mark_test_quick',        :to => 'memverses#mark_test_quick',       :as => 'mark_test_quick'
  match '/test_ref',               :to => 'memverses#test_ref',              :as => 'test_ref'
  match '/reftest_results',        :to => 'memverses#reftest_results',       :as => 'reftest_results'
  match '/start_ref_test',         :to => 'memverses#load_test_ref',         :as => 'start_ref_test'
  match '/exam',                   :to => 'memverses#load_exam',             :as => 'exam'
  match '/test_exam',              :to => 'memverses#test_exam',             :as => 'test_exam'
  match '/exam_results',           :to => 'memverses#exam_results',          :as => 'exam_results'
  match '/pre_exam',               :to => 'memverses#explain_exam',          :as => 'pre_exam'
  match '/pre_chapter',            :to => 'memverses#chapter_explanation',   :as => 'pre_chapter'
  match '/test_chapter',           :to => 'memverses#test_chapter',          :as => 'test_chapter'
  match '/drill_verse',            :to => 'memverses#drill_verse',           :as => 'drill_verse'
  match '/mark_test',              :to => 'memverses#mark_test',             :as => 'mark_test'
  match '/mark_drill',             :to => 'memverses#mark_drill',            :as => 'mark_drill'
  match '/manage_verses',          :to => 'memverses#manage_verses',         :as => 'manage_verses'
  match '/show_all_my_verses',     :to => 'memverses#manage_verses',         :as => 'manage_verses'
  match '/user_stats',             :to => 'memverses#user_stats',            :as => 'user_stats'
  match '/progress',               :to => 'memverses#show_progress',         :as => 'progress'
  match '/save_progress_report',   :to => 'memverses#save_progress_report',  :as => 'save_progress_report'
  match '/popular_verses',         :to => 'memverses#pop_verses',            :as => 'popular_verses'
  match '/home',                   :to => 'memverses#index',                 :as => 'index'
  match '/starter_pack',           :to => 'memverses#starter_pack',          :as => 'starter_pack'
  match '/memory_verse/:id',       :to => 'memverses#show',                  :as => 'memory_verse'
  match '/toggle_error_flag/:id',  :to => 'memverses#toggle_verse_flag',     :as => 'toggle_error_flag'
  match '/toggle_mv_status/:id',   :to => 'memverses#toggle_mv_status',      :as => 'toggle_mv_status'
 
  match '/tag_cloud',              :to => 'verses#tag_cloud',                :as => 'tag_cloud'
  match '/check_verses',           :to => 'verses#check_verses',             :as => 'check_verses'
  match '/check_verse/:id',        :to => 'verses#check_verse',              :as => 'check_verse'
  match '/search_verse',           :to => 'verses#verse_search',             :as => 'search_verse'
  match '/verify_vs_format',       :to => 'verses#verify_format',            :as => 'verify_vs_format'
  match '/show_verses_with_tag',   :to => 'verses#show_verses_with_tag',     :as => 'show_verses_with_tag'
      
  match '/show_user_info',         :to => 'utils#show_user_info',            :as => 'show_user_info'
  match '/show_tags',              :to => 'utils#show_tags',                 :as => 'show_tags'
  match '/admin_search_verse',     :to => 'utils#search_verse',              :as => 'admin_search_verse'
  match '/utils_verify_verse/:id', :to => 'utils#verify_verse',              :as => 'utils_verify_verse'
  match '/utils_dashboard',        :to => 'utils#dashboard',                 :as => 'utils_dashboard'
  match '/progression/:yr/:mo',    :to => 'utils#user_progression',          :as => 'progression'
    
  # Doesn't require a login
  match '/contact',                :to => 'info#contact',                    :as => 'contact'   
  match '/faq',                    :to => 'info#faq',                        :as => 'faq'
  match '/tutorial',               :to => 'info#tutorial',                   :as => 'tutorial'
  # match '/video_tutorial',        :to => 'info#video_tut',                  :as => 'video_tut'
  match '/volunteer',              :to => 'info#volunteer',                  :as => 'volunteer'
  match '/popular',                :to => 'info#pop_verses',                 :as => 'popular'
  match '/supermemo',              :to => 'info#sm_description',             :as => 'supermemo'
  match '/mission',                :to => 'info#mission_statement',          :as => 'mission'
  match '/demo',                   :to => 'info#demo_test_verse',            :as => 'demo'
  match '/leaderboard',            :to => 'info#leaderboard',                :as => 'leaderboard'
  match '/churchboard',            :to => 'info#churchboard',                :as => 'churchboard'
  match '/groupboard',             :to => 'info#groupboard',                 :as => 'groupboard'
  match '/stateboard',             :to => 'info#stateboard',                 :as => 'stateboard'
  match '/countryboard',           :to => 'info#countryboard',               :as => 'countryboard'
  match '/memverse_clock',         :to => 'info#memverse_clock',             :as => 'memverse_clock'
  match '/referralboard',          :to => 'info#referralboard',              :as => 'referralboard'
  match '/news',                   :to => 'info#news',                       :as => 'news'
 
  match '/update_profile',         :to => 'profile#update_profile',          :as => 'update_profile'
  match '/church',                 :to => 'profile#show_church',             :as => 'church'
  match '/referrals/:id',          :to => 'profile#referrals',               :as => 'referrals'
  match '/unsubscribe/*email',     :to => 'profile#unsubscribe',             :as => 'unsubscribe', :format => false
  match '/search_user',            :to => 'profile#search_user',             :as => 'search_user'
  match '/set_translation/:id',    :to => 'profile#set_translation',         :as => 'set_translation'

  
  match '/edit_tag/:id',           :to => 'tag#edit_tag',                    :as => 'edit_tag'

  # Tweet routes
  match '/tweets',                 :to => 'tweets#index',                    :as => 'tweets'  

  # Game routes  
  match '/verse_scramble',         :to => 'games#verse_scramble',            :as => 'verse_scramble'  
  
  # Blog routes
  match '/blog',                   :to => 'blog_posts#index', :blog_url_id_or_id => 'main',  :as => 'blog'
  match '/blog_comments_new',      :to => 'blog_comments#recent_comments',                   :as => 'blog_comments_new'
  match '/blog_search',            :to => 'blog_posts#blog_search',                          :as => 'blog_search'
  
  # Routes for graphs
  match '/load_progress/',         :to => 'chart#load_progress',             :as => 'load_progress'
  match '/global_data',            :to => 'chart#global_data',               :as => 'global_data' 
  
  # Routes for chat channels  
  match "/chat/send",       :controller => "chat", :action => "send_message"
  match "/chat/channel1",   :controller => "chat", :action => "channel1"
  match "/chat/channel2",   :controller => "chat", :action => "channel2"  

  
  # Routes for live quiz
  match "/live_quiz/start_quiz",  :controller => "live_quiz", :action => "start_quiz"
  match "/live_quiz",             :controller => "live_quiz", :action => "live_quiz"
  match "/live_quiz/channel1",    :controller => "live_quiz", :action => "channel1"
  match "/live_quiz/scoreboard",  :controller => "live_quiz", :action => "scoreboard"
  match "/record_score",          :controller => "live_quiz", :action => "record_score"

  # Install the default routes as the lowest priority. 
  match '/:controller(/:action(/:id))'

end
