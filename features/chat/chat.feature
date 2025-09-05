Feature: Chat functionality
  As a user of Memverse
  I want to participate in chat discussions
  So that I can communicate with other users in real-time

  Background:
    Given I am a user named "TestUser" with an email "testuser@test.com" and password "password"
    And I am an admin named "AdminUser" with an email "admin@test.com" and password "adminpass"

  Scenario: User can access chat when logged in
    Given I am signed in as "testuser"
    When I go to the chat page
    Then I should see "Memverse Chat"
    And I should see a message input field
    And I should see a "Send" button

  Scenario: User cannot access chat when not logged in
    Given I am not signed in
    When I go to the chat page
    Then I should be redirected to the sign in page

  Scenario: User can access specific chat channel
    Given I am signed in as "testuser"
    When I go to the chat page for channel 5
    Then I should see "Memverse Chat"
    And the page should load the correct channel

  Scenario: Sending messages requires authentication
    Given I am not signed in
    When I try to send a chat message via AJAX
    Then I should get a 401 unauthorized response

  Scenario: Admin can toggle channel status
    Given I am signed in as "admin"
    And the admin has quiz management permissions
    When I toggle the chat channel status
    Then the channel status should change
    And I should receive a JSON response with the new status

  Scenario: Admin can ban users from chat
    Given I am signed in as "admin" 
    And the admin has quiz management permissions
    And user "testuser" exists
    When I ban user "testuser" from chat
    Then user "testuser" should be banned from chat
    And I should receive a JSON response confirming the ban

  Scenario: Admin can unban users from chat
    Given I am signed in as "admin"
    And the admin has quiz management permissions  
    And user "testuser" is banned from chat
    When I unban user "testuser" from chat
    Then user "testuser" should not be banned from chat
    And I should receive a JSON response confirming the unban

  Scenario: Non-admin users cannot ban/unban users
    Given I am signed in as "testuser"
    When I try to ban user "admin" from chat
    Then I should receive a JSON response with no status change

  Scenario: Chat page displays user information correctly
    Given I am signed in as "testuser"
    When I go to the chat page
    Then the page should contain my user ID in JavaScript variables
    And the page should contain my username in JavaScript variables
    And the page should contain my avatar URL in JavaScript variables

  Scenario: Chat channel status affects message sending
    Given I am signed in as "testuser"
    And the chat channel is closed
    When I try to send a message "Hello everyone"
    Then the message should not be published to PubNub
    And the system should log that the channel is closed

  Scenario: Banned users cannot send messages
    Given I am signed in as "testuser"
    And user "testuser" is banned from chat
    When I try to send a message "Hello everyone" 
    Then the message should not be published to PubNub
    And the system should log that the user is banned