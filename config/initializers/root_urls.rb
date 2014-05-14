DOMAIN_NAMES = {"staging" => "https://staging.memverse.com", "development" => "http://localhost:3000", "production" =>  "https://www.memverse.com", "test" => "http://localhost:3000"}
DOMAIN_NAME = DOMAIN_NAMES[Rails.env]
