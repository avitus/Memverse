Feature: Forum Voting System
  As a Memverse user
  I want to vote on feedback topics
  So that the most requested features get priority

  Background:
    Given I have a user account
    And there is a feedback messageboard
    And the following feedback topics exist:
      | title                    | author | votes_up | votes_down |
      | Add dark mode           | user1  | 5        | 1          |
      | Mobile app development  | user2  | 3        | 0          |
      | Export to PDF           | user1  | 1        | 2          |
      | Improve search feature  | user3  | 0        | 0          |

  @javascript
  Scenario: Anonymous user sees voting interface but cannot vote
    When I visit the feedback board
    Then I should see vote counts on topics
    When I click on the topic "Add dark mode"
    Then I should see "Login to vote"
    And I should not see voting buttons

  @javascript
  Scenario: Logged in user can upvote a topic
    Given I am logged in
    When I visit the feedback board
    And I click on the topic "Mobile app development"
    Then I should see the vote score is "3"
    When I click the upvote button
    Then I should see the vote score is "4"
    And the upvote button should be highlighted
    And I should see "remove vote"

  @javascript
  Scenario: Logged in user can downvote a topic
    Given I am logged in
    When I visit the feedback board
    And I click on the topic "Export to PDF"
    Then I should see the vote score is "-1"
    When I click the downvote button
    Then I should see the vote score is "-2"
    And the downvote button should be highlighted

  @javascript
  Scenario: User can change their vote
    Given I am logged in
    And I have upvoted "Add dark mode"
    When I visit the topic "Add dark mode"
    Then the upvote button should be highlighted
    When I click the downvote button
    Then I should see the vote score is "3"
    And the downvote button should be highlighted
    And the upvote button should not be highlighted

  @javascript
  Scenario: User can remove their vote
    Given I am logged in
    When I visit the topic "Export to PDF" 
    Then I should see the vote score is "-1"
    When I click the downvote button
    Then I should see the vote score is "-2"
    And I should see "remove vote"
    When I remove my vote
    Then I should see the vote score is "-1"
    And I should not see "remove vote"
    And no vote buttons should be highlighted

  @javascript
  Scenario: Topics can be sorted by vote count
    Given I am logged in
    When I visit the feedback board
    Then I should see topics in order:
      | Add dark mode          |
      | Mobile app development |
      | Improve search feature |
      | Export to PDF          |
    When I follow "Most Votes"
    Then I should see topics in order:
      | Add dark mode          |
      | Mobile app development |
      | Export to PDF          |
      | Improve search feature |

  Scenario: Vote badges show in topic list
    When I visit the feedback board
    Then I should see "+4 votes" for "Add dark mode"
    And I should see "+3 votes" for "Mobile app development"
    And I should see "-1 votes" for "Export to PDF"
    And I should not see a vote badge for "Improve search feature"

  @javascript
  Scenario: Voting is restricted to feedback board
    Given I am logged in
    And there is a general discussion board
    And there is a topic "General question" in the general board
    When I visit the topic "General question" in the general board
    Then I should not see voting interface
    When I visit the general discussion board
    Then I should not see vote badges

  @javascript
  Scenario: Multiple users can vote on the same topic
    Given I am logged in as "voter1"
    When I visit the topic "Improve search feature"
    And I click the upvote button
    Then I should see the vote score is "1"
    When I log out
    And I log in as "voter2"
    And I visit the topic "Improve search feature"
    And I click the upvote button
    Then I should see the vote score is "2"

  @javascript
  Scenario: Vote persistence across sessions
    Given I am logged in
    When I visit the topic "Add dark mode"
    And I click the downvote button
    Then I should see the vote score is "3"
    When I log out
    And I log in again
    And I visit the topic "Add dark mode"
    Then I should see the vote score is "3"
    And the downvote button should be highlighted