namespace :quiz do
  desc "Check quiz status in Redis"
  task check_status: :environment do
    quiz_id = ENV['QUIZ_ID'] || 1
    quiz_session = QuizSession.new(quiz_id)
    
    puts "Quiz ID: #{quiz_id}"
    puts "Quiz Status: #{quiz_session.get_quiz_status}"
    puts "Quiz Running?: #{quiz_session.quiz_in_progress?}"
    puts "Quiz Locked?: #{quiz_session.quiz_locked?}"
    puts "Quiz Metadata: #{quiz_session.get_quiz_metadata}"
    
    # Check Redis keys directly
    redis_key = "quiz_session:#{quiz_id}:status"
    puts "\nDirect Redis check:"
    puts "Status key exists?: #{$redis.exists(redis_key)}"
    puts "Status hash: #{$redis.hgetall(redis_key).inspect}"
    
    # Check legacy keys that might interfere
    legacy_key = "quiz-bible-knowledge"
    puts "\nLegacy key check:"
    puts "Legacy key exists?: #{$redis.exists(legacy_key)}"
    puts "Legacy hash: #{$redis.hgetall(legacy_key).inspect}"
  end
  
  desc "Clear quiz status in Redis"
  task clear_status: :environment do
    quiz_id = ENV['QUIZ_ID'] || 1
    quiz_session = QuizSession.new(quiz_id)
    
    puts "Clearing status for Quiz ID: #{quiz_id}"
    
    # Clear using QuizSession methods
    quiz_session.cleanup_quiz_data
    quiz_session.cleanup_legacy_data
    quiz_session.set_quiz_status("Available")
    
    puts "Quiz status cleared and set to 'Available'"
    puts "New status: #{quiz_session.get_quiz_status}"
  end
end