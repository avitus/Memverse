Feature: Reminder Email Scenarios
  As a Memverse user
  I want to receive reminder emails based on my memorization progress
  So that I stay engaged with my Bible memorization journey

  Background:
    Given the following translations exist:
      | name   | translation        | language | translation_code |
      | NASB95 | New American Bible | English  | NASB95           |
    And email deliveries are enabled
    And the following verses exist:
      | book    | chapter | verse_number | text                        | translation |
      | John    | 3       | 16           | For God so loved the world... | NASB95      |
      | Romans  | 8       | 28           | And we know that God causes... | NASB95     |

  @javascript
  Scenario: User receives progression email level 9
    Given I am a confirmed user named "Progressor" with an email "progress@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 9
    When the system sends progression_email_9 to the user "Progressor"
    Then "progress@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And I should see "Progressor" in the email body
    And I should see "For God so loved the world" in the email body
    And I should see "admin@memverse.com" in the email from
    And the email should have tag "progression-9"
    And the email should have message stream "outbound"
    And the email should have unsubscribe link

  @javascript
  Scenario: User receives progression email level 8
    Given I am a confirmed user named "Progressor8" with an email "progress8@test.com" and password "password123"
    And I have a memverse for "Romans 8:28" at progression level 8
    When the system sends progression_email_8 to the user "Progressor8"
    Then "progress8@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And I should see "And we know that God causes" in the email body
    And the email should have tag "progression-8"
    And the email should have message stream "outbound"

  @javascript
  Scenario: User receives progression email level 7
    Given I am a confirmed user named "Progressor7" with an email "progress7@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 7
    When the system sends progression_email_7 to the user "Progressor7"
    Then "progress7@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And the email should have tag "progression-7"
    And the email should have message stream "outbound"

  @javascript
  Scenario: User receives progression email level 6
    Given I am a confirmed user named "Progressor6" with an email "progress6@test.com" and password "password123"
    And I have a memverse for "Romans 8:28" at progression level 6
    When the system sends progression_email_6 to the user "Progressor6"
    Then "progress6@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And the email should have tag "progression-6"

  @javascript
  Scenario: User receives progression email level 5
    Given I am a confirmed user named "Progressor5" with an email "progress5@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 5
    When the system sends progression_email_5 to the user "Progressor5"
    Then "progress5@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And the email should have tag "progression-5"

  @javascript
  Scenario: User receives progression email level 4
    Given I am a confirmed user named "Progressor4" with an email "progress4@test.com" and password "password123"
    And I have a memverse for "Romans 8:28" at progression level 4
    When the system sends progression_email_4 to the user "Progressor4"
    Then "progress4@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And the email should have tag "progression-4"

  @javascript
  Scenario: User receives progression email level 3
    Given I am a confirmed user named "Progressor3" with an email "progress3@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 3
    When the system sends progression_email_3 to the user "Progressor3"
    Then "progress3@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And the email should have tag "progression-3"

  @javascript
  Scenario: User receives progression email level 2 (no verse content)
    Given I am a confirmed user named "Progressor2" with an email "progress2@test.com" and password "password123"
    When the system sends progression_email_2 to the user "Progressor2"
    Then "progress2@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Reminder" in the email subject
    And I should see "Progressor2" in the email body
    And the email should have tag "progression-2"
    And the email should have message stream "outbound"
    And the email should have unsubscribe link
    But I should not see any specific verse text in the email body

  @javascript
  Scenario: Newsletter email contains proper content and headers
    Given I am a confirmed user named "Newsletter" with an email "newsletter@test.com" and password "password123"
    When the system sends newsletter_email to the user "Newsletter"
    Then "newsletter@test.com" should receive an email
    When I open the email
    Then I should see "Memverse Newsletter" in the email subject
    And I should see "Newsletter" in the email body
    And I should see "admin@memverse.com" in the email from
    And the email should have tag "newsletter"
    And the email should have message stream "broadcast"
    And the email should have unsubscribe link

  Scenario: All progression emails have correct Postmark configuration
    Given I am a confirmed user named "AllProgression" with an email "allprogression@test.com" and password "password123"
    And I have memverses at various progression levels
    When the system sends all progression emails to the user "AllProgression"
    Then "allprogression@test.com" should receive 9 emails
    And all received emails should have:
      | subject        | Memverse Reminder |
      | from           | "Memverse" <admin@memverse.com> |
      | message_stream | outbound         |
    And each email should have a unique tag:
      | progression-9 |
      | progression-8 |
      | progression-7 |
      | progression-6 |
      | progression-5 |
      | progression-4 |
      | progression-3 |
      | progression-2 |

  Scenario: All emails include proper unsubscribe headers
    Given I am a confirmed user named "Unsubscriber" with an email "unsubscriber@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 5
    When the system sends progression_email_5 to the user "Unsubscriber"
    And the system sends newsletter_email to the user "Unsubscriber"
    Then "unsubscriber@test.com" should receive 2 emails
    And all received emails should have header "List-Unsubscribe" containing "https://memverse.com/unsubscribe/unsubscriber@test.com"
    And all received emails should have header "List-Unsubscribe-Post" containing "List-Unsubscribe=One-Click"

  @javascript
  Scenario: Progression emails include verse content when appropriate
    Given I am a confirmed user named "VerseContent" with an email "versecontent@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 9
    And I have a memverse for "Romans 8:28" at progression level 3
    When the system sends progression_email_9 to the user "VerseContent"
    And the system sends progression_email_3 to the user "VerseContent"
    Then "versecontent@test.com" should receive 2 emails
    When I open the first email
    Then I should see "For God so loved the world" in the email body
    When I open the second email
    Then I should see "And we know that God causes" in the email body

  Scenario: Emails are multipart with both HTML and text versions
    Given I am a confirmed user named "Multipart" with an email "multipart@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 9
    When the system sends progression_email_9 to the user "Multipart"
    And the system sends newsletter_email to the user "Multipart"
    Then "multipart@test.com" should receive 2 emails
    And all received emails should be multipart with HTML and text versions
    And both parts of each email should contain the user's name "Multipart"

  Scenario: No reminder emails sent in test environment
    Given email deliveries are disabled for testing
    And I am a confirmed user named "TestEnv" with an email "testenv@test.com" and password "password123"
    And I have a memverse for "John 3:16" at progression level 9
    When the system attempts to send progression_email_9 to the user "TestEnv"
    Then "testenv@test.com" should receive no emails

  @javascript
  Scenario: Email content varies by progression level appropriately
    Given I am a confirmed user named "VariedContent" with an email "varied@test.com" and password "password123"
    And I have memverses at levels 9, 5, and 2
    When the system sends progression_email_9 to the user "VariedContent"
    And the system sends progression_email_5 to the user "VariedContent"
    And the system sends progression_email_2 to the user "VariedContent"
    Then "varied@test.com" should receive 3 emails
    And the emails should have different tags "progression-9", "progression-5", "progression-2"
    And progression level 9 and 5 emails should contain verse text
    But progression level 2 email should not contain specific verse text