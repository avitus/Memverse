# coding: utf-8
class CleanseVerses < ActiveRecord::Migration
  def up
    Verse.all.each do |vs|
      
      cleansed_text = String.new(vs.text)
      
      cleansed_text.gsub!('â€”',  '—')
      cleansed_text.gsub!(' - ',  ' — ')
      cleansed_text.gsub!('â€™',  '’')
      cleansed_text.gsub!('â€œ',  '“')
      cleansed_text.gsub!('â€', '”')

      # if cleansed_text != vs.text
        # Rails.logger.info("Saving text: #{cleansed_text}")
      # end
      
      vs.text = cleansed_text
     
      vs.save!
      
    end
  end

  def down
  end
end
