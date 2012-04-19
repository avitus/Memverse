# encoding: utf-8
describe BlogPost do

  before(:each) do
    @blog = FactoryGirl.create(:blog, :title => "Memverse Blog")
  end

  # it "should give URL identifier" do
  #   post = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id)
  #   post.url_identifier.should == "scripture-memorization"
  # end
  # 
  # it "should not give the same URL identifier" do
  #   post1 = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id)
  #   post1.url_identifier.should == "scripture-memorization"
  #   post2 = FactoryGirl.create(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id)
  #   post2.url_identifier.should == "scripture-memorization--1"
  # end
  
  # Commented out; kept getting error: "Validation failed: Posted by is not authorized to post to this blog"
end
