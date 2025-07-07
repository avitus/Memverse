Feature: Forum Home Page
  In order to participate in community discussions
  A user
  Should be able to visit the forum home page

  Background:
    Given I am not logged in

  Scenario: User visits forum home page
    When I navigate to the forum home page
    Then I should see "Forums"
    And I should see "Messageboards"

  Scenario: User visits forum home page while logged in
    Given I sign in as a normal user
    When I navigate to the forum home page
    Then I should see "Forums"
    And I should see "Messageboards"
    And I should see "New Topic"

  Scenario: Admin user visits forum home page
    Given I sign in as an admin user
    When I navigate to the forum home page
    Then I should see "Forums"
    And I should see "Messageboards"
    And I should see "New Topic"
    And I should see "Admin" 