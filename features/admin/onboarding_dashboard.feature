Feature: Admin Onboarding Dashboard
  As an admin user
  I want to view and analyze new user onboarding
  So that I can improve user retention and engagement

  Background:
    Given I am logged in as an admin user
    And the following users exist:
      | name        | email                  | created_at | confirmed_at | progression | memorized | translation |
      | New User 1  | newuser1@example.com   | 2 days ago | 1 day ago    | 5          | 2         | NIV         |
      | New User 2  | newuser2@example.com   | 5 days ago | 4 days ago   | 3          | 0         | ESV         |
      | New User 3  | newuser3@example.com   | 10 days ago| nil          | 1          | 0         | nil         |
      | Unengaged   | unengaged@example.com  | 7 days ago | 6 days ago   | 2          | 0         | NIV         |
      | Old User    | olduser@example.com    | 29 days ago| 28 days ago  | 9          | 50        | KJV         |

  Scenario: Viewing the onboarding dashboard
    When I visit the admin dashboard
    And I click on "User Onboarding"
    Then I should see "New User Onboarding Dashboard"
    And I should see "4" new users in the past 14 days
    And I should not see "Old User"
    And I should see the following metrics:
      | metric              | value |
      | Total New Users     | 4     |
      | Activation Rate     | 75.0% |
      | Engagement Rate     | 50.0% |

  Scenario: Filtering users by progression level
    When I visit the admin dashboard
    And I click on "User Onboarding"
    When I select "engaged" from the "progression_level" dropdown
    And I press "Apply Filters"
    Then I should see "New User 1"
    And I should not see "New User 2"
    And I should not see "New User 3"

  Scenario: Filtering users by email confirmation status
    When I visit the admin dashboard
    And I click on "User Onboarding"
    When I select "unconfirmed" from the "email_status" dropdown
    And I press "Apply Filters"
    Then I should see "New User 3"
    And I should not see "New User 1"
    And I should not see "New User 2"

  Scenario: Viewing detailed user information
    When I visit the admin dashboard
    And I click on "User Onboarding"
    When I click "View" for "New User 1"
    Then I should see "User Onboarding Details: New User 1"
    And I should see "Progression Level:"
    And I should see "newuser1@example.com"
    And I should see "Translation: NIV"
    And I should see "Memorized: 2"

  Scenario: Exporting users to CSV
    When I visit the admin dashboard
    And I click on "User Onboarding"
    When I follow "Export CSV"
    Then I should receive a CSV file
    And the CSV should contain "New User 1"
    And the CSV should contain "newuser1@example.com"
    And the CSV should not contain "Old User"

  Scenario: Sending emails to unengaged users
    When I visit the admin dashboard
    And I click on "User Onboarding"
    And there are unengaged users who need reminders
    When I follow "Email Unengaged"
    And I confirm the action
    Then reminder emails should be sent to unengaged users

  Scenario: Accessing admin dashboard as non-admin
    Given I am logged in as a regular user
    When I try to visit the admin onboarding dashboard
    Then I should be redirected to the home page
    And I should see the admin access error

  Scenario: Changing date range
    When I visit the admin dashboard
    And I click on "User Onboarding"
    When I select "30" from the "date_range" dropdown
    And I press "Apply Filters"
    Then I should see "6" new users
    And I should see "Old User"

  @javascript
  Scenario: Admin navigation menu
    Given I am on the home page
    Then I should see "Admin" in the main navigation
    When I hover over "Admin"
    Then I should see the following admin menu items:
      | Dashboard         |
      | User Onboarding   |
      | Database Admin    |
      | Background Jobs   |
      | Quiz Management   |