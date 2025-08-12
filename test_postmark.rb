# Test Postmark connection directly
require 'net/http'
require 'uri'
require 'json'

api_token = '6b4a7191-6750-46e4-95d9-72ad17c45156'

# Test the API token by getting server info
uri = URI.parse("https://api.postmarkapp.com/server")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Get.new(uri.request_uri)
request['X-Postmark-Server-Token'] = api_token
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'

begin
  response = http.request(request)
  puts "Response Code: #{response.code}"
  puts "Response Body: #{response.body}"
  
  if response.code == '200'
    server_info = JSON.parse(response.body)
    puts "\nServer Name: #{server_info['Name']}"
    puts "Server ID: #{server_info['ID']}"
    puts "Inbound Domain: #{server_info['InboundDomain']}"
  end
rescue => e
  puts "Error: #{e.message}"
end