require "spec_helper"

describe PassagesController do
  describe "routing" do

    it "routes to #index" do
      expect(get("/passages")).to route_to("passages#index")
    end

    it "routes to #new" do
      expect(get("/passages/new")).to route_to("passages#new")
    end

    it "routes to #show" do
      expect(get("/passages/1")).to route_to("passages#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/passages/1/edit")).to route_to("passages#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/passages")).to route_to("passages#create")
    end

    it "routes to #update" do
      expect(put("/passages/1")).to route_to("passages#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/passages/1")).to route_to("passages#destroy", :id => "1")
    end

  end
end
