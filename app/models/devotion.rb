class Devotion < ActiveRecord::Base
  
  # Get devotion for the day and save in database
  # @return [Devotion, nil]
  def self.daily_refresh
    Rails.logger.info("*** Devotion not in DB -- retrieving from web")

    dev_url   = 'http://feeds.feedburner.com/hl-devos-spurgeon-morning'
    dailydev  = RssReader.posts_for(dev_url, length=1, perform_validation=false)[0] 

    # Parse feed with Nokogiri
    if dailydev
      dd = Nokogiri::HTML(dailydev.description)
      @dev_ref  = dd.at_css("a").child.to_s.capitalize
      @devotion = dailydev.description unless !dailydev.description
        
      create!( name: "Spurgeon Morning", 
               month: Date.today.month, day: Date.today.day,
               thought: @devotion,
               ref: @dev_ref ) unless Devotion.exists?(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day)
    end  
  end
    
end