class AddTweetedToBlogPost < ActiveRecord::Migration
  class BlogPost < ActiveRecord::Base
  end
  def change
    add_column :blog_posts, :tweeted, :boolean, :default => false
    BlogPost.reset_column_information
    BlogPost.where("is_complete = ?", true).each { |f| f.update_attributes!(:tweeted => true) }
  end
end
