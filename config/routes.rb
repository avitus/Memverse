MemverseApp::Application.routes.draw do
  require 'sidekiq/web'

  mount Sidekiq::Web,     :at => '/sidekiq'
  mount Forem::Engine,    :at => '/forums'
  mount Bloggity::Engine, :at => '/blog'
  mount RailsAdmin::Engine    => '/admin', :as => 'rails_admin'
  mount Ckeditor::Engine      => '/ckeditor'

  get '/split' => Split::Dashboard, :anchor => false, :constraints => lambda { |request|
    request.env['warden'].authenticated?    # are we authenticated?
    request.env['warden'].authenticate!     # authenticate if not already
    request.env['warden'].user.try(:admin?) # check if admin
  }

  devise_for :users

  # Should be able to remove this route once Forem allows configurable sign_in path
  get '/users/sign_in', :to => "devise/sessions#new", :as => "sign_in"

  resources :users, :only => :show
  resources :groups
  resources :uberverses
  resources :sermons
  resources :quests
  resources :quizzes
  resources :quizquestions
  resources :verses

  resources :passages do
    get 'due', :on => :collection
    resources :memverses
  end

  # resources :memverses

  # Use a different home page for authenticated users
  authenticated :user do
    root to: "memverses#home", as: :authenticated_root
  end

  unauthenticated do
    root to: "home#index"
  end

  # Core Review Pages
  get '/review' => 'passages#review', :as => 'passage_review'

  # Memverse Mappings
  get '/reset_schedule',         :to => 'users#reset_schedule',            :as => 'reset_schedule'

  get '/add_verse',              :to => 'memverses#add_verse',             :as => 'add_verse'
  get '/add_chapter',            :to => 'memverses#add_chapter',           :as => 'add_chapter'
  get '/add/:id',                :to => 'memverses#ajax_add',              :as => 'add'
  get '/quick_add/:vs',          :to => 'memverses#quick_add',             :as => 'quick_add'
  get '/avail_translations',     :to => 'memverses#avail_translations',    :as => 'avail_translations'
  # get '/edit_verse/:id',         :to => 'memverses#edit_verse',            :as => 'edit_verse'  <--- duplicate route ... need to rename
  get '/test_verse',             :to => 'memverses#test_verse',            :as => 'test_verse'
  get '/feedback',               :to => 'memverses#feedback',              :as => 'feedback'
  get '/upcoming_verses',        :to => 'memverses#upcoming_verses',       :as => 'upcoming_verses'
  get '/test_verse_quick',       :to => 'memverses#test_verse_quick',      :as => 'test_verse_quick'
  get '/test_next_verse',        :to => 'memverses#test_next_verse',       :as => 'test_next_verse'
  get '/mark_test',              :to => 'memverses#mark_test',             :as => 'mark_test'
  get '/mark_test_quick',        :to => 'memverses#mark_test_quick',       :as => 'mark_test_quick'
  get '/test_ref',               :to => 'memverses#test_ref',              :as => 'test_ref'
  get '/reftest_results',        :to => 'memverses#reftest_results',       :as => 'reftest_results'
  get '/start_ref_test',         :to => 'memverses#load_test_ref',         :as => 'start_ref_test'
  get '/exam',                   :to => 'memverses#load_exam',             :as => 'exam'
  get '/test_exam',              :to => 'memverses#test_exam',             :as => 'test_exam'
  get '/exam_results',           :to => 'memverses#exam_results',          :as => 'exam_results'
  get '/pre_exam',               :to => 'memverses#explain_exam',          :as => 'pre_exam'
  get '/pre_chapter',            :to => 'memverses#chapter_explanation',   :as => 'pre_chapter'
  get '/test_chapter',           :to => 'memverses#test_chapter',          :as => 'test_chapter'
  get '/drill_verse',            :to => 'memverses#drill_verse',           :as => 'drill_verse'
  get '/learn',                  :to => 'memverses#learn',                 :as => 'learn'
  get '/mark_drill',             :to => 'memverses#mark_drill',            :as => 'mark_drill'
  get '/manage_verses',          :to => 'memverses#manage_verses',         :as => 'manage_verses'
  get '/show_all_my_verses',     :to => 'memverses#manage_verses'        # :as => 'manage_verses'
  get '/user_stats',             :to => 'memverses#user_stats',            :as => 'user_stats'
  get '/progress',               :to => 'memverses#show_progress',         :as => 'progress'
  get '/save_progress_report',   :to => 'memverses#save_progress_report',  :as => 'save_progress_report'
  get '/popular_verses',         :to => 'memverses#pop_verses',            :as => 'popular_verses'
  get '/home',                   :to => 'memverses#index',                 :as => 'index'
  get '/starter_pack',           :to => 'memverses#starter_pack',          :as => 'starter_pack'
  get '/memory_verse/:id',       :to => 'memverses#show',                  :as => 'memory_verse'
  get '/toggle_error_flag/:id',  :to => 'memverses#toggle_verse_flag',     :as => 'toggle_error_flag'
  get '/toggle_mv_status/:id',   :to => 'memverses#toggle_mv_status',      :as => 'toggle_mv_status'

  get '/lookup_user_verse',      :to => 'memverses#mv_lookup',             :as => 'lookup_user_verse'
  get '/lookup_user_passage',    :to => 'memverses#mv_lookup_passage',     :as => 'lookup_user_passage'
  get '/mv_search',              :to => 'memverses#mv_search',             :as => 'mv_search'

  get '/tag_cloud',              :to => 'verses#tag_cloud',                :as => 'tag_cloud'
  get '/check_verses',           :to => 'verses#check_verses',             :as => 'check_verses'
  get '/check_verse/:id',        :to => 'verses#check_verse',              :as => 'check_verse'
  get '/verify_vs_format',       :to => 'verses#verify_format',            :as => 'verify_vs_format'
  get '/show_verses_with_tag',   :to => 'verses#show_verses_with_tag',     :as => 'show_verses_with_tag'
  get '/search_verse',           :to => 'verses#verse_search',             :as => 'search_verse'
  get '/lookup_verse',           :to => 'verses#lookup',                   :as => 'lookup_verse'
  get '/lookup_passage',         :to => 'verses#lookup_passage',           :as => 'lookup_passage'
  get '/chapter_available',      :to => 'verses#chapter_available',        :as => 'chapter_available'

  get '/get_popverses',          :to => 'popverses#index',                 :as => 'get_popverses'

  get '/show_user_info',         :to => 'utils#show_user_info',            :as => 'show_user_info'
  get '/show_tags',              :to => 'utils#show_tags',                 :as => 'show_tags'
  get '/admin_search_verse',     :to => 'utils#search_verse',              :as => 'admin_search_verse'
  get '/utils_verify_verse/:id', :to => 'utils#verify_verse',              :as => 'utils_verify_verse'
  get '/utils_dashboard',        :to => 'utils#dashboard',                 :as => 'utils_dashboard'
  get '/progression/(:yr)/(:mo)',:to => 'utils#user_progression',          :as => 'progression'

  # Doesn't require a login
  get '/contact'        => 'info#contact'
  get '/faq'            => 'info#faq'
  get '/tutorial'       => 'info#tutorial'
  # get '/video_tutorial' => 'info#video_tut'
  get '/volunteer'      => 'info#volunteer'
  get '/popular'        => 'info#pop_verses'
  get '/supermemo'      => 'info#sm_description'
  get '/mission'        => 'info#mission_statement'
  get '/demo'           => 'info#demo_test_verse'
  get '/leaderboard'    => 'info#leaderboard'
  get '/churchboard'    => 'info#churchboard'
  get '/groupboard'     => 'info#groupboard'
  get '/stateboard'     => 'info#stateboard'
  get '/countryboard'   => 'info#countryboard'
  get '/memverse_clock' => 'info#memverse_clock'
  get '/referralboard'  => 'info#referralboard'
  get '/news'           => 'info#news'
  get '/stt_setia'      => 'info#stt_setia'
  get '/bible_bee_tool' => 'info#bible_bee_tool'

  get '/signup_button_finished' => 'info#signup_button_finished'

  # Route for users who haven't yet joined a group
  get '/mygroup',                :to => 'groups#show',                     :as => 'mygroup'

  get '/update_profile',         :to => 'profile#update_profile',          :as => 'update_profile'
  get '/church',                 :to => 'profile#show_church',             :as => 'church'
  get '/referrals/:id',          :to => 'profile#referrals',               :as => 'referrals'
  get '/unsubscribe/*email',     :to => 'profile#unsubscribe',             :as => 'unsubscribe', :format => false
  get '/search_user',            :to => 'profile#search_user',             :as => 'search_user'
  get '/set_translation/:tl',    :to => 'profile#set_translation',         :as => 'set_translation'
  get '/set_time_alloc/:time',   :to => 'profile#set_time_alloc',          :as => 'set_time_alloc'

  get '/earned_badges/:id',      :to => 'badges#earned_badges',            :as => 'earned_badges'
  get '/badge_completion_check', :to => 'badges#badge_completion_check',   :as => 'badge_completion_check'

  get '/badge_quests_check',     :to => 'quests#badge_quests_check',       :as => 'badge_quests_check'

  get '/edit_tag/:id',           :to => 'tag#edit_tag',                    :as => 'edit_tag'

  # Tweet routes
  get '/tweets',                 :to => 'tweets#index',                    :as => 'tweets'

  # Game routes
  get '/verse_scramble',         :to => 'games#verse_scramble',            :as => 'verse_scramble'

  # Routes for graphs
  get '/load_progress/',         :to => 'chart#load_progress',             :as => 'load_progress'
  get '/load_consistency_progress/', :to => 'chart#load_consistency_progress', :as => 'load_consistency_progress'
  get '/global_data',            :to => 'chart#global_data',               :as => 'global_data'

  # Routes for chat channels
  get "/chat/send",              :controller => "chat", :action => "send_message"
  get "/chat/channel1",          :controller => "chat", :action => "channel1"
  get "/chat/channel2",          :controller => "chat", :action => "channel2"
  get "/chat/toggle_ban",        :controller => "chat", :action => "toggle_ban"


  # Routes for live quiz
  get "/live_quiz/start_quiz",  :controller => "live_quiz", :action => "start_quiz"
  get "/live_quiz",             :controller => "live_quiz", :action => "live_quiz"
  get "/live_quiz/channel1",    :controller => "live_quiz", :action => "channel1"
  get "/live_quiz/scoreboard",  :controller => "live_quiz", :action => "scoreboard"
  get "/record_score",          :controller => "live_quiz", :action => "record_score"

  # Install the default routes as the lowest priority.
  get '/:controller(/:action(/:id))'

end
