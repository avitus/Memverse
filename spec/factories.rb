Factory.define :user do |u|
  u.sequence(:login) { |n| "demo#{n}" }
  u.password 'secret'
  u.password_confirmation { |u| u.password } 
  u.sequence(:email) { |n| "demo#{n}@example.com" }
  u.after_create { |user| user.register }
  u.after_create { |user| user.activate! }
end
