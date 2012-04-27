# encoding: utf-8
describe BlogPost do

  before(:each) do
    @blog = Factory.create(:blog, :title => "Memverse Blog")
	@user = Factory.create(:user, :id => 2) # user with id of 2 will be allowed to post
  end

  it "should give URL identifier" do
    post = Factory.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    post.url_identifier.should == "scripture-memorization"
  end

  it "should not give the same URL identifier" do
    post1 = Factory.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    post1.url_identifier.should == "scripture-memorization"
    # post2 = Factory.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
    # post2.url_identifier.should == "scripture-memorization--1"
  end
end
