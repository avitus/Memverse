require 'factory_bot'
require 'faker'

FactoryBot.define do

  # ==============================================================================================
  # Users
  # ==============================================================================================
  factory :user do
    name { Faker::Name.unique.name }
    email { Faker::Internet.unique.email }
    password { 'please' }
    password_confirmation { 'please' }
    last_activity_date { Date.today }
    admin { false }
    referred_by { 0 }
    translation { nil }

    trait :approved do
      after(:create) do |user, _|
        user.thredded_user_detail.update!(moderation_state: :approved)
      end
    end

    # Admin user
    # factory :admin do
    #   u.admin true
    # end

  end

  # ==============================================================================================
  # Roles
  # ==============================================================================================
  factory :role do |r|
    r.sequence(:name) { |n| "Role #{n}" }
  end

  # ==============================================================================================
  # Verses
  # ==============================================================================================
  factory :verse do
    translation { 'NIV' }
    book_index { 48 }
    book { 'Galatians' }
    chapter { 5 }
    versenum { 22 }
    text { 'But the fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness,' }

    # This ugliness is required to skip the validate_ref callback since the FinalVerse records are often not available during testing
    # For details see: http://stackoverflow.com/questions/8751175/skip-callbacks-on-factory-girl-and-rspec
    # after(:build) { |verse| verse.class.skip_callback(:create, :before, :validate_ref, raise: false) }

    # # Use this factory for testing out of bound verses
    # # TODO: these tests are not yet passing ... not sure how this works
    # factory :verse_with_validate_ref do
    #   after(:build) { |verse| verse.class.set_callback(:create, :before, :validate_ref) }
    # end

  end

  # ==============================================================================================
  # Passages
  # ==============================================================================================
  factory :passage do
    association :user, factory: :user
    translation { 'NIV' }
    length { 9 }
    book { 'Proverbs' }
    chapter { 3 }
    first_verse { 2 }
    last_verse { 10 }

    after(:create) do |psg, evaluator|
      for i in evaluator.first_verse..evaluator.last_verse
        vs = FactoryBot.create(:verse, book: evaluator.book, chapter: evaluator.chapter, versenum: i, translation: evaluator.translation)
        FactoryBot.create(:memverse_without_passage, user: evaluator.user, verse: vs, passage: psg, test_interval: i, rep_n: i)
      end
    end
  end

  # ==============================================================================================
  # Memverses
  # ==============================================================================================
  factory :memverse do
    association :verse, factory: :verse
    association :user, factory: :user
    status { 'Learning' }
    last_tested { Date.today }
    next_test { Date.today }
    efactor { 2.0 }
    rep_n { 1 }
    test_interval { 1 }
    ref_interval { 6 }
    next_ref_test { Date.today }

    after(:build) { |memverse| memverse.class.set_callback(:create, :after, :add_to_passage) }

    factory :memverse_without_passage do
      after(:build) { |memverse| memverse.class.skip_callback(:create, :after, :add_to_passage) }
    end

    factory :memverse_without_supermemo_init do
      after(:build) { |memverse| memverse.class.skip_callback(:create, :before, :supermemo_init, raise: false) }
    end
  end

  # ==============================================================================================
  # Blog
  # ==============================================================================================
  factory :blog do
    id { 1 }
    title { 'Memverse Blog' }
  end

  factory :blog_post do |f|
    f.association :posted_by_id, :factory => :user
  end

  factory :blog_comment do
    association :blog_post, factory: :blog_post
    association :user, factory: :user
    comment { 'Nice blog post!' }
  end

  # ==============================================================================================
  # Final Verse
  # ==============================================================================================
  factory :final_verse do
    book { 'Genesis' }
    chapter { 1 }
    last_verse { 31 }
  end

  # ==============================================================================================
  # Badges
  # ==============================================================================================
  factory :badge do
    name { 'Sermon on the Mount' }
    description { 'Memorize the Sermon on the Mount' }
    color { 'solo' }
  end

  # ==============================================================================================
  # Quests
  # ==============================================================================================
  factory :quest do
    task { 'Memorize Matthew 5' }
    objective { 'Chapters' }
    qualifier { 'Matthew 5' }
    quantity { nil }
    description { nil }
    level { 1 }
    url { nil }
    association :badge, factory: :badge
  end

  # ==============================================================================================
  # Progress Reports
  # ==============================================================================================
  factory :progress_report do
    association :user, factory: :user
    learning { 50 }
    memorized { 100 }
    entry_date { Date.today }
  end

  # ==============================================================================================
  # Groups
  # ==============================================================================================
  factory :group do
    name { 'Memory Group' }
    association :leader, factory: :user
  end

  # ==============================================================================================
  # Quiz
  # ==============================================================================================
  factory :quiz do
    association :user, factory: :user
    name { 'Weekly Bible Knowledge' }
  end

  # ==============================================================================================
  # Quiz Questions
  # ==============================================================================================
  factory :quiz_question do
    association :quiz, factory: :quiz
    times_answered { 10 }
    perc_correct { 50 }
    question_type { "reference" }
    mc_question { nil }
    mc_option_a { nil }
    mc_option_b { nil }
    mc_option_c { nil }
    mc_option_d { nil }
    mc_answer { nil }
    association :supporting_ref, factory: :uberverse
  end

  # ==============================================================================================
  # Uberverses
  # ==============================================================================================
  factory :uberverse do
    book { 'Genesis' }
    chapter { 1 }
    versenum { 1 }
    book_index { 1 }
    subsection_end { 0 }
  end

  # ==============================================================================================
  # Used to seed Thredded Forum
  # ==============================================================================================
  sequence(:topic_hash) { |n| "hash#{n}" }

  factory :messageboard do
    name { 'General Discussion' }
    description { 'This is a description of the messageboard' }
  end

  factory :post do
    ip { '127.0.0.1' }
    # ... add other attributes here as needed ...
  end

  factory :private_post do
    ip { '127.0.0.1' }
    # ... add other attributes here as needed ...
  end

  factory :private_topic, class: Thredded::PrivateTopic do
    user
    users { build_list :user, 1 }
    association :last_user, factory: :user

    title { Faker::Lorem.sentence[0..-2] }
    hash_id { generate(:topic_hash) }
  end

end
