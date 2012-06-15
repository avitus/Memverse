Feature: Edit description of my group
  In order to change the description of her group
  A user
  Should be able to edit it in place
  
  Background:
  	Given I sign in as a normal user
  	And a group called "VineyardGrapes"
  	And the normal user belongs to the group called "VineyardGrapes"
     
    @javascript
    Scenario: User edits her group description
      When I go my group page
      And I click on description
      And I type "A group of grapes clinging to the vine for their life"
      And I click outside the box
      Then I should see "A group of grapes clinging to the vine for their life"

      
