Feature: Review a verse
  In order to move a verse into long-term memory
  A user
  Should see their rating of a review reschedule the verse

  Background:
    Given the following verses exist:
      | book_index | book | chapter | versenum | text                           | translation |
      | 43         | John | 3       | 16       | For God so loved the world...  | NIV         |
    And I sign in as a normal user
    And I have the following memory verses:
      | verse_ref | status   | efactor | next_test |
      | John 3:16 | Learning | 2.0     | 0 days    |

  Scenario: A good rating pushes the next review into the future
    When I rate the verse "John 3:16" with a 4
    Then the verse "John 3:16" should next be tested 4 days from today
    And the verse "John 3:16" should have a repetition count of 2
    When I go to the main memorization page
    Then I should be on the progress page
    And I should see "You have no more verses to memorize today. Your next memory verse is due for review in 4 days."

  Scenario: A failed rating restarts the verse tomorrow
    When I rate the verse "John 3:16" with a 1
    Then the verse "John 3:16" should next be tested 1 day from today
    And the verse "John 3:16" should have a repetition count of 1
    When I go to the main memorization page
    Then I should be on the progress page
    And I should see "You have no more verses to memorize today. Your next memory verse is due for review tomorrow."
