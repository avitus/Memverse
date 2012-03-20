# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# puts 'SETTING UP DEFAULT USER LOGIN'
# user = User.create :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
# puts '  New user created: ' << user.name

# TODO: Add popular verses

# Add 50 quest levels
puts 'SETTING UP QUESTS'
for i in 19..50
  
  puts "  Creating quests for level #{i}"
  
  learning_verses   = (i-6)*25 + 50
  memorized_verses  = learning_verses - 50
  
  gospel_learning   = (learning_verses.to_f / 10.0).round
  epistle_learning  = (learning_verses.to_f / 10.0).round
  wisdom_learning   = (learning_verses.to_f / 20.0).round
  history_learning  = (learning_verses.to_f / 20.0).round
  prophecy_learning = (learning_verses.to_f / 20.0).round

  gospel_memorized   = (memorized_verses.to_f / 10.0).round
  epistle_memorized  = (memorized_verses.to_f / 10.0).round
  wisdom_memorized   = (memorized_verses.to_f / 20.0).round
  history_memorized  = (memorized_verses.to_f / 20.0).round
  prophecy_memorized = (memorized_verses.to_f / 20.0).round
  
  accuracy           = i + 15
  ref_recall         = [i + 50, 90].min
  
  referrals          = ((i-6).to_f / 3.0).round
  tags               = (learning_verses.to_f / 5.0).round
  
  chapters_learning  = ((i-5).to_f / 3.0).round
  chapters_memorized = ((i-7).to_f / 3.0).round

  # Learning quests
  q = Quest.where(:level => i, :objective => 'Verses', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Verses', :qualifier => 'Learning', :quantity => learning_verses, :task => "Learn #{learning_verses} verses.")
  end
  
  # Memorized quests
  q = Quest.where(:level => i, :objective => 'Verses', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Verses', :qualifier => 'Memorized', :quantity => memorized_verses, :task => "Memorize #{memorized_verses} verses.")
  end  
  
  # Gospel quests
  q = Quest.where(:level => i, :objective => 'Gospels', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Gospels', :qualifier => 'Learning', :quantity => gospel_learning, :task => "Learn #{gospel_learning} verses from the gospels.")
  end  

  q = Quest.where(:level => i, :objective => 'Gospels', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Gospels', :qualifier => 'Memorized', :quantity => gospel_memorized, :task => "Memorize #{gospel_memorized} verses from the gospels.")
  end  

  # Epistle quests
  q = Quest.where(:level => i, :objective => 'Epistles', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Epistles', :qualifier => 'Learning', :quantity => epistle_learning, :task => "Learn #{epistle_learning} verses from the epistles.")
  end  

  q = Quest.where(:level => i, :objective => 'Epistles', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Epistles', :qualifier => 'Memorized', :quantity => epistle_memorized, :task => "Memorize #{epistle_memorized} verses from the epistles.")
  end  
  
  # Wisdom quests
  q = Quest.where(:level => i, :objective => 'Wisdom', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Wisdom', :qualifier => 'Learning', :quantity => wisdom_learning, :task => "Learn #{wisdom_learning} verses from the wisdom literature.")
  end  

  q = Quest.where(:level => i, :objective => 'Wisdom', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Wisdom', :qualifier => 'Memorized', :quantity => wisdom_memorized, :task => "Memorize #{wisdom_memorized} verses from the wisdom literature.")
  end  
  
  # History quests
  q = Quest.where(:level => i, :objective => 'History', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'History', :qualifier => 'Learning', :quantity => history_learning, :task => "Learn #{history_learning} verses of biblical history.")
  end  

  q = Quest.where(:level => i, :objective => 'History', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'History', :qualifier => 'Memorized', :quantity => history_memorized, :task => "Memorize #{history_memorized} verses of biblical history.")
  end  
  
  # Prophecy quests
  q = Quest.where(:level => i, :objective => 'Prophecy', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Prophecy', :qualifier => 'Learning', :quantity => prophecy_learning, :task => "Learn #{prophecy_learning} verses of biblical prophecy.")
  end  

  q = Quest.where(:level => i, :objective => 'Prophecy', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Prophecy', :qualifier => 'Memorized', :quantity => prophecy_memorized, :task => "Memorize #{prophecy_memorized} verses of biblical prophecy.")
  end
  
  # Reference recall       
  q = Quest.where(:level => i, :objective => 'References')
  if q.empty?
    Quest.create(:level => i, :objective => 'References', :quantity => ref_recall, :task => "Recall #{ref_recall}% of your references.")
  end  
  
  # Accuracy test       
  q = Quest.where(:level => i, :objective => 'Accuracy')
  if q.empty?
    Quest.create(:level => i, :objective => 'Accuracy', :quantity => accuracy, :task => "Increase your accuracy test score to #{accuracy}%.")
  end    
  
  # Tags       
  q = Quest.where(:level => i, :objective => 'Tags')
  if q.empty?
    Quest.create(:level => i, :objective => 'Tags', :quantity => tags, :task => "Tag #{tags} of your memory verses.")
  end   
  
  # Referrals       
  q = Quest.where(:level => i, :objective => 'Referrals')
  if q.empty?
    Quest.create(:level => i, :objective => 'Referrals', :quantity => referrals, :task => "Refer #{referrals} active users to Memverse", :description => "To count, referred users must be active. Remember that people they refer also count toward your score.")
  end 
  
  # Chapter quests
  q = Quest.where(:level => i, :objective => 'Chapters', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Chapters', :qualifier => 'Learning', :quantity => chapters_learning, :task => "Learn #{chapters_learning} complete chapters.")
  end
  
  q = Quest.where(:level => i, :objective => 'Chapters', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Chapters', :qualifier => 'Memorized', :quantity => chapters_memorized, :task => "Memorize #{chapters_memorized} complete chapters.")
  end    
end

puts 'ADDING FINAL VERSE DATA'

# Delete previous table
FinalVerse.delete_all

BIBLEBOOKS.each { |bk|

  sleep(1)

  book = bk.downcase.gsub(" ","")

  url = 'http://www.deafmissions.com/tally/' + CGI.escape(book) + '.html'
  doc = Nokogiri::HTML(open(url))

  ch_vs_array = doc.at_css("tr").to_s.gsub(/<\/?[^>]*>/, "").split    
  # Need this from Daniel onwards
  if ch_vs_array.empty?
    ch_vs_array = doc.at_css("blockquote center").to_s.gsub(/<\/?[^>]*>/, "").split  
  end

  ch_vs_array.each { |cv| 

    ch, vs = cv.split(':')

    if ch.to_i == 0
      ch = CGI.escape(ch).gsub("%C2%A0","").to_i  # handle nbsp characters in a few chapters in Psalms
    end

    FinalVerse.create(:book => bk, :chapter => ch.to_i, :last_verse => vs.to_i )

  }

}
