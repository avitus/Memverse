class RenameBlogTables < ActiveRecord::Migration

  def change
    rename_table :blogs, 			:bloggity_blogs
    rename_table :blog_posts, 		:bloggity_blog_posts
    rename_table :blog_comments, 	:bloggity_blog_comments
    rename_table :blog_tags, 		:bloggity_blog_tags
    rename_table :blog_assets, 		:bloggity_blog_assets
    rename_table :blog_categories, 	:bloggity_blog_categories
  end 

end
