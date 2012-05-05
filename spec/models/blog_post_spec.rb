# encoding: utf-8
describe BlogPost do

  before(:each) do
    @blog = FactoryGirl.create(:blog, :title => "Memverse Blog")
    @user = FactoryGirl.create(:user, :id => 2) # user with id of 2 will be allowed to post
  end

  it "should give URL identifier" do
    post = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    post.url_identifier.should == "scripture-memorization"
  end

  it "should not give the same URL identifier" do
    post1 = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    post1.url_identifier.should == "scripture-memorization"
    pp post1.id

    post2 = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    post2.url_identifier.should == "scripture-memorization--1"
    pp post2.id
  end
end
