#Background info

Given /^the following tags exist:$/ do |table|

  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    ActsAsTaggableOn::Tag.create(hash)
  end

end

And /^Old Dog is signed in$/ do
  %{And the email address "olddog@test.com" is confirmed}
  %{When I go to the sign in page}
  %{And I sign in as "olddog@test.com/please"}
  %{Then I should be signed in}
end
