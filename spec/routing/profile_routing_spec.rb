require "spec_helper"

describe UsersController do
  describe "routing" do

    it "routes to #unsubscribe" do
      get("/unsubscribe/test@memverse.com").should route_to("profile#unsubscribe", email: "test@memverse.com")
    end

  end
end