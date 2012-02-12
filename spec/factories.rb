require 'factory_girl'

Factory.define :user do |u|
  u.name 'Test User'
  u.email 'user@test.com'
  u.password 'please'
  u.password_confirmation { |u| u.password }
end

Factory.define :memverse do |mv|
  mv.association :verse, :factory => :verse
  mv.association :user, :factory => :user  
end

Factory.define :verse do |v|
  v.translation 'NIV'
  v.book_index '1'
  v.book 'Genesis'
  v.chapter '1'
  v.versenum '1'
end

Factory.define :blog do |f|
  f.id 1
  f.title 'Memverse Blog'
end

Factory.define :blog_post do |f|
  f.posted_by_id 2
end
