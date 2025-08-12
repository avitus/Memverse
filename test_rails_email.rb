# Test Rails mailer with memverse.com email
user = User.find_by(email: "admin@memverse.com") || User.new(
  email: "admin@memverse.com", 
  name: "Admin User",
  login: "admin"
)

puts "Testing email to: #{user.email}"
puts "Delivery method: #{ActionMailer::Base.delivery_method}"
puts "Perform deliveries: #{ActionMailer::Base.perform_deliveries}"

begin
  mail = UserMailer.signup_notification(user)
  result = mail.deliver_now
  
  puts "\nEmail sent successfully!"
  puts "Message ID: #{result.message_id}"
  puts "Subject: #{result.subject}"
  puts "Tag: #{result.tag}"
  puts "Message Stream: #{result.message_stream}"
  
  # Check if Postmark response is available
  if result.respond_to?(:postmark_response)
    puts "Postmark Response: #{result.postmark_response}"
  end
  
rescue => e
  puts "\nError sending email: #{e.class} - #{e.message}"
  puts e.backtrace.first(10).join("\n")
end