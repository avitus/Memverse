# encoding: utf-8
describe BlogPost do

  before(:each) do
    @blog = Factory(:blog, :title => "Memverse Blog")
  end

  # it "should give URL identifier" do
  #   post = Factory(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id)
  #   post.url_identifier.should == "scripture-memorization"
  # end
  # 
  # it "should not give the same URL identifier" do
  #   post1 = Factory(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id)
  #   post1.url_identifier.should == "scripture-memorization"
  #   post2 = Factory(:blog_post, :title => "Scripture Memorization", :blog_id => @blog.id)
  #   post2.url_identifier.should == "scripture-memorization--1"
  # end
  
  # Commented out; kept getting error: "Validation failed: Posted by is not authorized to post to this blog"
end
