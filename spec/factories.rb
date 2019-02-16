require 'factory_bot'
require 'faker'

FactoryBot.define do

  # ==============================================================================================
  # Users
  # ==============================================================================================
  factory :user do |u|

    u.name  { Faker::Name.unique.name }
    u.email { Faker::Internet.unique.email }

    # u.name 'Test User'
	  # u.sequence(:email) { |n| "user#{n}@test.com" }
    
    u.password 'please'
    u.password_confirmation { |u| u.password }
    u.last_activity_date Date.today
    u.admin false
    u.referred_by 0
    u.translation nil

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
  factory :verse do |verse|
    verse.translation 'NIV'
    verse.book_index 48
    verse.book 'Galatians'
    verse.chapter 5
    verse.versenum 22
    verse.text 'But the fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness,'

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

    association :user,  :factory => :user
    translation 'NIV'
    length      9
    book        'Proverbs'
    chapter     3
    first_verse 2
    last_verse  10

    # Create the necessary memverses and verses for the passage
    # Note: 'evaluator' stores all values from the 'passage' factory_girl
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
    # association :passage, :factory => :passage # this causes problems with infinite recursion
    association     :verse,   :factory => :verse
    association     :user,    :factory => :user
    status          'Learning'
    last_tested     Date.today
    next_test       Date.today
    efactor         2.0
    rep_n           1
    test_interval   1
    ref_interval    6
    next_ref_test   Date.today

    # We need to add the callback back to the Memverse class because it is removed from the class by
    # the :memverse_without_passage callback. See link below for details
    # http://stackoverflow.com/questions/11409734/why-does-my-FactoryBot-callback-run-when-it-shouldnt
    after(:build) {|memverse| memverse.class.set_callback(:create, :after, :add_to_passage)}

    # This factory is used by the Passage model to avoid a duplicate passage being created
    factory :memverse_without_passage do
      after(:build) { |memverse| memverse.class.skip_callback(:create, :after, :add_to_passage) }
    end

    # This factory allows creation of memory verses with a different efactor
    factory :memverse_without_supermemo_init do
      after(:build) { |memverse| memverse.class.skip_callback(:create, :before, :supermemo_init, raise: false) }
    end

  end

  # ==============================================================================================
  # Blog
  # ==============================================================================================
  factory :blog do |f|
    f.id 1
    f.title 'Memverse Blog'
  end

  factory :blog_post do |f|
    f.association :posted_by_id, :factory => :user
  end

  factory :blog_comment do |bc|
    bc.association :blog_post, :factory => :blog_post
  	bc.association :user,      :factory => :user
  	bc.comment 'Nice blog post!'
  end

  # ==============================================================================================
  # Final Verse
  # ==============================================================================================
  factory :final_verse do |f|
    f.book 'Genesis'
    f.chapter 1
    f.last_verse 31
  end

  # ==============================================================================================
  # Badges
  # ==============================================================================================
  factory :badge do |b|
    b.name 'Sermon on the Mount'
    b.description 'Memorize the Sermon on the Mount'
    b.color 'solo'
  end

  # ==============================================================================================
  # Quests
  # ==============================================================================================
  factory :quest do |q|
    q.task 'Memorize Matthew 5'
    q.objective 'Chapters'
    q.qualifier 'Matthew 5'
    q.quantity nil
    q.description nil
    q.level 1
    q.url nil
    q.association :badge, :factory => :badge
  end

  # ==============================================================================================
  # Progress Reports
  # ==============================================================================================
  factory :progress_report do |pr|
    pr.association :user, :factory => :user
    pr.learning   50
    pr.memorized 100
    pr.entry_date Date.today
  end

  # ==============================================================================================
  # Groups
  # ==============================================================================================
  factory :group do |g|
    g.name 'Memory Group'
    g.association :leader, :factory => :user
  end

  # ==============================================================================================
  # Quiz
  # ==============================================================================================
  factory :quiz do |q|
    q.association :user, :factory => :user
    q.name    'Weekly Bible Knowledge'
  end

  # ==============================================================================================
  # Quiz Questions
  # ==============================================================================================
  factory :quiz_question do |qq|
    qq.association :quiz, :factory => :quiz
    qq.times_answered  10
    qq.perc_correct    50
    qq.question_type   "reference"
    qq.mc_question     nil
    qq.mc_option_a     nil
    qq.mc_option_b     nil
    qq.mc_option_c     nil
    qq.mc_option_d     nil
    qq.mc_answer       nil
    qq.association :supporting_ref, :factory => :uberverse
  end

  # ==============================================================================================
  # Uberverses
  # ==============================================================================================
  factory :uberverse do
    book "Genesis"
    chapter 1
    versenum 1
    book_index 1
    subsection_end 31
  end

  # ==============================================================================================
  # Used to seed Thredded Forum
  # ==============================================================================================
  sequence(:topic_hash) { |n| "hash#{n}" }

  factory :messageboard, class: Thredded::Messageboard do
    sequence(:name) { |n| "messageboard#{n}" }
    description 'This is a description of the messageboard'
    # closed false
  end

  factory :post, class: Thredded::Post do
    user
    postable { association :topic, user: user }
    messageboard

    content { Faker::Hacker.say_something_smart }
    ip '127.0.0.1'
  end

  factory :private_post, class: Thredded::PrivatePost do
    user
    postable { association :private_topic, user: user }

    content { Faker::Hacker.say_something_smart }
    ip '127.0.0.1'
  end

  factory :topic, class: Thredded::Topic do
    transient do
      with_posts 0
      with_categories 0
    end

    title { Faker::StarWars.quote }
    hash_id { generate(:topic_hash) }

    user
    messageboard
    association :last_user, factory: :user

    after(:create) do |topic, evaluator|
      if evaluator.with_posts
        evaluator.with_posts.times do
          create(:post, postable: topic, user: topic.user, messageboard: topic.messageboard)
        end

        topic.posts_count = evaluator.with_posts
        topic.save
      end

      evaluator.with_categories.times do
        topic.categories << create(:category)
      end
    end

    trait :locked do
      locked true
    end

    trait :pinned do
      sticky true
    end

    trait :sticky do
      sticky true
    end
  end

  factory :private_topic, class: Thredded::PrivateTopic do
    user
    users { build_list :user, 1 }
    association :last_user, factory: :user

    title { Faker::Lorem.sentence[0..-2] }
    hash_id { generate(:topic_hash) }
  end

end
