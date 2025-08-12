# Test sending email through Postmark
require 'net/http'
require 'uri'
require 'json'

api_token = '6b4a7191-6750-46e4-95d9-72ad17c45156'

# Your email address for testing
puts "Enter your email address to receive the test email:"
test_email = gets.chomp

if test_email.empty?
  puts "No email provided, using default"
  test_email = "test@example.com"
end

# Send test email
uri = URI.parse("https://api.postmarkapp.com/email")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

email_data = {
  "From" => "admin@memverse.com",
  "To" => test_email,
  "Subject" => "Test Email from Memverse Development",
  "TextBody" => "This is a test email from your Memverse development environment. If you received this, Postmark is working correctly!",
  "HtmlBody" => "<p>This is a test email from your Memverse development environment.</p><p>If you received this, <strong>Postmark is working correctly!</strong></p>",
  "MessageStream" => "outbound",
  "Tag" => "test-email"
}

request = Net::HTTP::Post.new(uri.request_uri)
request['X-Postmark-Server-Token'] = api_token
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'
request.body = email_data.to_json

begin
  response = http.request(request)
  puts "\nResponse Code: #{response.code}"
  puts "Response Body: #{response.body}"
  
  if response.code == '200'
    result = JSON.parse(response.body)
    puts "\nSuccess! Email sent to: #{result['To']}"
    puts "Message ID: #{result['MessageID']}"
  else
    puts "\nError sending email!"
  end
rescue => e
  puts "Error: #{e.message}"
end