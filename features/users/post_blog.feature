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

