Feature: Passages
  In order to memorize longer sections of scripture
  A user
  Should see consecutive verses grouped into a passage

  Background:
    Given the following verses exist:
      | book_index | book | chapter | versenum | text                                   | translation |
      | 43         | John | 3       | 16       | For God so loved the world...          | NIV         |
      | 43         | John | 3       | 17       | For God did not send his Son...        | NIV         |
      | 43         | John | 3       | 18       | Whoever believes in him...             | NIV         |
    And I sign in as a normal user
    And I have the following memory verses:
      | verse_ref | status   | efactor | next_test |
      | John 3:16 | Learning | 2.0     | 0 days    |
      | John 3:17 | Learning | 2.0     | 0 days    |
      | John 3:18 | Learning | 2.0     | 0 days    |

  Scenario: Consecutive verses form a single passage
    Then I should have 1 passage
    When I go to the passages page
    Then I should see "John 3:16-18"
    And I should not see "John 3:17"
