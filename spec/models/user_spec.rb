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
    user = User.create!(@attr)
    user.confirm if user.respond_to?(:confirm)  # Skip email confirmation in tests
  end

  it "should require an email address" do
    no_email_user = User.new(@attr.merge(:email => ""))
    expect(no_email_user).not_to be_valid
  end

  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = User.new(@attr.merge(:email => address))
      expect(valid_email_user).to be_valid
    end
  end

  it "should reject invalid email addresses" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    # addresses = %w[ user_at_foo.org ]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      expect(invalid_email_user).not_to be_valid
    end
  end

  it "should reject duplicate email addresses" do
    user = User.create!(@attr)
    user.confirm if user.respond_to?(:confirm)  # Skip email confirmation in tests
    user_with_duplicate_email = User.new(@attr)
    expect(user_with_duplicate_email).not_to be_valid
  end

  it "should reject email addresses identical up to case" do
    upcased_email = @attr[:email].upcase
    user = User.create!(@attr.merge(:email => upcased_email))
    user.confirm if user.respond_to?(:confirm)  # Skip email confirmation in tests
    user_with_duplicate_email = User.new(@attr)
    expect(user_with_duplicate_email).not_to be_valid
  end

  describe "passwords" do

    before(:each) do
      @user = User.new(@attr)
    end

    it "should have a password attribute" do
      expect(@user).to respond_to(:password)
    end

    it "should have a password confirmation attribute" do
      expect(@user).to respond_to(:password_confirmation)
    end
  end

  describe "password validations" do

    it "should require a password" do
      expect(User.new(@attr.merge(:password => "", :password_confirmation => ""))).not_to be_valid
    end

    it "should require a matching password confirmation" do
      expect(User.new(@attr.merge(:password_confirmation => "invalid"))).not_to be_valid
    end

    it "should reject short passwords" do
      short = "a" * 5
      hash = @attr.merge(:password => short, :password_confirmation => short)
      expect(User.new(hash)).not_to be_valid
    end

  end

  describe "password encryption" do

    before(:each) do
      @user = User.create!(@attr)
      @user.confirm if @user.respond_to?(:confirm)  # Skip email confirmation in tests
    end

    it "should have an encrypted password attribute" do
      expect(@user).to respond_to(:encrypted_password)
    end

    it "should set the encrypted password attribute" do
      expect(@user.encrypted_password).not_to be_blank
    end

  end

  # ==============================================================================================
  # Adjusting work load
  # ==============================================================================================
  describe "adjust_work_load" do
    it "should not change the account of an overworked user" do
      @user = FactoryBot.create(:user, :time_allocation => 5)
      expect(@user.work_load).to eq(2)
      for i in 1..3
        # Use unique verses to avoid duplicate key errors
        verse = FactoryBot.create(:verse, :book_index => 19, :book => "Psalms", :chapter => 117, :versenum => i)
        FactoryBot.create(:memverse, :user => @user, :verse => verse)
      end
      expect(@user.work_load).to eq(5)
      expect(@user.adjust_work_load).to eq(false)
    end

    it "should adjust the work load of an underworked user" do
      @user = FactoryBot.create(:user)

      for i in 5..14 # setup learning verses
        verse = FactoryBot.create(:verse, :book_index => 2, :book => "Exodus", :chapter => 20, :versenum => i)
        mv = FactoryBot.create(:memverse, :user => @user, :verse => verse)
        mv.update!(:test_interval => i, :next_test => Date.today + i, :status => "Learning")
      end

      for i in 1..5 # setup pending verses
        verse = FactoryBot.create(:verse, :book_index => 19, :book => "Psalms", :chapter => 118, :versenum => i)
        mv    = FactoryBot.create(:memverse, :user => @user, :verse => verse)
        Memverse.update(mv.id, :status => "Pending")
      end

      expect(@user.due_verses).to eq(0)

      expect(Memverse.includes(:verse).where('verses.book_index' => 19, 'user_id' => @user.id).first.status).to eq("Pending")
      expect(@user.work_load).to eq(3)
      expect(@user.adjust_work_load.length).to eq(2) # should activate 2 memverses
      expect(@user.work_load).to eq(5)

      expect(@user.due_verses).to eq(0)
    end
  end

  # ==============================================================================================
  # Reset memorization schedule
  # ==============================================================================================
  describe "reset_memorization_schedule" do
    it "should space out verses appropriately" do
      @user = FactoryBot.create(:user)

      for i in 11..20 # setup learning verses
        verse = FactoryBot.create(:verse, :book_index => 2, :book => "Exodus", :chapter => 20, :versenum => i)
        FactoryBot.create(:memverse, :user => @user, :verse => verse, :test_interval => i, :next_test => Date.today - i)
      end

      expect(@user.work_load).to eq(3)
      load_for_today = @user.memverses.active.where("next_test <= ?", Date.today).count

      @user.reset_memorization_schedule
      new_load_for_today = @user.memverses.active.where("next_test <= ?", Date.today).count
      expect(new_load_for_today).to be < load_for_today
      load_for_tomorrow  = @user.memverses.active.where("next_test = ?", Date.tomorrow).count
      expect(load_for_tomorrow).to eq(new_load_for_today)
    end
  end

  describe ".can_blog?" do
    it "is true for user with blogger role" do
      user = FactoryBot.create(:user)
      blogger = FactoryBot.create(:role, name: "blogger")
      blogger.users << user

      expect([user.can_blog?]).to eq([true])
    end

    it "is false for non-bloggers" do
      user = FactoryBot.create(:user)

      expect([user.can_blog?]).to eq([false])
    end
  end

end

