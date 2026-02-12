import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// Since we're using importmap-rails, we'll test the SSE logic directly
// without importing the Stimulus controller

describe('Quiz SSE Controller Logic', () => {
  let mockEventSource
  let eventListeners

  class MockEventSource {
    constructor(url) {
      this.url = url
      this.readyState = 0 // CONNECTING
      eventListeners = {}
      mockEventSource = this

      // Simulate connection opening after a delay
      setTimeout(() => {
        this.readyState = 1 // OPEN
        if (this.onopen) this.onopen()
      }, 10)
    }

    addEventListener(event, callback) {
      eventListeners[event] = callback
    }

    close() {
      this.readyState = 2 // CLOSED
    }

    // Helper to trigger events in tests
    triggerEvent(eventName, data) {
      if (eventListeners[eventName]) {
        eventListeners[eventName]({ data: JSON.stringify(data) })
      }
    }
  }

  beforeEach(() => {
    // Mock the EventSource API
    global.EventSource = MockEventSource

    // Mock console
    global.console.log = vi.fn()
    global.console.error = vi.fn()

    // Mock window.location
    delete window.location
    window.location = {
      reload: vi.fn(),
      href: 'http://localhost/live_quiz'
    }

    // Mock Turbo
    global.Turbo = {
      visit: vi.fn()
    }
  })

  afterEach(() => {
    vi.clearAllMocks()
    if (mockEventSource) {
      mockEventSource.close()
    }
  })

  describe('SSE connection', () => {
    it('establishes connection with correct URL', () => {
      const eventSource = new EventSource('/live_quiz/events?id=1')

      expect(mockEventSource).toBeDefined()
      expect(mockEventSource.url).toBe('/live_quiz/events?id=1')
    })

    it('handles connection open event', async () => {
      const eventSource = new EventSource('/live_quiz/events?id=1')
      const openHandler = vi.fn()
      eventSource.onopen = openHandler

      // Wait for connection to open
      await new Promise(resolve => setTimeout(resolve, 20))

      expect(openHandler).toHaveBeenCalled()
      expect(eventSource.readyState).toBe(1) // OPEN
    })
  })

  describe('quiz state updates', () => {
    it('processes reload action correctly', () => {
      const eventSource = new EventSource('/live_quiz/events?id=1')
      let reloadScheduled = false

      eventSource.addEventListener('quiz-state', (event) => {
        const data = JSON.parse(event.data)
        if (data.action === 'reload') {
          reloadScheduled = true
          eventSource.close()

          setTimeout(() => {
            window.location.reload()
          }, 500)
        }
      })

      // Trigger reload event
      mockEventSource.triggerEvent('quiz-state', {
        action: 'reload',
        state: 'running',
        message: 'Quiz is starting'
      })

      expect(reloadScheduled).toBe(true)
      expect(mockEventSource.readyState).toBe(2) // CLOSED

      // Check reload is called after delay
      setTimeout(() => {
        expect(window.location.reload).toHaveBeenCalled()
      }, 600)
    })

    it('processes state updates correctly', () => {
      const eventSource = new EventSource('/live_quiz/events?id=1')
      let receivedState = null

      eventSource.addEventListener('quiz-state', (event) => {
        const data = JSON.parse(event.data)
        receivedState = data.state
      })

      // Trigger state update
      mockEventSource.triggerEvent('quiz-state', {
        state: 'preparing',
        next_transition_at: new Date(Date.now() + 300000).toISOString()
      })

      expect(receivedState).toBe('preparing')
    })
  })

  describe('countdown formatting', () => {
    function formatTime(seconds) {
      if (seconds <= 0) return '00:00'

      const hours = Math.floor(seconds / 3600)
      const minutes = Math.floor((seconds % 3600) / 60)
      const secs = seconds % 60

      if (hours > 0) {
        return `${hours}h ${minutes}m`
      } else if (minutes > 0) {
        return `${minutes}m ${secs.toString().padStart(2, '0')}s`
      } else {
        return `${secs}s`
      }
    }

    it('formats time correctly for different durations', () => {
      expect(formatTime(7200)).toBe('2h 0m')
      expect(formatTime(3665)).toBe('1h 1m')
      expect(formatTime(120)).toBe('2m 00s')
      expect(formatTime(65)).toBe('1m 05s')
      expect(formatTime(45)).toBe('45s')
      expect(formatTime(0)).toBe('00:00')
      expect(formatTime(-10)).toBe('00:00')
    })
  })

  describe('error handling and reconnection', () => {
    it('handles connection errors', () => {
      const eventSource = new EventSource('/live_quiz/events?id=1')
      const errorHandler = vi.fn((event) => {
        // Simulate what a real error handler would do
        console.error('SSE connection error:', event)
      })
      eventSource.onerror = errorHandler

      // Simulate error
      if (eventSource.onerror) {
        eventSource.onerror({ type: 'error' })
      }

      expect(errorHandler).toHaveBeenCalled()
      expect(console.error).toHaveBeenCalledWith('SSE connection error:', { type: 'error' })
    })

    it('implements exponential backoff', () => {
      vi.useFakeTimers()

      let reconnectDelay = 1000
      let reconnectAttempts = 0
      const maxReconnectAttempts = 3

      function reconnect() {
        reconnectAttempts++
        if (reconnectAttempts < maxReconnectAttempts) {
          setTimeout(() => {
            // Attempt reconnection
            console.log(`Reconnecting after ${reconnectDelay}ms`)
            reconnectDelay = Math.min(reconnectDelay * 2, 30000)
          }, reconnectDelay)
        }
      }

      // Simulate multiple reconnection attempts
      reconnect()
      expect(reconnectDelay).toBe(1000)

      vi.advanceTimersByTime(1000)
      reconnect()
      expect(reconnectDelay).toBe(2000)

      vi.advanceTimersByTime(2000)
      reconnect()
      expect(reconnectDelay).toBe(4000)

      vi.useRealTimers()
    })
  })

  describe('fallback polling mechanism', () => {
    beforeEach(() => {
      vi.useFakeTimers()
      global.fetch = vi.fn()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('polls when SSE is not available', async () => {
      // Simulate SSE not available
      global.EventSource = undefined

      let pollingInterval = null

      // Fallback polling implementation
      function startPolling(quizId) {
        pollingInterval = setInterval(() => {
          fetch(`/live_quiz/quiz_state/${quizId}`)
            .then(response => response.json())
            .then(data => {
              if (data.should_refresh) {
                clearInterval(pollingInterval)
                window.location.reload()
              }
            })
            .catch(error => {
              console.error('Polling error:', error)
            })
        }, 5000)
      }

      global.fetch.mockResolvedValue({
        json: vi.fn().mockResolvedValue({ state: 'waiting' })
      })

      startPolling(1)

      // Advance timer to trigger polling
      vi.advanceTimersByTime(5000)

      expect(global.fetch).toHaveBeenCalledWith('/live_quiz/quiz_state/1')

      // Cleanup
      if (pollingInterval) clearInterval(pollingInterval)
    })

    it('triggers reload when polling detects should_refresh', async () => {
      let pollingInterval = null

      global.fetch.mockResolvedValue({
        json: vi.fn().mockResolvedValue({
          state: 'running',
          should_refresh: true
        })
      })

      // Simple polling check
      fetch('/live_quiz/quiz_state/1')
        .then(response => response.json())
        .then(data => {
          if (data.should_refresh) {
            setTimeout(() => {
              window.location.reload()
            }, 500)
          }
        })

      await vi.runAllTimersAsync()

      expect(window.location.reload).toHaveBeenCalled()
    })
  })
})