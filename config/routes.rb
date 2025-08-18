MemverseApp::Application.routes.draw do
  
  # Background jobs
  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  mount Thredded::Engine      => '/forum'
  mount Bloggity::Engine, :at => '/blog'
  mount RailsAdmin::Engine    => '/admin', :as => 'rails_admin'
  mount Ckeditor::Engine      => '/ckeditor'
  mount JasmineRails::Engine  => '/specs' if defined?(JasmineRails)

  # Allow Admin users to monitor Sidekiq - used for quiz schedule
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    get '/volunteers' => 'volunteer#index', as: 'volunteers'
    
    # Sidekiq health monitoring routes
    namespace :admin do
      get 'sidekiq_health/dashboard', to: 'sidekiq_health#dashboard', as: 'sidekiq_health_dashboard'
      get 'sidekiq_health/health_check', to: 'sidekiq_health#health_check', as: 'sidekiq_health_check'
      get 'sidekiq_health/metrics', to: 'sidekiq_health#metrics', as: 'sidekiq_health_metrics'
      post 'sidekiq_health/clear_failed_jobs', to: 'sidekiq_health#clear_failed_jobs', as: 'sidekiq_clear_failed_jobs'
      post 'sidekiq_health/retry_failed_jobs', to: 'sidekiq_health#retry_failed_jobs', as: 'sidekiq_retry_failed_jobs'
      post 'sidekiq_health/toggle_queue/:queue_name/:action_type', to: 'sidekiq_health#toggle_queue', as: 'sidekiq_toggle_queue'
    end
  end

  # Routes for A/B testing
  # match "/split" => Split::Dashboard, via: [:get, :post, :delete], :anchor => false, :constraints => lambda { |request|
  #   request.env['warden'].authenticated?    # are we authenticated?
  #   request.env['warden'].authenticate!     # authenticate if not already
  #   request.env['warden'].user.try(:admin?) # check if admin
  # }

  # Oauth
  devise_for :users, :controllers => { 
    :omniauth_callbacks => "omniauth_callbacks",
    :confirmations => "users/confirmations"
  }

  # Should be able to remove this route once Forem allows configurable sign_in path
  get '/users/sign_in', :to => "devise/sessions#new", :as => "sign_in"

  # Primary resource routes
  resources :users, :only => :show
  resources :american_state, :only => :show
  resources :country, :only => :show
  resources :groups
  resources :uberverses
  resources :sermons
  resources :quests
  resources :quizzes do
    get 'search', on: :collection
  end
  resources :verses

  resources :quiz_questions do
    collection do
      get 'search'
      get 'bible_bee'
      get 'nationals' => 'quiz_questions#bible_bee', nationals: true
    end
  end

  get 'submit_question'        => "quiz_questions#submit",    as: :submit_question         # for users to submit quiz questions
  get 'quiz_question_approval' => 'quiz_questions#approvals', as: :quiz_question_approval  # for admins to approve quiz questions

  resources :passages do
    get 'due', :on => :collection
    resources :memverses
  end

  # Use a different home page for authenticated users
  authenticated :user do
    root to: "memverses#home", as: :authenticated_root
  end

  unauthenticated do
    root to: "home#index"
  end

  # ---------------------------------------------------------------------------------------------------------
  # API
  # ---------------------------------------------------------------------------------------------------------
  
  # To version we would do this instead
  # scope '1' do
  #   use_doorkeeper
  # end
  use_doorkeeper                        # Authentication for API
  
  resources :apidocs, only: [:index]    # for Swagger UI documentation

  # API v1 routes (converted from rocket_pants to Rails namespace)
  namespace :api do
    namespace :v1 do
      resources :users, :only => [:show, :update, :create, :destroy]
      resources :verses do
        get 'lookup', :on => :collection
        get 'chapter', :on => :collection
        get 'search', :on => :collection
      end
      resources :memverses
      resources :passages do
        get 'due', :on => :collection
        resources :memverses
      end
      resources :quizzes do
        get 'upcoming', :on => :collection
      end
      resources :translations, :only => [:index, :show]
      resources :final_verses, :only => [:index]
      resources :progress_reports, :only => [:index]

      get '/me'            => "credentials#me"
      post '/record_score' => 'live_quiz#record_score'
    end
  end
  # ---------------------------------------------------------------------------------------------------------
  # END: API
  # ---------------------------------------------------------------------------------------------------------


  # Adding verses and chapters to user account
  get   '/add_verse'              => 'memverses#add_verse',             :as => 'add_verse'
  post  '/add_chapter'            => 'memverses#add_chapter',           :as => 'add_chapter'
  match '/add/:id'                => 'memverses#ajax_add',              :as => 'add', :via => [:get, :post]
  get   '/avail_translations'     => 'memverses#avail_translations',    :as => 'avail_translations'

  # Core Review Pages
  get '/learn'                    => 'memverses#learn',                 :as => 'learn'
  get '/review'                   => 'passages#review',                 :as => 'passage_review'
  
  # AJAX endpoints
  get '/memverses/memverse_counter' => 'memverses#memverse_counter',    :as => 'memverse_counter'

  # Current single verse test
  get '/test_verse_quick'         => 'memverses#test_verse_quick',      :as => 'test_verse_quick'
  get '/test_next_verse'          => 'memverses#test_next_verse',       :as => 'test_next_verse'
  get '/mark_test_quick'          => 'memverses#mark_test_quick',       :as => 'mark_test_quick'
  get '/upcoming_verses'          => 'memverses#upcoming_verses',       :as => 'upcoming_verses'

  # Reference tests
  get  '/test_ref'                => 'memverses#test_ref',              :as => 'test_ref'
  get  '/test_next_ref'           => 'memverses#test_next_ref',         :as => 'test_next_ref'
  post '/score_ref/:mv/:score'    => 'memverses#score_ref_test'
  post '/save_ref_grade/:score'   => 'users#update_ref_grade'

  # Accuracy test
  get '/test_accuracy'            => 'memverses#test_accuracy',         :as => 'test_accuracy'
  get '/accuracy_test_next'       => 'memverses#accuracy_test_next'
  post '/save_accuracy/:score'    => 'users#update_accuracy'

  # Chapter review
  get '/pre_chapter'              => 'memverses#chapter_explanation',   :as => 'pre_chapter'
  get '/test_chapter'             => 'memverses#test_chapter',          :as => 'test_chapter'

  # Legacy drill page
  get '/drill_verse'              => 'memverses#drill_verse',           :as => 'drill_verse'
  post '/mark_drill'              => 'memverses#mark_drill',            :as => 'mark_drill'

  # Verse management
  get '/manage_verses'            => 'memverses#manage_verses',         :as => 'manage_verses'
  get '/show_all_my_verses'       => 'memverses#manage_verses'        # :as => 'manage_verses'
  post '/delete_memverses'        => 'memverses#delete_verses'
  post '/show_prompt'             => 'memverses#show_prompt',           :as => 'show_prompt'
  post '/handle_verse_action'     => 'memverses#handle_verse_action',   :as => 'handle_verse_action'
  get '/reset_schedule'           => 'users#reset_schedule',            :as => 'reset_schedule'

  get '/progress'                 => 'memverses#show_progress',         :as => 'progress'
  get '/save_progress_report'     => 'memverses#save_progress_report',  :as => 'save_progress_report'
  get '/popular_verses'           => 'memverses#pop_verses',            :as => 'popular_verses'
  get '/home'                     => 'memverses#index',                 :as => 'index'
  get '/memory_verse/:id'         => 'memverses#show',                  :as => 'memory_verse'
  get '/toggle_error_flag/:id'    => 'verses#toggle_flag',              :as => 'toggle_error_flag'
  get '/toggle_mv_status/:id'     => 'memverses#toggle_mv_status',      :as => 'toggle_mv_status'

  # Tagging verses
  post '/add_tag'                 => 'memverses#add_mv_tag'
  post '/remove_verse_tag'        => 'memverses#remove_verse_tag'
  get  '/tag_autocomplete'        => 'memverses#tag_autocomplete'

  # Bible Reading
  get  '/read/:tl/:bk/:ch'        => 'reading#chapter'
  get  '/chapter'                 => 'reading#chapter'
  
  # Starter pack
  get  '/starter_pack/:translation' => 'memverses#starter_pack', :as => 'starter_pack'

  # Verse search
  get '/lookup_user_verse'        => 'memverses#mv_lookup',             :as => 'lookup_user_verse'
  get '/lookup_user_passage'      => 'memverses#mv_lookup_passage',     :as => 'lookup_user_passage'
  get '/mv_tag_search'            => 'memverses#mv_tag_search',         :as => 'mv_tag_search'

  get '/tag_cloud'                => 'verses#tag_cloud',                :as => 'tag_cloud'
  get '/check_verses'             => 'verses#check_verses',             :as => 'check_verses'
  get '/check_verse/:id'          => 'verses#check_verse',              :as => 'check_verse'
  get '/verify_vs_format'         => 'verses#verify_format',            :as => 'verify_vs_format'
  get '/show_verses_with_tag'     => 'verses#show_verses_with_tag',     :as => 'show_verses_with_tag'
  get '/search_verse'             => 'verses#verse_search',             :as => 'search_verse'
  get '/lookup_verse'             => 'verses#lookup',                   :as => 'lookup_verse'
  get '/lookup_passage'           => 'verses#lookup_passage',           :as => 'lookup_passage'
  get '/major_tl_lookup'          => 'verses#major_tl_lookup'
  get '/chapter_available'        => 'verses#chapter_available',        :as => 'chapter_available'

  get '/get_popverses'            => 'popverses#index',                 :as => 'get_popverses'

  get '/show_user_info'           => 'utils#show_user_info',            :as => 'show_user_info'
  get '/show_tags'                => 'utils#show_tags',                 :as => 'show_tags'
  get '/admin_search_verse'       => 'utils#search_verse',              :as => 'admin_search_verse'
  get '/utils_verify_verse/:id'   => 'utils#verify_verse',              :as => 'utils_verify_verse'
  get '/utils_dashboard'          => 'utils#dashboard',                 :as => 'utils_dashboard'
  get '/show_users'               => 'utils#show_users',                :as => 'show_users'
  get '/progression/(:yr)/(:mo)'  => 'utils#user_progression',          :as => 'progression'

  # Doesn't require a login
  get '/contact'                  => 'info#contact'
  get '/faq'                      => 'info#faq'
  get '/tutorial'                 => 'info#tutorial'
  # get '/video_tutorial' => 'info#video_tut'
  get '/volunteer'                => 'info#volunteer'
  get '/popular'                  => 'info#pop_verses'
  get '/supermemo'                => 'info#sm_description'
  get '/mission'                  => 'info#mission_statement'
  get '/demo'                     => 'info#demo_test_verse'
  get '/leaderboard'              => 'info#leaderboard'
  get '/churchboard'              => 'info#churchboard'
  get '/groupboard'               => 'info#groupboard'
  get '/stateboard'               => 'info#stateboard'
  get '/countryboard'             => 'info#countryboard'
  get '/memverse_clock'           => 'info#memverse_clock'
  get '/info/email_available'     => 'info#email_available'
  get '/referralboard'            => 'info#referralboard'
  get '/news'                     => 'info#news'
  get '/stt_setia'                => 'info#stt_setia'
  get '/bible_bee_tool'           => 'info#bible_bee_tool'
  get '/show_vs'                  => 'info#show_vs',                   :as => 'show_vs'

  get '/finish_experiment'        => 'experiment#finish'

  # Route for users who haven't yet joined a group
  get '/mygroup'                  => 'groups#show',                     :as => 'mygroup'

  get '/update_profile'           => 'profile#update_profile',          :as => 'update_profile'
  patch '/profile/update/:id'     => 'profile#update'
  get '/church'                   => 'profile#show_church',             :as => 'church'
  get '/referrals/:id'            => 'profile#referrals',               :as => 'referrals'
  get '/unsubscribe/*email'       => 'profile#unsubscribe',             :as => 'unsubscribe', :format => false
  get '/search_user'              => 'profile#search_user',             :as => 'search_user'
  get '/set_translation/:tl'      => 'profile#set_translation',         :as => 'set_translation'
  get '/set_time_alloc/:time'     => 'profile#set_time_alloc',          :as => 'set_time_alloc'
  
  # Referrer routes
  get '/set_referrer'             => 'profile#set_referrer',            :as => 'set_referrer'
  get '/set_as_referrer/:id'      => 'profile#set_as_referrer',        :as => 'set_as_referrer'

  # Autocomplete routes for profile
  get '/profile/country_autocomplete' => 'profile#country_autocomplete', :as => 'profile_country_autocomplete'
  get '/profile/state_autocomplete'   => 'profile#state_autocomplete',   :as => 'profile_state_autocomplete'
  get '/profile/church_autocomplete'  => 'profile#church_autocomplete',  :as => 'profile_church_autocomplete'
  get '/profile/group_autocomplete'   => 'profile#group_autocomplete',   :as => 'profile_group_autocomplete'

  get '/earned_badges/:id'        => 'badges#earned_badges',            :as => 'earned_badges'
  get '/badge_completion_check'   => 'badges#badge_completion_check',   :as => 'badge_completion_check'

  get '/badge_quests_check'       => 'quests#badge_quests_check',       :as => 'badge_quests_check'

  get '/edit_tag/:id'             => 'tag#edit_tag',                    :as => 'edit_tag'

  # Tweet routes
  get '/tweets'                   => 'tweets#index',                    :as => 'tweets'

  # Game routes
  get '/verse_scramble'           => 'games#verse_scramble',            :as => 'verse_scramble'

  # Routes for graphs
  get '/load_progress/'             => 'chart#load_progress',             :as => 'load_progress'
  get '/load_consistency_progress/' => 'chart#load_consistency_progress', :as => 'load_consistency_progress'
  get '/global_data'                => 'chart#global_data',               :as => 'global_data'

  # Routes for chat channels
  post '/chat/send'                 => 'chat#send_message'
  get  '/chat/toggle_ban'           => 'chat#toggle_ban'
  get  '/chat'                      => 'chat#index'

  # Routes for live quiz
  get  '/live_quiz'                 => 'live_quiz#live_quiz',             :as => 'live_quiz'     # Main quiz URL
  get  '/live_quiz/channel1'        => 'live_quiz#channel1'                                      # Chat channel
  get  '/live_quiz/scoreboard'      => 'live_quiz#scoreboard'                                    # Scoreboard for quiz
  get  '/live_quiz/:quiz'           => 'live_quiz#live_quiz'
  post '/record_score'              => 'live_quiz#record_score'

  # Routes for scribe
  get  '/scribe/search'            => 'scribe#search',       :as => 'scribe_search'
  get  '/scribe/search_verse'      => 'scribe#search_verse'
  post '/scribe/edit_verse'        => 'scribe#edit_verse'
  get  '/scribe'                   => 'scribe#index',        :as => 'scribe'
  get  '/scribe/:check'            => 'scribe#check',        :as => 'scribe_check'
  get  '/scribe/verify/:id'        => 'scribe#verify_verse', :as => 'scribe_verify'

  # Legacy routes for pages that no longer exist but have incoming links
  get '/starter_pack'               => 'memverses#home'     # Retired in 2012
  get '/memverses/starter_pack'     => 'memverses#home'     # Visit from search bot causing errors
  get '/chat/channel1'              => 'live_quiz#channel1' # Old chat route
  get '/forums/:messageboard/topics/:topic' => redirect('/forum/%{messageboard}/%{topic}')

  # ---------------------------------------------------------------------------------------------------------
  # Explicit routes for controllers previously using default routes
  # ---------------------------------------------------------------------------------------------------------
  
  # Pastors management
  resources :pastors do
    collection do
      get 'pastor_autocomplete'
    end
  end
  
  # Church routes
  get '/church/:id' => 'church#show', as: 'show_church'
  
  # Sermons management  
  resources :sermons
  
  # Uberverses routes
  resources :uberverses
  
  # Additional home controller routes
  get '/quick_start' => 'home#quick_start', as: 'quick_start'
  
  # Additional tag routes  
  patch '/tag/:id' => 'tag#update_tag', as: 'update_tag'
  delete '/tag/:id' => 'tag#destroy_tag', as: 'destroy_tag'
  
  # Additional chat routes
  post '/chat/toggle_channel' => 'chat#toggle_channel', as: 'toggle_channel'
  
  # Additional popverses routes (for tests)
  get '/popverses/show' => 'popverses#show', as: 'popverses_show' if Rails.env.test?

  # Default routes have been removed to comply with Rails 6.0
  # All controller actions must now have explicit routes defined above
  # This improves security by preventing access to unmapped controller actions

end
