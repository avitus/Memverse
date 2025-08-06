require "spec_helper"

describe UsersController do
  describe "routing" do

    it "routes to #unsubscribe" do
      expect(get("/unsubscribe/test@memverse.com")).to route_to("profile#unsubscribe", :email => "test@memverse.com")
    end

  end
end