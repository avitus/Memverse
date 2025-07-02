Feature: Demo Verse Review
  In order to learn how to use Memverse
  A visitor
  Should be able to demo the review page

    @javascript
    Scenario: Visitor tries demo
      When I go to the demo page
      Then I should see "This is a demo of the main memorization section"
      And I should see "D n c a l t t p"
      And I should not see "As you type"
      When I click inside "#verseguess"
      Then I should see "Live Feedback"
      And I should not see "This is a demo of the main memorization section"
      When I fill in "verseguess" with "Do not confirm any longer two the pattern"
      Then I should see "Do not ... any longer ... the pattern"
      When I click inside the first ".submit"
      Then I should see "How it works"
