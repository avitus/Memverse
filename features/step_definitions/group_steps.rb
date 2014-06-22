Given /^a group called "([^"]*)"$/ do |group_name|
  Group.new(name: group_name).save!
end

Given /^the normal user belongs to the group called "([^"]*)"$/ do |group_name|
  user = User.find_by_email('user@test.com')
  grp  = Group.find_by_name(group_name)
  user.group = grp
  user.save!
end

Given /^the normal user is the leader of the group called "([^"]*)"$/ do |group_name|
  user = User.find_by_email('user@test.com')
  grp  = Group.find_by_name(group_name)
  grp.leader = user
  grp.save!
end