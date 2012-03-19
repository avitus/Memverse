#Background info

And /^I make a tag named ".*"$/ do |tag_name| 
   Tag.new(:tag_name => name)
end

And /^Old Dog is signed in$/ do
  %{And the email address "olddog@test.com" is confirmed}
  %{When I go to the sign in page}
  %{And I sign in as "olddog@test.com/please"}   
  %{Then I should be signed in}
end