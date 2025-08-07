class Devotion < ApplicationRecord
  
  # Get devotion for the day and save in database
  # @return [Devotion, nil]
  def self.daily_refresh
    Rails.logger.info("*** Devotion not in DB -- retrieving from web")

    begin
      dev_url   = 'http://feeds.feedburner.com/hl-devos-spurgeon-morning'
      posts = RssReader.posts_for(dev_url, length=1, perform_validation=false)
      
      # Handle case where RssReader returns nil or empty array
      return nil unless posts && posts.any?
      
      dailydev = posts[0]

      # Parse feed with Nokogiri
      if dailydev && dailydev.description
        dd = Nokogiri::HTML(dailydev.description)
        
        # Safely extract reference from anchor tag
        anchor = dd.at_css("a")
        @dev_ref = anchor && anchor.child ? anchor.child.to_s.capitalize : ""
        @devotion = dailydev.description
          
        create!( name: "Spurgeon Morning", 
                 month: Date.today.month, day: Date.today.day,
                 thought: @devotion,
                 ref: @dev_ref ) unless Devotion.exists?(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day)
      end
    rescue StandardError => e
      Rails.logger.error("Error refreshing devotion: #{e.message}")
      return nil
    end
  end
    
end