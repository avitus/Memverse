# coding: utf-8
class MobileFailure < Devise::FailureApp

  # You need to override respond to eliminate recall
  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end

  def mobile_failure
    self.status 		= 401
    self.content_type 	= 'json'
    self.response_body	= {"errors" => ["Invalid credentials"]}.to_json
  end 

end
