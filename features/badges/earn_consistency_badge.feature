Feature: Earn badges
  In order to have a feeling of achievement
  A user
  Should be able to earn badges
  
  Background:
  	Given I sign in as an advanced user
    Given I have completed 300 memorization sessions in the past year
     
    @javascript
    Scenario: User completes final session required to earn silver consistency badge
      Given I sign in as a normal user
      When I complete a memorization session
      Then I should see "Congratulations"
      
