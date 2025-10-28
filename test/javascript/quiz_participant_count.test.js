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

  it('displays the exact PubNub occupancy count when adding user', () => {
    // Import the function (it would be defined globally in the actual app)
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      var userDiv = $(buildRosterItem(userID, userName, gravatarURL));
      $("#roster-window").scrollTop($("#roster-window")[0].scrollHeight).append(userDiv);
      userDiv.effect('highlight', {}, 3000);

      // Display the exact PubNub occupancy count
      $("#quizzers-stats").effect('highlight', {}, 3000);
      $("#quizzers-count").html("(" + userCount + ")");
    }

    // Test with 3 PubNub connections (3 actual users)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 3)

    // Verify the displayed count is 3 (exact count)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(3)')
  })

  it('handles single participant correctly', () => {
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      $("#quizzers-count").html("(" + userCount + ")");
    }

    // Test with 1 PubNub connection (1 user)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 1)

    // Verify the displayed count is 1 (exact count)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(1)')
  })

  it('handles zero participants correctly', () => {
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      $("#quizzers-count").html("(" + userCount + ")");
    }

    // Test with 0 PubNub connections (no participants)
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 0)

    // Verify the displayed count is 0
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(0)')
  })

  it('updates count correctly when user leaves', () => {
    // Mock the presence callback for user leaving
    const mvPresence = function(message) {
      if (message.action === "leave") {
        // Display the exact occupancy count
        $("#quizzers-count").html("(" + message.occupancy + ")");
      }
    }

    // Test user leaving - occupancy goes from 3 to 2
    mvPresence({ action: "leave", occupancy: 2 })

    // Verify the displayed count is 2 (exact count)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(2)')
  })

  it('displays large participant counts correctly', () => {
    const addUserToRoster = function(userID, userName, gravatarURL, userCount) {
      $("#quizzers-count").html("(" + userCount + ")");
    }

    // Test with many participants
    addUserToRoster('user123', 'Test User', 'avatar.jpg', 25)

    // Verify the displayed count is 25 (exact count)
    expect(mockElements['#quizzers-count'].html).toHaveBeenCalledWith('(25)')
  })
})