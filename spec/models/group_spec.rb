# encoding: utf-8
=begin
describe Group do

  before(:each) do    
    @user1 = FactoryBot.create(:user, :name => "User1")
    @user2 = FactoryBot.create(:user, :name => "User2", :last_activity_date => Date.today-2.months)  # an inactive user
    @user3 = FactoryBot.create(:user, :name => "User3")
    
    # User1 creates a new group
    @group = FactoryBot.create(:group, :name => 'Band of Memorizers', :leader => @user1)
    
    # 3 users join new group
    @user1.group = @group
    @user1.save
    @user2.group = @group
    @user2.save
    @user3.group = @group
    @user3.save
  end

  it "should return the active leader if there is one" do
    @group.leader.name.should == "User1"
  end

  it "should replace inactive leaders with a new one" do
    @user1.last_activity_date = Date.today - 2.months
    @group.get_leader!
    @group.leader.name.should == "User3"
  end

end
=end