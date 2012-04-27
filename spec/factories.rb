require 'factory_girl'

FactoryGirl.define do

  factory :user do |u|
    u.name 'Test User'
	u.sequence(:email) { |n| "user#{n}@test.com" }
    u.password 'please'
    u.password_confirmation { |u| u.password }     
  end
  
  factory :verse do |v|
    v.translation 'NIV'
    v.book_index 1
    v.book 'Genesis'
    v.chapter 1
    v.versenum 1
    v.text 'In the beginning, God created the heavens and the earth.'
  end
  
  factory :memverse do |mv|
    mv.association :verse, :factory => :verse
    mv.association :user,  :factory => :user
    mv.status 'Learning'
  end
  
  factory :blog do |f|
    f.id 1
    f.title 'Memverse Blog'
  end
  
  factory :blog_post do |f|
    f.association :posted_by_id, :factory => :user
  end
  
  factory :blog_comment do |bc|
    bc.association :blog_post, :factory => :blog_post
	bc.association :user, :factory => :user
	bc.comment 'Nice blog post!'
  end
  
  factory :final_verse do |f|
    f.book 'Genesis'
    f.chapter 1
    f.last_verse 31
  end
  
  factory :badge do |b|
    b.name 'Sermon on the Mount'
    b.description 'Memorize the Sermon on the Mount'
    b.color 'solo'
  end
  
  factory :quest do |q|
    q.task 'Memorize Matthew 5'
    q.objective 'Chapters'
    q.qualifier 'Matthew 5'
    q.association :badge, :factory => :badge
  end

  factory :progress_report do |pr|
    pr.association :user, :factory => :user
    pr.learning   50
    pr.memorized 100
    pr.entry_date Date.today
  end
end
