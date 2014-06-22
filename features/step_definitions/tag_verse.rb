#Background info

Given /^the tag "([^"]*)" exists$/ do |tag|

  # Attach tag to a memverse => taggable_count 1
  # Then it appears in autocomplete on memverses/show

  vs = FactoryGirl.create(:verse, translation: "ESV")
  mv = FactoryGirl.create(:memverse, verse: vs)

  tag_list = mv.all_tags_list.to_s + ", " + tag
  User.first.tag(mv, with: tag_list, on: :tags)

  mv.verse.update_tags # Update verse model with most popular tags

  Verse.tag_counts.last.name.should == tag

end

And /^Old Dog is signed in$/ do
  %{And the email address "olddog@test.com" is confirmed}
  %{When I go to the sign in page}
  %{And I sign in as "olddog@test.com/please"}
  %{Then I should be signed in}
end
