require 'factory_girl'

Factory.define :user do |f|
  f.name 'Test User'
  f.email 'user@test.com'
  f.password 'please'
  f.password_confirmation { |u| u.password }
end

Factory.define :verse do |f|
  f.translation 'NIV'
  f.book_index '1'
  f.book 'Genesis'
  f.chapter '1'
  f.versenum '1'
end

Factory.define :blog do |f|
  f.id 1
  f.title 'Memverse Blog'
end

Factory.define :blog_post do |f|
  f.posted_by_id 2
end