Feature: Admin panel access
  In order to get access to admin sections of the site
  An admin
  Should be able to access the admin and utils sections
  
    Background:
      Given I am not logged in

    Scenario: User without admin role accesses admin dashboard
      Given I sign in as an advanced user
      When I go to the admin dashboard     
      Then I should be on the home page      

    Scenario: User without admin role accesses utils dashboard
      Given I sign in as an advanced user
      When I go to the utils dashboard     
      Then I should be on the home page   

    Scenario: Admin successfully accesses admin dashboard
      Given I sign in as an admin user
      When I go to the admin dashboard
      Then I should see "Site administration"

    Scenario: Admin successfully accesses utils dashboard
      Given I sign in as an admin user
      When I go to the utils dashboard
      Then I should see "Weekly Activity"           