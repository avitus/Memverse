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
    confirmed_at { Time.now }  # Auto-confirm users for testing

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
  sequence :verse_sequence do |n|
    n
  end

  factory :verse do
    translation { 'NIV' }
    book_index { 19 }
    book { 'Psalms' }
    chapter { generate(:verse_sequence) }
    versenum { 1 }
    text { 'Praise the LORD, all you nations; extol him, all you peoples.' }

    # This ugliness is required to skip the validate_ref callback since the FinalVerse records are often not available during testing
    # For details see: http://stackoverflow.com/questions/8751175/skip-callbacks-on-factory-girl-and-rspec
    after(:build) { |verse| verse.define_singleton_method(:validate_ref) { true } }

    # # Use this factory for testing out of bound verses
    # # TODO: these tests are not yet passing ... not sure how this works
    # factory :verse_with_validate_ref do
    #   after(:build) { |verse| verse.class.set_callback(:create, :before, :validate_ref) }
    # end

    factory :verse2 do
      versenum { 2 }
      text { 'For great is his love toward us, and the faithfulness of the LORD endures forever. Praise the LORD.' }
    end

  end

  # ==============================================================================================
  # Passages
  # ==============================================================================================
  factory :passage do
    association :user, factory: :user
    translation { 'NIV' }
    length { 2 }
    book { 'Psalms' }
    chapter { 117 }
    first_verse { 1 }
    last_verse { 2 }

    after(:create) do |psg, evaluator|
      for i in evaluator.first_verse..evaluator.last_verse
        # Find or create verse to avoid conflicts
        vs = Verse.find_by(book: evaluator.book, chapter: evaluator.chapter, versenum: i, translation: evaluator.translation)
        if vs.nil?
          vs = FactoryBot.create(:verse, book: evaluator.book, chapter: evaluator.chapter, versenum: i, translation: evaluator.translation)
        end
        FactoryBot.create(:memverse_without_passage, user: evaluator.user, verse: vs, passage_id: psg.id, test_interval: [i, 1].max, rep_n: [i, 1].max, status: 'Learning')
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

    factory :memverse_without_passage do
      # Skip the passage callback to avoid circular dependencies in tests
      after(:build) do |memverse|
        memverse.class.skip_callback(:create, :after, :add_to_passage)
      end
      after(:create) do |memverse|
        memverse.class.set_callback(:create, :after, :add_to_passage)  # Re-enable for other tests
      end
    end

    factory :memverse_without_supermemo_init do
      # Skip supermemo initialization for testing
      after(:build) do |memverse|
        memverse.class.skip_callback(:create, :before, :supermemo_init)
      end
      after(:create) do |memverse|
        memverse.class.set_callback(:create, :before, :supermemo_init)  # Re-enable for other tests
      end
    end
  end

  # ==============================================================================================
  # Blog
  # ==============================================================================================
  factory :blog do
    id { 1 }
    title { 'Memverse Blog' }
  end

  factory :blog_post do
    association :posted_by, factory: :user
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
    book { 'Psalms' }
    chapter { 117 }
    last_verse { 2 }
  end

  # ==============================================================================================
  # Badges
  # ==============================================================================================
  factory :badge do
    name { 'Sermon on the Mount' }
    description { 'Memorize the Sermon on the Mount' }
    color { 'solo' }
    auto_award { true }  # Default to true for most badges
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
    start_time { 1.hour.from_now }
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
    
    # Skip the update callbacks that can cause issues in tests
    after(:build) do |quiz_question|
      quiz_question.class.skip_callback(:create, :after, :update_length, raise: false)
      quiz_question.class.skip_callback(:update, :after, :update_length, raise: false) 
      quiz_question.class.skip_callback(:destroy, :after, :update_length, raise: false)
    end
    
    trait :mcq do
      question_type { "mcq" }
      mc_question { "What is the capital of France?" }
      mc_option_a { "London" }
      mc_option_b { "Paris" }
      mc_option_c { "Berlin" }
      mc_option_d { "Madrid" }
      mc_answer { "B" }
    end
    
    trait :recitation do
      question_type { "recitation" }
    end
    
    trait :reference do
      question_type { "reference" }
    end
  end

  # ==============================================================================================
  # Uberverses
  # ==============================================================================================
  factory :uberverse do
    book { 'Psalms' }
    chapter { 117 }
    versenum { 1 }
    book_index { 19 }
    subsection_end { 0 }
  end

  # ==============================================================================================
  # American States
  # ==============================================================================================
  factory :american_state do
    name { Faker::Address.state }
    abbrev { Faker::Address.state_abbr }
    users_count { 0 }
    population { Faker::Number.between(from: 500000, to: 40000000) }
  end

  # ==============================================================================================
  # Countries
  # ==============================================================================================
  factory :country do
    name { Faker::Address.country }
    printable_name { name }
    iso3 { Faker::Address.country_code_long }
    numcode { Faker::Number.between(from: 1, to: 999) }
    users_count { 0 }
  end

  # ==============================================================================================
  # Churches
  # ==============================================================================================
  factory :church do
    name { "#{Faker::Company.name} Church" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    association :country, factory: :country
    users_count { 0 }
  end

  # ==============================================================================================
  # Devotions
  # ==============================================================================================
  factory :devotion do
    name { 'Spurgeon Morning' }
    month { Faker::Number.between(from: 1, to: 12) }
    day { Faker::Number.between(from: 1, to: 28) }
    thought { Faker::Lorem.paragraph(sentence_count: 5) }
    ref { "#{Faker::Lorem.word.capitalize} #{Faker::Number.between(from: 1, to: 150)}:#{Faker::Number.between(from: 1, to: 50)}" }
  end

  # ==============================================================================================
  # Daily Stats
  # ==============================================================================================
  factory :daily_stats do
    entry_date { Date.today }
    segment { 'Global' }
    users { Faker::Number.between(from: 100, to: 10000) }
    users_active_in_month { Faker::Number.between(from: 50, to: 1000) }
    verses { Faker::Number.between(from: 1000, to: 50000) }
    memverses { Faker::Number.between(from: 500, to: 25000) }
    memverses_memorized { Faker::Number.between(from: 100, to: 5000) }
    memverses_learning { Faker::Number.between(from: 200, to: 8000) }
    memverses_memorized_not_overdue { Faker::Number.between(from: 50, to: 2500) }
    memverses_learning_active_in_month { Faker::Number.between(from: 150, to: 6000) }

    trait :american do
      segment { 'United States' }
    end
  end

  # ==============================================================================================
  # Used to seed Thredded Forum
  # ==============================================================================================
  sequence(:topic_hash) { |n| "hash#{n}" }

  factory :messageboard, class: 'Thredded::Messageboard' do
    name { 'General Discussion' }
    description { 'This is a description of the messageboard' }
  end

  factory :topic, class: 'Thredded::Topic' do
    title { "Sample Topic" }
    association :messageboard, factory: :messageboard
    association :user, factory: :user
    transient do
      with_posts { 0 }
    end
    after(:create) do |topic, evaluator|
      if evaluator.with_posts > 0
        create_list(:post, evaluator.with_posts, postable: topic, messageboard: topic.messageboard)
      end
    end
  end

  factory :post, class: 'Thredded::Post' do
    content { "This is a sample post content." }
    association :user, factory: :user
    association :postable, factory: :topic
    association :messageboard, factory: :messageboard
  end

  factory :private_post, class: 'Thredded::PrivatePost' do
    content { "This is a private post content." }
    association :user, factory: :user
    association :postable, factory: :private_topic
  end

  factory :private_topic, class: 'Thredded::PrivateTopic' do
    title { Faker::Lorem.sentence[0..-2] }
    hash_id { generate(:topic_hash) }
    association :user, factory: :user
    association :last_user, factory: :user
    users { build_list :user, 1 }
  end

  # ==============================================================================================
  # CKEditor - Using Active Storage
  # ==============================================================================================
  factory :ckeditor_picture, class: 'Ckeditor::Picture' do
    type { 'Ckeditor::Picture' }
    
    after(:build) do |picture|
      picture.data_attachment.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')),
        filename: 'test_image.jpg',
        content_type: 'image/jpeg'
      )
    end
  end

  factory :ckeditor_attachment_file, class: 'Ckeditor::AttachmentFile' do
    type { 'Ckeditor::AttachmentFile' }
    
    after(:build) do |attachment|
      attachment.data_attachment.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_document.pdf')),
        filename: 'test_document.pdf',
        content_type: 'application/pdf'
      )
    end
  end

  # ==============================================================================================
  # Sermons
  # ==============================================================================================
  factory :sermon do
    title { 'Test Sermon' }
    summary { 'This is a test sermon' }
    association :user, factory: :user
  end

end
