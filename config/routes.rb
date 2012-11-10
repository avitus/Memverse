MemverseApp::Application.routes.draw do
  
  mount Forem::Engine,    :at => '/forums'
  mount Bloggity::Engine, :at => '/blog'
  mount RailsAdmin::Engine    => '/admin', :as => 'rails_admin'
  mount Ckeditor::Engine      => '/ckeditor'

  match '/split' => Split::Dashboard, :anchor => false, :constraints => lambda { |request|
    request.env['warden'].authenticated?    # are we authenticated?
    request.env['warden'].authenticate!     # authenticate if not already
    request.env['warden'].user.try(:admin?) # check if admin
  }

  devise_for :users
  
  # Should be able to remove this route once Forem allows configurable sign_in path
  match '/users/sign_in', :to => "devise/sessions#new", :as => "sign_in"
  
  resources :blog_categories
  resources :users, :only => :show
  resources :groups
  resources :uberverses
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
  match '/add_chapter',            :to => 'memverses#add_chapter',           :as => 'add_chapter'
  match '/add/:id',                :to => 'memverses#ajax_add',              :as => 'add'
  match '/quick_add/:vs',          :to => 'memverses#quick_add',             :as => 'quick_add'
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
  match '/learn',                  :to => 'memverses#learn',                 :as => 'learn'
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

  match '/lookup_user_verse',      :to => 'memverses#mv_lookup',             :as => 'lookup_user_verse'
  match '/lookup_user_passage',    :to => 'memverses#mv_lookup_passage',     :as => 'lookup_user_passage'
  match '/mv_search',              :to => 'memverses#mv_search',             :as => 'mv_search'
 
  match '/tag_cloud',              :to => 'verses#tag_cloud',                :as => 'tag_cloud'
  match '/check_verses',           :to => 'verses#check_verses',             :as => 'check_verses'
  match '/check_verse/:id',        :to => 'verses#check_verse',              :as => 'check_verse'
  match '/verify_vs_format',       :to => 'verses#verify_format',            :as => 'verify_vs_format'
  match '/show_verses_with_tag',   :to => 'verses#show_verses_with_tag',     :as => 'show_verses_with_tag'
  match '/search_verse',           :to => 'verses#verse_search',             :as => 'search_verse'
  match '/lookup_verse',           :to => 'verses#lookup',                   :as => 'lookup_verse'
  match '/lookup_passage',         :to => 'verses#lookup_passage',           :as => 'lookup_passage'
  match '/chapter_available',      :to => 'verses#chapter_available',        :as => 'chapter_available'

  match '/get_popverses',          :to => 'popverses#index',                 :as => 'get_popverses'
      
  match '/show_user_info',         :to => 'utils#show_user_info',            :as => 'show_user_info'
  match '/show_tags',              :to => 'utils#show_tags',                 :as => 'show_tags'
  match '/admin_search_verse',     :to => 'utils#search_verse',              :as => 'admin_search_verse'
  match '/utils_verify_verse/:id', :to => 'utils#verify_verse',              :as => 'utils_verify_verse'
  match '/utils_dashboard',        :to => 'utils#dashboard',                 :as => 'utils_dashboard'
  match '/progression/(:yr)/(:mo)',:to => 'utils#user_progression',          :as => 'progression'
    
  # Doesn't require a login
  match '/contact'        => 'info#contact'
  match '/faq'            => 'info#faq'
  match '/tutorial'       => 'info#tutorial'
  # match '/video_tutorial' => 'info#video_tut'
  match '/volunteer'      => 'info#volunteer'
  match '/popular'        => 'info#pop_verses'
  match '/supermemo'      => 'info#sm_description'
  match '/mission'        => 'info#mission_statement'
  match '/demo'           => 'info#demo_test_verse'
  match '/leaderboard'    => 'info#leaderboard'
  match '/churchboard'    => 'info#churchboard'
  match '/groupboard'     => 'info#groupboard'
  match '/stateboard'     => 'info#stateboard'
  match '/countryboard'   => 'info#countryboard'
  match '/memverse_clock' => 'info#memverse_clock'
  match '/referralboard'  => 'info#referralboard'
  match '/news'           => 'info#news'
  match '/stt_setia'      => 'info#stt_setia'
  match '/bible_bee_tool' => 'info#bible_bee_tool'

  match '/signup_button_test_finished' => 'info#signup_button_finished'

  # Route for users who haven't yet joined a group
  match '/mygroup',                :to => 'groups#show',                     :as => 'mygroup'
 
  match '/update_profile',         :to => 'profile#update_profile',          :as => 'update_profile'
  match '/church',                 :to => 'profile#show_church',             :as => 'church'
  match '/referrals/:id',          :to => 'profile#referrals',               :as => 'referrals'
  match '/unsubscribe/*email',     :to => 'profile#unsubscribe',             :as => 'unsubscribe', :format => false
  match '/search_user',            :to => 'profile#search_user',             :as => 'search_user'
  match '/set_translation/:tl',    :to => 'profile#set_translation',         :as => 'set_translation'
  match '/set_time_alloc/:time',   :to => 'profile#set_time_alloc',          :as => 'set_time_alloc'

  match '/earned_badges/:id',      :to => 'badges#earned_badges',            :as => 'earned_badges'     
  match '/badge_completion_check', :to => 'badges#badge_completion_check',   :as => 'badge_completion_check'
 
  match '/badge_quests_check',     :to => 'quests#badge_quests_check',       :as => 'badge_quests_check' 
  
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
  match "/chat/send",              :controller => "chat", :action => "send_message"
  match "/chat/channel1",          :controller => "chat", :action => "channel1"
  match "/chat/channel2",          :controller => "chat", :action => "channel2"  

  
  # Routes for live quiz
  match "/live_quiz/start_quiz",  :controller => "live_quiz", :action => "start_quiz"
  match "/live_quiz",             :controller => "live_quiz", :action => "live_quiz"
  match "/live_quiz/channel1",    :controller => "live_quiz", :action => "channel1"
  match "/live_quiz/scoreboard",  :controller => "live_quiz", :action => "scoreboard"
  match "/record_score",          :controller => "live_quiz", :action => "record_score"

  # Install the default routes as the lowest priority. 
  match '/:controller(/:action(/:id))'

end
