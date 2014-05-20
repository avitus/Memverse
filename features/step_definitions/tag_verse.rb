#Background info

Given /^the tag "([^"]*)" exists$/ do |tag|

  # Attach tag to a memverse => taggable_count 1
  # Then it appears in autocomplete on memverses/show

  vs = FactoryGirl.create(:verse, translation: "ESV")
  mv = FactoryGirl.create(:memverse, verse: vs)

  mv.tag_list.add(tag)

  mv.verse.update_tags # Update verse model with most popular tags

end

And /^Old Dog is signed in$/ do
  %{And the email address "olddog@test.com" is confirmed}
  %{When I go to the sign in page}
  %{And I sign in as "olddog@test.com/please"}
  %{Then I should be signed in}
end
