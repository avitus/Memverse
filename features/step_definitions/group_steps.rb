Given /^a group called "([^"]*)"$/ do |group_name|
  Group.new(:name => group_name).save!
end

Given /^the normal user belongs to the group called "([^"]*)"$/ do |group_name|
  # Find the current user (created in the scenario)
  user = User.find_by_email(@current_user_email) if @current_user_email
  user ||= User.find_by_email('user@test.com')
  
  if user.nil?
    raise "Normal user does not exist. Make sure to create a user first in the scenario."
  end
  
  grp = Group.find_by_name(group_name)
  if grp.nil?
    raise "Group #{group_name} does not exist"
  end
  
  user.group = grp
  user.save!
end

Given /^the normal user is the leader of the group called "([^"]*)"$/ do |group_name|
  # Find the current user (created in the scenario)
  user = User.find_by_email(@current_user_email) if @current_user_email
  user ||= User.find_by_email('user@test.com')
  
  if user.nil?
    raise "Normal user does not exist. Make sure to create a user first in the scenario."
  end
  
  grp = Group.find_by_name(group_name)
  if grp.nil?
    raise "Group #{group_name} does not exist"
  end
  
  grp.leader = user
  grp.save!
end