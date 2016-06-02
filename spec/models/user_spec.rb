require 'spec_helper'

describe User do

  before(:each) do
    @attr = {
      :name => "Example User",
      :email => "user@example.com",
      :password => "foobar",
      :password_confirmation => "foobar"
    }
  end

  it "should create a new instance given a valid attribute" do
    User.create!(@attr)
  end

  it "should require an email address" do
    no_email_user = User.new(@attr.merge(:email => ""))
    no_email_user.should_not be_valid
  end

  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = User.new(@attr.merge(:email => address))
      valid_email_user.should be_valid
    end
  end

  it "should reject invalid email addresses" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    # addresses = %w[ user_at_foo.org ]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      invalid_email_user.should_not be_valid
    end
  end

  it "should reject duplicate email addresses" do
    User.create!(@attr)
    user_with_duplicate_email = User.new(@attr)
    user_with_duplicate_email.should_not be_valid
  end

  it "should reject email addresses identical up to case" do
    upcased_email = @attr[:email].upcase
    User.create!(@attr.merge(:email => upcased_email))
    user_with_duplicate_email = User.new(@attr)
    user_with_duplicate_email.should_not be_valid
  end

  describe "passwords" do

    before(:each) do
      @user = User.new(@attr)
    end

    it "should have a password attribute" do
      @user.should respond_to(:password)
    end

    it "should have a password confirmation attribute" do
      @user.should respond_to(:password_confirmation)
    end
  end

  describe "password validations" do

    it "should require a password" do
      User.new(@attr.merge(:password => "", :password_confirmation => "")).
        should_not be_valid
    end

    it "should require a matching password confirmation" do
      User.new(@attr.merge(:password_confirmation => "invalid")).
        should_not be_valid
    end

    it "should reject short passwords" do
      short = "a" * 5
      hash = @attr.merge(:password => short, :password_confirmation => short)
      User.new(hash).should_not be_valid
    end

  end

  describe "password encryption" do

    before(:each) do
      @user = User.create!(@attr)
    end

    it "should have an encrypted password attribute" do
      @user.should respond_to(:encrypted_password)
    end

    it "should set the encrypted password attribute" do
      @user.encrypted_password.should_not be_blank
    end

  end

  # ==============================================================================================
  # Adjusting work load
  # ==============================================================================================
  describe "adjust_work_load" do
    it "should not change the account of an overworked user" do
      @user = FactoryGirl.create(:user, :time_allocation => 5)
      @user.work_load.should == 2
      for i in 1..3
        verse = FactoryGirl.create(:verse, :book_index => 1, :book => "Genesis", :chapter => 3, :versenum => i)
        FactoryGirl.create(:memverse, :user => @user, :verse => verse)
      end
      @user.work_load.should == 5
      @user.adjust_work_load.should == false
    end

    it "should adjust the work load of an underworked user" do
      @user = FactoryGirl.create(:user)

      for i in 5..14 # setup learning verses
        verse = FactoryGirl.create(:verse, :book_index => 2, :book => "Exodus", :chapter => 20, :versenum => i)
        FactoryGirl.create(:memverse, :user_id => @user.id, :verse_id => verse.id, :test_interval => i, :next_test => Date.today + i)
      end

      for i in 1..5 # setup pending verses
        verse = FactoryGirl.create(:verse, :book_index => 19, :book => "Psalms", :chapter => 118, :versenum => i)
        mv    = FactoryGirl.create(:memverse, :user => @user, :verse => verse)
        Memverse.update(mv.id, :status => "Pending")
      end

      @user.due_verses.should == 0

      Memverse.includes(:verse).where('verses.book_index' => 19, 'user_id' => @user.id).first.status.should == "Pending"
      @user.work_load.should == 3
      @user.adjust_work_load.length.should == 2 # should activate 2 memverses
      @user.work_load.should == 5

      @user.due_verses.should == 0
    end
  end

  # ==============================================================================================
  # Reset memorization schedule
  # ==============================================================================================
  describe "reset_memorization_schedule" do
    it "should space out verses appropriately" do
      @user = FactoryGirl.create(:user)

      for i in 11..20 # setup learning verses
        verse = FactoryGirl.create(:verse, :book_index => 2, :book => "Exodus", :chapter => 20, :versenum => i)
        FactoryGirl.create(:memverse, :user => @user, :verse => verse, :test_interval => i, :next_test => Date.today - i)
      end

      @user.work_load.should == 3
      load_for_today = @user.memverses.active.where("next_test <= ?", Date.today).count

      @user.reset_memorization_schedule
      new_load_for_today = @user.memverses.active.where("next_test <= ?", Date.today).count
      new_load_for_today.should be < load_for_today
      load_for_tomorrow  = @user.memverses.active.where("next_test = ?", Date.tomorrow).count
      load_for_tomorrow.should == new_load_for_today
    end
  end

  describe ".can_blog?" do
    it "is true for user with blogger role" do
      user = FactoryGirl.create(:user)
      blogger = FactoryGirl.create(:role, name: "blogger")
      blogger.users << user

      [user.can_blog?].should == [true]
    end

    it "is false for non-bloggers" do
      user = FactoryGirl.create(:user)

      [user.can_blog?].should == [false]
    end
  end

end

