# encoding: utf-8
describe Group do

  before(:each) do    
    @user1 = FactoryGirl.create(:user, :name => "User1")
    @user2 = FactoryGirl.create(:user, :name => "User2")
    @user3 = FactoryGirl.create(:user, :name => "User3")
    
    @group = FactoryGirl.create(:group, :name => 'Band of Memorizers', :leader => @user1)
  end

  it "should return the active leader if there is one" do
    @group.get_leader!.name.should == "User1"
  end

  it "should replace inactive leaders with a new one" do
    @user1.last_activity_date = Date.today - 2.months
    @group.get_leader!.name.should == "User2"
  end

end