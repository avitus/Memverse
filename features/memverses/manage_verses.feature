Feature: Manage verses
  In order to manage my memorized verses
  As a user
  I want to be able to view, sort, and manage my verses

  Background:
    Given the following verses exist:
      | book_index | book         | chapter | versenum | text                                    | translation |
      | 43         | John         | 3       | 16       | For God so loved the world...          | NIV         |
      | 45         | Romans       | 8       | 28       | And we know that in all things...      | NIV         |
      | 50         | Philippians  | 4       | 13       | I can do all things through Christ...  | NIV         |
    And I sign in as a normal user
    And I have the following memory verses:
      | verse_ref          | status    | efactor | next_test   |
      | John 3:16          | Learning  | 2.5     | 2 days      |
      | Romans 8:28        | Memorized | 2.8     | 10 days     |
      | Philippians 4:13   | Pending   | 2.5     | N/A         |

  Scenario: User views their verses
    When I go to the manage verses page
    Then I should see "John 3:16"
    And I should see "Romans 8:28"
    And I should see "Philippians 4:13"
    And I should see "Learning"
    And I should see "Memorized"
    And I should see "Pending"

  Scenario: User with no verses sees appropriate message
    Given I have no memory verses
    When I go to the manage verses page
    Then I should see "You do not have any verses in your account"
    And I should see "Please add some verses by clicking here"

  @javascript
  Scenario: User sorts verses by status
    When I go to the manage verses page
    And I click "Status"
    Then the verses should be sorted by status

  @javascript
  Scenario: User sorts verses by next test date
    When I go to the manage verses page
    And I click "Next Test"
    Then the verses should be sorted by next test date

  @javascript
  Scenario: User selects and shows a single verse
    When I go to the manage verses page
    And I check the verse "John 3:16"
    And I press "Show Selected"
    Then I should be on the memory verse page for "John 3:16"

  @javascript
  Scenario: User selects and deletes verses
    When I go to the manage verses page
    And I check the verse "John 3:16"
    And I check the verse "Romans 8:28"
    And I press "Delete Selected"
    Then I should see /(?i)MEMORY VERSES HAVE BEEN DELETED/
    And I should not see "John 3:16"
    And I should not see "Romans 8:28"
    But I should see "Philippians 4:13"

  @javascript
  Scenario: User tries to show verses without selecting any
    When I go to the manage verses page
    And I press "Show Selected"
    Then I should see an alert with "No verses are selected"

  @javascript
  Scenario: User filters verses
    When I go to the manage verses page
    And I click inside "#searchico"
    And I fill in "filter" with "John"
    Then I should see "John 3:16"
    But I should not see "Romans 8:28"
    And I should not see "Philippians 4:13"