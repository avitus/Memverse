require "spec_helper"

describe PassagesController do
  describe "routing" do

    it "routes to #index" do
      get("/passages").should route_to("passages#index")
    end

    it "routes to #new" do
      get("/passages/new").should route_to("passages#new")
    end

    it "routes to #show" do
      get("/passages/1").should route_to("passages#show", :id => "1")
    end

    it "routes to #edit" do
      get("/passages/1/edit").should route_to("passages#edit", :id => "1")
    end

    it "routes to #create" do
      post("/passages").should route_to("passages#create")
    end

    it "routes to #update" do
      put("/passages/1").should route_to("passages#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/passages/1").should route_to("passages#destroy", :id => "1")
    end

  end
end
