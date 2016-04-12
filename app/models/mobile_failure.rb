class MobileFailure < Devise::FailureApp
  def respond
    self.status 		= 401
    self.content_type 	= 'json'
    self.response_body	= {"errors" => ["Invalid credentials"]}.to_json
  end 
end