Feature: Refer
  In order to tell other people about Memverse
  A user
  Should be able to share a referrer link
    
	@javascript @refer
    Scenario: User tries valid referrer link
	  Given I am not logged in
	  And no user exists with an email of "user@test.com"
	  And there is a user with the login "myfriendslogin"
	  When I go to myfriendslogin's referrer page
	  And I go to the sign up page
	  And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              | please          |
        | user_password_confirmation | please          |
      And I press "submit"
	  Then there should be a user with an email of "user@test.com" whose referrer's login is "myfriendslogin"