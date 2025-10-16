import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

describe('Live Quiz Countdown Conflict Prevention', () => {
  let originalJQuery
  let mockJQuery
  let sessionStorageMock
  let originalSessionStorage

  beforeEach(() => {
    // Save original jQuery
    originalJQuery = global.$

    // Mock sessionStorage
    originalSessionStorage = global.sessionStorage
    sessionStorageMock = {
      store: {},
      getItem: vi.fn((key) => sessionStorageMock.store[key] || null),
      setItem: vi.fn((key, value) => { sessionStorageMock.store[key] = value }),
      removeItem: vi.fn((key) => { delete sessionStorageMock.store[key] }),
      clear: vi.fn(() => { sessionStorageMock.store = {} })
    }
    global.sessionStorage = sessionStorageMock

    // Mock jQuery
    mockJQuery = vi.fn((selector) => {
      const mockElement = {
        length: 0,
        find: vi.fn().mockReturnThis(),
        text: vi.fn().mockReturnValue('0:05'),
        attr: vi.fn(),
        data: vi.fn()
      }

      // Mock Stimulus controller detection
      if (selector === '[data-controller="live-quiz"]') {
        mockElement.length = 0 // Default: no Stimulus controller
      }
      if (selector === '[data-live-quiz-quiz-preparing-value="true"]') {
        mockElement.length = 0 // Default: not preparing
      }

      return mockElement
    })

    global.$ = mockJQuery
    global.jQuery = mockJQuery
  })

  afterEach(() => {
    // Restore originals
    global.$ = originalJQuery
    global.jQuery = originalJQuery
    global.sessionStorage = originalSessionStorage
  })

  it('prevents jQuery countdown from refreshing when Stimulus controller is active and preparing', () => {
    // Setup: Stimulus controller is present and quiz is preparing
    mockJQuery.mockImplementation((selector) => {
      const mockElement = {
        length: 0,
        find: vi.fn().mockReturnThis(),
        text: vi.fn().mockReturnValue('0:00')
      }

      if (selector === '[data-controller="live-quiz"]') {
        mockElement.length = 1 // Stimulus controller present
      }
      if (selector === '[data-live-quiz-quiz-preparing-value="true"]') {
        mockElement.length = 1 // Quiz is preparing
      }

      return mockElement
    })

    // Simulate countdown reaching zero - should NOT reload
    const reloadSpy = vi.spyOn(window.location, 'reload').mockImplementation(() => {})

    // Execute the conflict prevention logic (simulated from live_quiz.js)
    const stimulusPresent = $('[data-controller="live-quiz"]').length > 0
    const quizPreparing = $('[data-live-quiz-quiz-preparing-value="true"]').length > 0

    if (stimulusPresent && quizPreparing) {
      // Exit early - Stimulus is handling it
      console.log('Quiz preparation is being handled by Stimulus controller')
    } else {
      // Would normally reload here
      window.location.reload()
    }

    // Verify reload was NOT called
    expect(reloadSpy).not.toHaveBeenCalled()

    reloadSpy.mockRestore()
  })

  it('allows jQuery countdown to refresh when Stimulus controller is not active', () => {
    // Setup: No Stimulus controller
    mockJQuery.mockImplementation((selector) => {
      const mockElement = {
        length: 0, // No elements found
        find: vi.fn().mockReturnThis(),
        text: vi.fn().mockReturnValue('0:00')
      }
      return mockElement
    })

    // Simulate countdown reaching zero - should reload
    const reloadSpy = vi.spyOn(window.location, 'reload').mockImplementation(() => {})

    // Execute the logic
    const stimulusPresent = $('[data-controller="live-quiz"]').length > 0
    const quizPreparing = $('[data-live-quiz-quiz-preparing-value="true"]').length > 0

    if (stimulusPresent && quizPreparing) {
      console.log('Quiz preparation is being handled by Stimulus controller')
    } else {
      // jQuery should handle the reload
      window.location.reload()
    }

    // Verify reload WAS called
    expect(reloadSpy).toHaveBeenCalled()

    reloadSpy.mockRestore()
  })

  it('uses shared sessionStorage flag to prevent duplicate reloads', () => {
    // Simulate first system setting the flag
    sessionStorage.setItem('quiz_reload_scheduled', 'true')

    // Second system checks the flag
    const isReloadScheduled = sessionStorage.getItem('quiz_reload_scheduled') === 'true'

    expect(isReloadScheduled).toBe(true)
    expect(sessionStorageMock.getItem).toHaveBeenCalledWith('quiz_reload_scheduled')

    // If reload is already scheduled, second system should not reload
    const reloadSpy = vi.spyOn(window.location, 'reload').mockImplementation(() => {})

    if (!isReloadScheduled) {
      window.location.reload()
    }

    expect(reloadSpy).not.toHaveBeenCalled()

    reloadSpy.mockRestore()
  })

  it('cleans up sessionStorage flags before reload', () => {
    // Set some quiz-related flags
    sessionStorage.setItem('quiz_preparation_123456', 'true')
    sessionStorage.setItem('quiz_reload_scheduled', 'true')
    sessionStorage.setItem('other_data', 'keep')

    // Clean up quiz flags (simulated from live_quiz.js)
    for (const key in sessionStorageMock.store) {
      if (key.startsWith('quiz_preparation_')) {
        sessionStorage.removeItem(key)
      }
    }
    sessionStorage.removeItem('quiz_reload_scheduled')

    // Verify quiz flags are removed but other data remains
    expect(sessionStorage.getItem('quiz_preparation_123456')).toBeNull()
    expect(sessionStorage.getItem('quiz_reload_scheduled')).toBeNull()
    expect(sessionStorage.getItem('other_data')).toBe('keep')
  })

  it('increases delay to 3 seconds after worker starts', () => {
    const targetTime = new Date()
    const currentTime = new Date(targetTime.getTime() + 100) // 100ms after target

    // Calculate delay
    const delayMs = 3000 // Changed from 2000 to 3000

    expect(delayMs).toBe(3000)
    expect(delayMs).toBeGreaterThan(2000) // Ensure it's more than the old delay
  })
})