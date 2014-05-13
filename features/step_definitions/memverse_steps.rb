Given /^the user named "(.*?)" has a memverse with the id of ([0-9]+)$/ do |name, id|
  user = User.where(name: name).first
  FactoryGirl.create(:memverse, id: id, user: user)
end
