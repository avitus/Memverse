Given /^the user named "(.*?)" has a memverse$/ do |name|
  # Use the current user that was created in the background
  user = User.find_by(email: @current_user_email)
  if user.nil?
    raise "No current user found. Make sure to create a user first."
  end
  verse = FactoryBot.create(:verse)
  memverse = FactoryBot.create(:memverse, user: user, verse: verse)
  # Store IDs for use in scenario
  @memverse_id = memverse.id
  @verse_id = verse.id
end
