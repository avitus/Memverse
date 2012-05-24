# encoding: utf-8
describe BlogComment do

  before(:each) do
    @blog = FactoryGirl.create(:blog, :title => "Memverse Blog")
	@user = FactoryGirl.create(:user, :id => 2) # user with id of 2 will be allowed to post
	@post = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id, :posted_by => @user)
  end

  it "should add rel='nofollow' to links" do
    comment = FactoryGirl.create(:blog_comment, :comment => "Check out www.mysite.com", :blog_post => @post)
    comment.comment.should == 'Check out <a href="http://www.mysite.com" rel="nofollow">www.mysite.com</a>'

	comment = FactoryGirl.create(:blog_comment, :comment => 'Check out <a href="http://www.mysite.com">www.mysite.com</a>', :blog_post => @post)
    comment.comment.should == 'Check out <a href="http://www.mysite.com" rel="nofollow">www.mysite.com</a>'
  end
end
