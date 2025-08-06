require "spec_helper"

describe UsersController do
  describe "routing" do

    it "routes to #update_ref_grade" do
      expect(post("/save_ref_grade/50")).to route_to("users#update_ref_grade", :score => "50")
    end

  end
end
