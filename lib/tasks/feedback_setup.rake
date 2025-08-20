namespace :feedback do
  desc "Setup feedback messageboard in Thredded forum"
  task setup: :environment do
    puts "Setting up feedback messageboard..."
    
    # Create feedback messageboard if it doesn't exist
    feedback_board = Thredded::Messageboard.find_or_create_by(slug: 'feedback') do |board|
      board.name = 'Feedback & Feature Requests'
      board.description = 'Share your ideas for new features, report bugs, and vote on suggestions from other users. The most popular requests will be prioritized!'
      board.position = 1  # Put it at the top
    end
    
    puts "✓ Created feedback messageboard: #{feedback_board.name}"
    
    # Create categories for the feedback board
    categories = [
      { name: 'Feature Request', description: 'Suggest new features for Memverse' },
      { name: 'Bug Report', description: 'Report issues and problems' },
      { name: 'Improvement', description: 'Suggest improvements to existing features' }
    ]
    
    categories.each do |cat_data|
      category = feedback_board.categories.find_or_create_by(name: cat_data[:name]) do |cat|
        cat.description = cat_data[:description]
      end
      puts "✓ Created category: #{category.name}"
    end
    
    # Skip welcome topic creation for now - can be added manually later
    puts "\n[INFO] Skipping welcome topic creation due to Thredded validation requirements"
    puts "       You can manually create a welcome topic through the web interface"
    
    puts "\n[SUCCESS] Feedback messageboard setup complete!"
    puts "\nTo integrate voting into your Thredded views:"
    puts "1. Run: bundle install"
    puts "2. Run: rails generate acts_as_votable:migration"
    puts "3. Run: rails db:migrate"
    puts "4. Add to your Thredded topic views:"
    puts "   <%= thredded_topic_voting(topic) %>"
    puts "\nVisit /forum/feedback to see the new board!"
  end
  
  desc "Show voting statistics for feedback topics"
  task stats: :environment do
    feedback_board = Thredded::Messageboard.find_by(slug: 'feedback')
    
    if feedback_board
      puts "\nFeedback Board Statistics:"
      puts "=" * 50
      
      topics = feedback_board.topics.includes(:categories)
      puts "Total topics: #{topics.count}"
      
      # Sort by votes
      topics_with_votes = topics.map do |topic|
        {
          topic: topic,
          score: topic.vote_score,
          upvotes: topic.get_upvotes.size,
          downvotes: topic.get_downvotes.size
        }
      end.sort_by { |t| -t[:score] }
      
      puts "\nTop 10 Most Voted Topics:"
      puts "-" * 50
      topics_with_votes.first(10).each_with_index do |data, index|
        topic = data[:topic]
        puts "#{index + 1}. [#{data[:score]} votes] #{topic.title}"
        puts "   ↑ #{data[:upvotes]} | ↓ #{data[:downvotes]} | Category: #{topic.categories.first&.name || 'None'}"
      end
    else
      puts "Feedback messageboard not found. Run 'rake feedback:setup' first."
    end
  end
end