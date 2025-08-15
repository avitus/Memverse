namespace :quiz do
  desc "Export 25 Knowledge Quiz questions to SQL dump"
  task export_knowledge_questions: :environment do
    # Select questions using exact Knowledge Quiz algorithm
    questions = QuizQuestion
      .where(quiz_id: 1)
      .mcq
      .approved
      .order(:last_asked, :id)
      .limit(25)
    
    # Generate SQL dump file
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "knowledge_quiz_questions_#{timestamp}.sql"
    filepath = Rails.root.join('db', 'data_exports', filename)
    
    # Create directory if it doesn't exist
    FileUtils.mkdir_p(Rails.root.join('db', 'data_exports'))
    
    File.open(filepath, 'w') do |file|
      # Write header
      file.puts "-- Knowledge Quiz Questions Export"
      file.puts "-- Generated: #{Time.current}"
      file.puts "-- Database: #{Rails.env}"
      file.puts "-- Count: #{questions.count} questions"
      file.puts "-- Selection: MCQ, Approved, ordered by last_asked (oldest first)"
      file.puts ""
      file.puts "-- Disable foreign key checks"
      file.puts "SET FOREIGN_KEY_CHECKS=0;"
      file.puts ""
      file.puts "-- Clear existing Knowledge Quiz MCQ questions if needed"
      file.puts "-- DELETE FROM quiz_questions WHERE quiz_id = 1 AND question_type = 'mcq';"
      file.puts ""
      file.puts "-- Insert questions"
      
      questions.each_with_index do |q, index|
        # Escape special characters for SQL
        def sql_escape(str)
          return 'NULL' if str.nil?
          "'#{str.to_s.gsub("'", "''").gsub("\n", "\\n").gsub("\r", "\\r")}'"
        end
        
        file.puts "-- Question #{index + 1}/25 (ID: #{q.id}, Last Asked: #{q.last_asked || 'Never'})"
        file.puts "INSERT INTO quiz_questions ("
        file.puts "  id, quiz_id, question_no, question_type, passage,"
        file.puts "  mc_question, mc_option_a, mc_option_b, mc_option_c, mc_option_d, mc_answer,"
        file.puts "  times_answered, perc_correct, mcq_category, last_asked,"
        file.puts "  supporting_ref, submitted_by, approval_status, rejection_code,"
        file.puts "  created_at, updated_at"
        file.puts ") VALUES ("
        file.puts "  #{q.id}, #{q.quiz_id}, #{q.question_no || 'NULL'}, #{sql_escape(q.question_type)}, #{sql_escape(q.passage)},"
        file.puts "  #{sql_escape(q.mc_question)}, #{sql_escape(q.mc_option_a)}, #{sql_escape(q.mc_option_b)}, #{sql_escape(q.mc_option_c)}, #{sql_escape(q.mc_option_d)}, #{sql_escape(q.mc_answer)},"
        file.puts "  #{q.times_answered}, #{q.perc_correct}, #{sql_escape(q.mcq_category)}, #{sql_escape(q.last_asked)},"
        file.puts "  #{q.supporting_ref || 'NULL'}, #{q.submitted_by || 'NULL'}, #{sql_escape(q.approval_status)}, #{sql_escape(q.rejection_code)},"
        file.puts "  #{sql_escape(q.created_at)}, #{sql_escape(q.updated_at)}"
        file.puts ") ON DUPLICATE KEY UPDATE"
        file.puts "  mc_question = VALUES(mc_question),"
        file.puts "  mc_option_a = VALUES(mc_option_a),"
        file.puts "  mc_option_b = VALUES(mc_option_b),"
        file.puts "  mc_option_c = VALUES(mc_option_c),"
        file.puts "  mc_option_d = VALUES(mc_option_d),"
        file.puts "  mc_answer = VALUES(mc_answer),"
        file.puts "  times_answered = VALUES(times_answered),"
        file.puts "  perc_correct = VALUES(perc_correct),"
        file.puts "  last_asked = VALUES(last_asked);"
        file.puts ""
      end
      
      # Write footer
      file.puts "-- Re-enable foreign key checks"
      file.puts "SET FOREIGN_KEY_CHECKS=1;"
      file.puts ""
      file.puts "-- Summary"
      file.puts "SELECT 'Import complete!' AS status,"
      file.puts "       COUNT(*) AS total_mcq_questions"
      file.puts "FROM quiz_questions"
      file.puts "WHERE quiz_id = 1 AND question_type = 'mcq' AND approval_status = 'Approved';"
      file.puts ""
      file.puts "-- End of export"
    end
    
    puts "✅ Exported #{questions.count} questions to: #{filepath}"
    puts "\nQuestion Summary:"
    puts "=================="
    puts "Total questions: #{questions.count}"
    puts "Difficulty breakdown:"
    puts "  Easy (66-100%): #{questions.where(perc_correct: 66..100).count}"
    puts "  Medium (34-65%): #{questions.where(perc_correct: 34..65).count}"
    puts "  Hard (0-33%): #{questions.where(perc_correct: 0..33).count}"
    puts "\nLast asked dates:"
    puts "  Never asked: #{questions.where(last_asked: nil).count}"
    puts "  > 6 months ago: #{questions.where('last_asked < ?', 6.months.ago).count}"
    puts "  3-6 months ago: #{questions.where(last_asked: 6.months.ago..3.months.ago).count}"
    puts "  < 3 months ago: #{questions.where('last_asked > ?', 3.months.ago).count}"
    puts "\nTo import to another database:"
    puts "mysql -u [username] -p [database] < #{filepath}"
  end
  
  desc "Export quiz questions as JSON for easier transport"
  task export_knowledge_questions_json: :environment do
    questions = QuizQuestion
      .where(quiz_id: 1)
      .mcq
      .approved
      .order(:last_asked, :id)
      .limit(25)
    
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "knowledge_quiz_questions_#{timestamp}.json"
    filepath = Rails.root.join('db', 'data_exports', filename)
    
    FileUtils.mkdir_p(Rails.root.join('db', 'data_exports'))
    
    export_data = {
      metadata: {
        exported_at: Time.current,
        environment: Rails.env,
        count: questions.count,
        selection_criteria: "MCQ, Approved, ordered by last_asked (oldest first)"
      },
      questions: questions.map do |q|
        {
          id: q.id,
          quiz_id: q.quiz_id,
          question_no: q.question_no,
          question_type: q.question_type,
          passage: q.passage,
          mc_question: q.mc_question,
          mc_option_a: q.mc_option_a,
          mc_option_b: q.mc_option_b,
          mc_option_c: q.mc_option_c,
          mc_option_d: q.mc_option_d,
          mc_answer: q.mc_answer,
          times_answered: q.times_answered,
          perc_correct: q.perc_correct,
          mcq_category: q.mcq_category,
          last_asked: q.last_asked,
          supporting_ref: q.supporting_ref,
          submitted_by: q.submitted_by,
          approval_status: q.approval_status,
          rejection_code: q.rejection_code,
          created_at: q.created_at,
          updated_at: q.updated_at
        }
      end
    }
    
    File.write(filepath, JSON.pretty_generate(export_data))
    
    puts "✅ Exported #{questions.count} questions to: #{filepath}"
  end
end