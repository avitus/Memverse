Given /^I advance (\d+) learning levels/ do |n|
  n.to_i.times { |i|
    step %{I click inside "div.inc-level"}
  }
end
