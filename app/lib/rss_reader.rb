# coding: utf-8

require 'rss'
require 'open-uri'

class RssReader

  def self.posts_for(feed_url, length=2, perform_validation=false)
    posts = []
    URI.open(feed_url) do |rss|
    # URI.open('http://www.heartlight.org/rss/track/devos/spurgeon-morning/') do |rss|
      posts = RSS::Parser.parse(rss, perform_validation)
    end
    
    # Occasionally 'posts' is nil so we need to check for this before we access 'posts.items'
    if posts
      posts.items[0..length - 1] if posts.items.size > length
    end
    
  end

end
