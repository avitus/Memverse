describe "Routing to memverses" do

  it "route to add a chapter" do
	expect(:post => "/add_chapter").to route_to(
	  :controller => "memverses",
	  :action     => "add_chapter"
	)
  end

  it "route to add a tag" do
	expect(:post => "/add_tag").to route_to(
	  :controller => "memverses",
	  :action     => "add_mv_tag"
	)
  end

  it "route to autocomplete tag" do
	expect(:get => "/tag_autocomplete").to route_to(
	  :controller => "memverses",
	  :action     => "tag_autocomplete"
	)
  end

end