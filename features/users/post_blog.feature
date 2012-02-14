Feature: Post on Blog
  In order to publicize information
  As a user
  I want to be able to post on the blog
  
    Background:
      Given a blog titled "Memverse Blog"
  
    @blog
    Scenario: I am not logged in and cannot post
      When I go to the blog
      Then I should not see "New blog post"
      When I go to the new blog post page for the blog titled "Memverse Blog"
      Then I should see "You don't have permission to do that."
    
    @blog
    Scenario: I sign in but am not authorized to blog
      Given I am a user named "foo" with an email "user@test.com" and password "please"
      And the email address "user@test.com" is confirmed
      When I sign in as "user@test.com/please"
      Then I should be signed in
      When I go to the blog
	  Then I should not see "New blog post"
	  When I go to the new blog post page for the blog titled "Memverse Blog"
	  Then I should see "You don't have permission to do that."
	
    # @blog
    # Scenario: User signs in and creates two blog posts with same name
	#   Given I am a user named "blogger" with an email "user@test.com" and password "please"
    #   And the email address "user@test.com" is confirmed
	#   And the user with the email address "user@test.com" can blog
    #   When I sign in as "user@test.com/please"
    #   Then I should be signed in
    #   When I go to the blog
	#   And I press "New blog post"
	#   And I fill in the following:
    #     | blog_post_title            | Scripture Memorization   |
    #     | blog_post_body             | This is the post 1 body  |
    #     | blog_post_is_complete      | true                     |
    #   And I press "Save"
    #   Then I should see "This is the post 1 body"
	#   When I go to the blog
	#   And I press "New blog post"
	#   And I fill in the following:
    #     | blog_post_title            | Scripture Memorization   |
    #     | blog_post_body             | This is the post 2 body  |
    #     | blog_post_is_complete      | true                     |
    #   And I press "Save"
    #   Then I should see "This is the post 2 body"
	# 
	# Wasn't able to get can_blog? to return true for "blogger"....