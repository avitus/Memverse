# Test email delivery script
user = User.first || User.new(email: "test@example.com", name: "Test User")

puts "Testing email to: #{user.email}"
puts "Delivery method: #{ActionMailer::Base.delivery_method}"
puts "Postmark settings: #{ActionMailer::Base.postmark_settings.inspect}"

begin
  mail = UserMailer.signup_notification(user)
  result = mail.deliver_now
  puts "Email sent successfully!"
  puts "Message ID: #{result.message_id}"
  puts "Response: #{result.inspect}"
rescue => e
  puts "Error sending email: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end