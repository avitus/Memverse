Feature: Earn badges
  In order to have a feeling of achievement
  A user
  Should be able to earn badges
  
  Background:
  	Given I sign in as an advanced user
     
    @javascript
    Scenario: User completes final session required to earn silver consistency badge
      Given the user with the email of "advanced_user@test.com" has completed 324 memorization sessions in the past year
      When the user with the email of "advanced_user@test.com" completes a memorization session
      Then I should see "Congratulations"
      When I go to the home page
      When I follow "Dashboard"
      Then I should see "advanced has been awarded a silver Consistency badge"
      When I go to the progress page
      Then I should not see "Congratulations"
      