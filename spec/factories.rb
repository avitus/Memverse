require 'factory_girl'

FactoryGirl.define do

  factory :user do |u|
    u.name 'Test User'
    u.email 'user@test.com'
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
    mv.association :user, :factory => :user  
  end
  
  factory :blog do |f|
    f.id 1
    f.title 'Memverse Blog'
  end
  
  factory :blog_post do |f|
    f.posted_by_id 2
  end
  
  factory :final_verse do |f|
    f.book 'Genesis'
    f.chapter 1
    f.last_verse 31
  end

end
