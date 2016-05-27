# encoding: utf-8

describe "Placeholder behavior", :js => true do
  before do
    @user = User.new name: "Zero",
      last_name: "My Hero",
      address: "0 Nowhere lane",
      email: "zero@zero.com",
      height: "0",
      zip: "00000",
      description: ""                    
  end

  it "should set a place_holder value" do
    @user.save!
    visit user_path(@user)
    expect(find('#favorite_locale')).to have_content("N/A")
  end

  it "should allow the use of 0 for a placeholder" do
    @user.save!
    visit user_path(@user)
    expect(find('#zero_field')).to have_content("0")
  end

end