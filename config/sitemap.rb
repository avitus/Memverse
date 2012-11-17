# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.memverse.com"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  # Add all top level paths
  add root_path
  add demo_path, :priority => 0.8, :changefreq => 'monthly'
  add tutorial_path
  add leaderboard_path
  add faq_path
  add popular_path    # popular verses
  
  # Add root path for forem and blog
  add '/forums'    # ALV: not sure how to do this using a route helper
  add '/blog'      # bloggity.root_path does not work

  # Add blog posts
  # BlogPost.find_each do |blog_post|
  #   add blog_posts_path(blog_post), :lastmod => blog_post.updated_at
  # end


end
