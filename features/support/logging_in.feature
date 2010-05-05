Feature: Logging in
  In order to get login
  As a user
  I want to see a getting started page if I'm new

  Scenario Outline: Start page after logging in
    
    Given the following users exist
    | login   		| password	|
    | avitus    	| veetle77	|
    | new_user  	| secret	|
    | unactivated 	| secret	|
     
    When I log in as "<login>" with password "<password>"
    
    Then I should <action>

    Examples:
      | login 			| action           				|
      | avitus 			| see "Spurgeon"  				|
      | new_user   		| see "Getting started"  		|
      | unactivated   	| see "password is incorrect"  	|

  
  Scenario Outline: Tutorial
    
    Given the following users exist
    | login   		| password	|
    | avitus    	| secret	|
    | new_user  	| secret	|
    | unactivated 	| secret	|
    
    Given I am logged in as "<login>" with password "<password>"
    
    When I go to the tutorial page
    
    Then I should <action>

    Examples:
      | login 			| action           										|
      | avitus 			| see "keeps track of all your bible memory verses"  	|
      | new_user   		| see "keeps track of all your bible memory verses"  	|
      | unactivated   	| see "keeps track of all your bible memory verses"  	|  