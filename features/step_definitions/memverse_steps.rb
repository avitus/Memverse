Given /^the following memverses exist:$/ do |table|

  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|  
		FactoryGirl.create(:memverse, hash)
	end

end
