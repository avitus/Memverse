Feature: Earn badges
  In order to have a feeling of achievement
  A user
  Should be able to earn badges
  
  Background:
  	Given I am a 
    Given I have completed 300 memorization sessions in the past year
    Given I have 10 verses in my list
     
    @javascript
    Scenario: User completes final session required to earn silver consistency badge
      Given I sign in as a normal user
      When I complete a memorization session
      Then I should see "Congratulations"
      
