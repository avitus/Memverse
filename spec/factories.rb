require 'factory_girl'

Factory.define :user do |f|
  f.name 'Test User'
  f.email 'user@test.com'
  f.password 'please'
  f.password_confirmation { |u| u.password }
end

Factory.define :memverse do |mv|
  mv.association :user,  :factory => :user
  mv.association :verse, :factory => :verse
end

Factory.define :verse do |v|
  v.translation 'NIV'
  v.book_index '1'
  v.book 'Genesis'
  v.chapter '1'
  v.versenum '1'
  v.association :memverse, :factory => :memverse
end

Factory.define :blog do |f|
  f.id 1
  f.title 'Memverse Blog'
end

Factory.define :blog_post do |f|
  f.posted_by_id 2
end
