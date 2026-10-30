Feature: Post a forum topic
  In order to give feedback to the Memverse team
  A user
  Should be able to start a topic on the feedback board

  Background:
    Given I have a user account
    And there is a feedback messageboard
    And I have completed enough memorization sessions to post on the forum
    And I am logged in

  Scenario: User starts a new topic on the feedback board
    When I go to the new feedback topic page
    And I fill in "topic_title" with "Please add a dark mode"
    And I fill in "topic_content" with "Reviewing verses at night would be easier on the eyes."
    And I press "Create New Topic"
    Then I should see "Please add a dark mode"
    When I follow "Please add a dark mode"
    Then I should see "Reviewing verses at night would be easier on the eyes."
    And the feedback board should contain the topic "Please add a dark mode"
