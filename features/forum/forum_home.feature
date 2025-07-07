Feature: Forum Home Page
  In order to participate in community discussions
  A user
  Should be able to visit the forum home page

  Background:
    Given I sign in as a normal user

  Scenario: User visits forum home page
    When I navigate to the forum home page
    Then I should see "Forums"
    And I should see "Messageboards"
