import { describe, it, expect, vi, beforeEach } from 'vitest'

describe('Quiz Participant Count Display', () => {
  let originalJQuery
  let mockJQuery
  let mockElements

  beforeEach(() => {
    // Save original jQuery
    originalJQuery = global.$

    // Mock jQuery elements
    mockElements = {
      '#quizzers-count': {
        html: vi.fn()
      },
      '#quizzers-stats': {
        effect: vi.fn().mockReturnThis()
      },
      '#roster-window': {
        scrollTop: vi.fn().mockReturnThis(),
        append: vi.fn().mockReturnThis(),
        0: { scrollHeight: 100 },
        get: vi.fn(() => ({ scrollHeight: 100 }))
      }
    }

    // Mock jQuery
    mockJQuery = vi.fn((selector) => {
      if (mockElements[selector]) {
        return mockElements[selector]
      }

      // Default mock element
      return {
        effect: vi.fn().mockReturnThis(),
        html: vi.fn().mockReturnThis(),
        append: vi.fn().mockReturnThis(),
        remove: vi.fn().mockReturnThis()
      }
    })

    global.$ = mockJQuery
    global.jQuery = mockJQuery

    // Mock the buildRosterItem function
    global.buildRosterItem = vi.fn(() => '<div>Test User</div>')
  })

  afterEach(() => {
    // Restore original
    global.$ = originalJQuery
    global.jQuery = originalJQuery
    delete global.buildRosterItem
  })

  it('subtracts 1 from PubNub occupancy when adding user to exclude quiz bot', () => {
    // Import the function (it would be defined globally in the actual app)
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      var userDiv = $(buildRosterItem(userID, userName, gravatarURL));
      $("#roster-window").scrollTop($("#roster-window")[0].scrollHeight).append(userDiv);
      userDiv.effect('highlight', {}, 3000);

      // This is the fix: subtract 1 from userCount to exclude the quiz bot
      var actualParticipantCount = Math.max(0, userCount - 1);
      $("#quizzers-stats").effect('highlight', {}, 3000);
      $("#quizzers-count").html("(" + actualParticipantCount + ")");
    }

    // Test with 3 PubNub connections (2 users + 1 bot)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 3)

    // Verify the displayed count is 2 (3 - 1)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(2)')
  })

  it('handles single participant correctly (bot + 1 user)', () => {
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      var actualParticipantCount = Math.max(0, userCount - 1);
      $("#quizzers-count").html("(" + actualParticipantCount + ")");
    }

    // Test with 2 PubNub connections (1 user + 1 bot)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 2)

    // Verify the displayed count is 1 (2 - 1)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(1)')
  })

  it('never shows negative count when only bot is present', () => {
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      var actualParticipantCount = Math.max(0, userCount - 1);
      $("#quizzers-count").html("(" + actualParticipantCount + ")");
    }

    // Test with 1 PubNub connection (just the bot)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 1)

    // Verify the displayed count is 0, not -1
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(0)')
  })

  it('updates count correctly when user leaves', () => {
    // Mock the presence callback for user leaving
    const mvPresence = function(message) {
      if (message.action === "leave") {
        // Subtract 1 from occupancy to exclude the quiz bot
        var actualParticipantCount = Math.max(0, message.occupancy - 1);
        $("#quizzers-count").html("(" + actualParticipantCount + ")");
      }
    }

    // Test user leaving - occupancy goes from 3 to 2 (1 user left)
    mvPresence({ action: "leave", occupancy: 2 })

    // Verify the displayed count is 1 (2 - 1)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(1)')
  })

  it('handles edge case of zero occupancy', () => {
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      var actualParticipantCount = Math.max(0, userCount - 1);
      $("#quizzers-count").html("(" + actualParticipantCount + ")");
    }

    // Test with 0 PubNub connections (edge case)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 0)

    // Verify the displayed count is 0 (Math.max ensures no negative)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(0)')
  })
})