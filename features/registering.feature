Feature: Registering	
  In order to register
  As a user
  I want to see a welcome message

  Scenario: Registering as a new user
    
    Given I am on the signup page
     
    When I register as "demo" with email "demo@test.com" and password "secret"
    
    Then I should see "Thanks for signing up"

  
