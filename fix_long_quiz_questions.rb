# Script to find and fix quiz questions that are too long
# Run with: bundle exec rails runner fix_long_quiz_questions.rb

puts "Finding quiz questions with mc_question longer than 300 characters..."
puts "=" * 60

long_questions = QuizQuestion.where("LENGTH(mc_question) > 300")

if long_questions.empty?
  puts "No questions found with mc_question longer than 300 characters."
  exit
end

puts "Found #{long_questions.count} questions that are too long:"
puts

long_questions.each_with_index do |question, index|
  chars_over = question.mc_question.length - 300
  puts "#{index + 1}. Question ID: #{question.id}"
  puts "   Category: #{question.mcq_category}"
  puts "   Current length: #{question.mc_question.length} characters (#{chars_over} characters over limit)"
  puts "   Must remove at least: #{chars_over} characters"
  puts "   Question preview: #{question.mc_question[0..150]}..."
  puts "   Full question: #{question.mc_question}"
  puts "   " + "-" * 80
  puts
end

print "\nDo you want to truncate these questions to 295 characters? (y/n): "
response = STDIN.gets.chomp.downcase

if response == 'y'
  long_questions.each do |question|
    original = question.mc_question
    truncated = original[0..294] + "..."

    # Skip validation to force the update
    question.update_column(:mc_question, truncated)

    puts "Updated Question ID #{question.id}:"
    puts "  Original (#{original.length} chars): #{original[0..100]}..."
    puts "  Truncated (#{truncated.length} chars): #{truncated[0..100]}..."
    puts
  end

  puts "Successfully truncated #{long_questions.count} questions."
else
  puts "No changes made."
end

# Also check for approved MCQ questions to see what the quiz will use
puts "\n" + "=" * 60
puts "Checking approved MCQ questions..."
approved_mcq = QuizQuestion.mcq.approved
puts "Total approved MCQ questions: #{approved_mcq.count}"

# Check if any approved questions are still too long
long_approved = approved_mcq.where("LENGTH(mc_question) > 300")
if long_approved.any?
  puts "WARNING: #{long_approved.count} approved MCQ questions are still too long!"
else
  puts "All approved MCQ questions are within the 300 character limit."
end