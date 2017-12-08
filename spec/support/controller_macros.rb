module ControllerMacros

  puts " ====> Loading controller macros."

  def login_user
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryBot.create(:user)
    @user.confirm # or set a confirmed_at inside the factory. Only necessary if you are using the confirmable module
    sign_in @user
  end

  def login_admin
    @request.env["devise.mapping"] = Devise.mappings[:user]

    @user = FactoryBot.create(:user)
    @user.confirm # or set a confirmed_at inside the factory. Only necessary if you are using the confirmable module

    admin = FactoryBot.create(:role, name: "admin")
    admin.users << @user
    
    sign_in @user 
  end

  def login_scribe
    @request.env["devise.mapping"] = Devise.mappings[:user]

    @user = FactoryBot.create(:user)
    @user.confirm # or set a confirmed_at inside the factory. Only necessary if you are using the confirmable module

    scribe = FactoryBot.create(:role, name: "scribe")
    scribe.users << @user
    
    sign_in @user    
  end

  def login_quizmaster
    @request.env["devise.mapping"] = Devise.mappings[:user]

    @user = FactoryBot.create(:user)
    @user.confirm # or set a confirmed_at inside the factory. Only necessary if you are using the confirmable module

    quizmaster = FactoryBot.create(:role, name: "quizmaster")
    quizmaster.users << @user
    
    sign_in @user    
  end    

end
