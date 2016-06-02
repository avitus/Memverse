module ControllerMacros

  puts " ====> Loading controller macros."

  def login_user
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryGirl.create(:user)
    @user.confirm # or set a confirmed_at inside the factory. Only necessary if you are using the confirmable module
    sign_in @user
  end

  def login_admin
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:admin) # Using factory girl as an example
  end

end
