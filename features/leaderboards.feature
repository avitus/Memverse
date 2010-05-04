Feature: Leaderboards
  In order to show off cucumber with capybara
  As a Ruby developer
  I want to run some scenarios with different browser simulators
  
  Scenario: Displaying countryboard
	Given I go to the countryboard page
    Then I should see "South Africa"
    And I should see "United States"

  Scenario: Displaying leaderboard
	Given I go to the leaderboard page
    Then I should see "Andy"
    
  Scenario: Displaying stateboard
	Given I go to the stateboard page
    Then I should see "California"    
