Feature: Add a verse
  In order to memorize a verse
  A user
  Should be able to locate and add verses

  Background:
    Given the following verses exist:

    | book_index | book   | chapter | versenum | text |
    | 19         | Psalms | 37      | 1        | Do not fret because of evil men or be envious of those who do wrong; |
    | 19         | Psalms | 37      | 2        | for like the grass they will soon wither, like green plants they will soon die away. |
    | 19         | Psalms | 37      | 3        | Trust in the Lord and do good; dwell in the land and enjoy safe pasture. |
    | 19         | Psalms | 37      | 4        | Delight yourself in the Lord and he will give you the desires of your heart. |

  	And I sign in as a normal user
    And I go to the add verse page

    @javascript
    Scenario: User searches for a passage
      When I search for "Psalm 37:1-4"
      Then I should see "Do not fret"
      And I should see "Trust in the Lord"

    @javascript
    Scenario: User searches for a single verse
      When I search for "Psalm 37:4"
      Then I should see "Delight yourself in the Lord"

    @javascript
    Scenario: User searches for a chapter
      When I search for "Psalm 37"
      Then I should see "Do not fret"
      And I should see "they will soon wither"
      And I should see "Trust in the Lord"

