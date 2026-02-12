import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-sse"
export default class extends Controller {
  static targets = ["countdown", "status"]
  static values = {
    quizId: { type: Number, default: 1 },
    eventsUrl: { type: String, default: "/live_quiz/events" }
  }

  connect() {
    console.log('QuizSSE: Connecting to quiz', this.quizIdValue)

    // Check browser support for SSE
    if (this.supportsSSE()) {
      this.startEventSource()
    } else {
      console.warn('QuizSSE: Browser does not support Server-Sent Events')
      this.fallbackToPolling()
    }
  }

  disconnect() {
    console.log('QuizSSE: Disconnecting')
    this.closeEventSource()
    this.stopPolling()
  }

  supportsSSE() {
    return typeof EventSource !== 'undefined'
  }

  startEventSource() {
    // Close any existing connection
    this.closeEventSource()

    // Build URL with quiz ID
    const url = `${this.eventsUrlValue}?id=${this.quizIdValue}`
    console.log('QuizSSE: Connecting to', url)

    this.eventSource = new EventSource(url)
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 10
    this.baseDelay = 1000 // Base delay for exponential backoff (1 second)
    this.maxDelay = 30000 // Maximum delay (30 seconds)
    this.reconnectDelay = this.baseDelay

    // Handle connection open
    this.eventSource.onopen = (event) => {
      console.log('QuizSSE: Connection established')
      this.reconnectAttempts = 0
      this.reconnectDelay = this.baseDelay

      // Clear any existing error notifications
      this.clearErrorNotification()

      // Update UI to show connected state
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = 'Connected'
        this.statusTarget.classList.remove('text-red-600')
        this.statusTarget.classList.add('text-green-600')
      }
    }

    // Handle quiz state updates
    this.eventSource.addEventListener('quiz-state', (event) => {
      try {
        const data = JSON.parse(event.data)
        console.log('QuizSSE: Received state update', data)

        // Handle action commands
        if (data.action === 'reload') {
          console.log('QuizSSE: Quiz is starting - reloading page')
          this.handleReload()
          return
        }

        // Validate state data before updating UI
        if (this.validateStateData(data)) {
          // Update UI based on state
          this.updateUIState(data)
        } else {
          console.error('QuizSSE: Invalid state data received', data)
        }
      } catch (error) {
        console.error('QuizSSE: Error parsing event data:', error)
      }
    })

    // Handle error events (e.g., rate limiting)
    this.eventSource.addEventListener('error', (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.code === 'RATE_LIMIT') {
          console.error('QuizSSE: Rate limit exceeded')
          this.handleRateLimit()
          return
        }
      } catch (e) {
        // Not a JSON error message, continue with normal error handling
      }
    })

    // Handle errors
    this.eventSource.onerror = (error) => {
      console.error('QuizSSE: Connection error', error)

      // Update UI to show error state
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = 'Connection lost - retrying...'
        this.statusTarget.classList.remove('text-green-600')
        this.statusTarget.classList.add('text-red-600')
      }

      // Close the connection
      this.eventSource.close()

      // Attempt reconnection with exponential backoff and jitter
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        this.reconnectAttempts++

        // Calculate delay with exponential backoff and jitter
        const jitter = Math.random() * 0.5 * this.reconnectDelay
        const delayWithJitter = Math.min(this.reconnectDelay + jitter, this.maxDelay)

        console.log(`QuizSSE: Reconnecting in ${Math.round(delayWithJitter)}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`)

        setTimeout(() => {
          this.startEventSource()
        }, delayWithJitter)

        // Exponential backoff: double the delay for next attempt
        this.reconnectDelay = Math.min(this.reconnectDelay * 2, this.maxDelay)
      } else {
        console.error('QuizSSE: Max reconnection attempts reached')
        this.showErrorNotification('Unable to maintain connection to quiz server. Switching to backup mode.')
        this.fallbackToPolling()
      }
    }
  }

  closeEventSource() {
    if (this.eventSource) {
      console.log('QuizSSE: Closing existing connection')
      this.eventSource.close()
      this.eventSource = null
    }
  }

  stopPolling() {
    if (this.pollingTimeout) {
      clearTimeout(this.pollingTimeout)
      this.pollingTimeout = null
    }
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
      this.pollingInterval = null
    }
  }

  validateStateData(data) {
    // Ensure we have required fields
    if (!data || typeof data !== 'object') {
      return false
    }

    // Check for required state field
    if (!data.state || typeof data.state !== 'string') {
      return false
    }

    // Validate state is one of expected values
    const validStates = ['none', 'waiting', 'preparing', 'ready', 'running', 'finished']
    if (!validStates.includes(data.state)) {
      return false
    }

    // If we have a transition time, ensure it's valid
    if (data.next_transition_at && !this.isValidISODate(data.next_transition_at)) {
      return false
    }

    return true
  }

  isValidISODate(dateString) {
    if (typeof dateString !== 'string') return false
    const date = new Date(dateString)
    return !isNaN(date.getTime())
  }

  updateUIState(data) {
    // Update countdown if we have time until next transition
    if (data.next_transition_at && this.hasCountdownTarget) {
      const transitionTime = new Date(data.next_transition_at)
      const now = new Date()
      const secondsUntilTransition = Math.max(0, Math.floor((transitionTime - now) / 1000))

      this.countdownTarget.textContent = this.formatTime(secondsUntilTransition)
    }

    // Update status message based on state
    const stateMessages = {
      'none': 'No quiz scheduled',
      'waiting': 'Waiting for quiz to start',
      'preparing': 'Quiz is preparing...',
      'ready': 'Quiz is ready - joining...',
      'running': 'Quiz in progress',
      'finished': 'Quiz has finished'
    }

    if (this.hasStatusTarget && stateMessages[data.state]) {
      this.statusTarget.textContent = stateMessages[data.state]
    }
  }

  async handleReload() {
    // Prevent multiple reloads
    if (this.reloadScheduled) {
      console.log('QuizSSE: Reload already scheduled')
      return
    }

    this.reloadScheduled = true

    // Close the event source before reloading
    this.closeEventSource()
    this.stopPolling()

    // Check server readiness before reload
    const checkServerReady = async () => {
      try {
        const response = await fetch(`/live_quiz/quiz_state/${this.quizIdValue}`, {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
          }
        })

        if (response.ok) {
          const data = await response.json()
          console.log('QuizSSE: Server readiness check:', data)

          // Verify we're in a stable state before reloading
          if (data.state && ['ready', 'running'].includes(data.state)) {
            return true
          }
        }
      } catch (error) {
        console.error('QuizSSE: Server readiness check failed:', error)
      }
      return false
    }

    // Add longer delay to ensure server is ready (2 seconds instead of 500ms)
    setTimeout(async () => {
      console.log('QuizSSE: Checking server readiness before reload')

      // Try to verify server is ready, with a timeout
      let serverReady = false
      const maxRetries = 3

      for (let i = 0; i < maxRetries; i++) {
        serverReady = await checkServerReady()
        if (serverReady) {
          break
        }
        // Wait a bit before retrying
        await new Promise(resolve => setTimeout(resolve, 500))
      }

      console.log(`QuizSSE: Server ready: ${serverReady}, proceeding with reload`)

      if (typeof Turbo !== 'undefined') {
        Turbo.visit(window.location.href, { action: 'replace' })
      } else {
        window.location.reload()
      }
    }, 2000)
  }

  formatTime(seconds) {
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

  handleRateLimit() {
    console.warn('QuizSSE: Rate limit exceeded, switching to polling')
    this.closeEventSource()

    // Show rate limit message
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = 'Connection limit exceeded - using polling mode'
      this.statusTarget.classList.remove('text-green-600')
      this.statusTarget.classList.add('text-yellow-600')
    }

    // Start polling with longer interval
    this.fallbackToPolling(10000) // 10 second interval for rate-limited clients
  }

  fallbackToPolling(interval = null) {
    console.warn('QuizSSE: Falling back to polling')

    // Stop any existing polling
    this.stopPolling()

    // Adaptive polling interval based on server response time
    let pollInterval = interval || 5000 // Default 5 seconds
    let lastResponseTime = Date.now()

    const performPoll = async () => {
      const startTime = Date.now()

      try {
        const response = await fetch(`/live_quiz/quiz_state/${this.quizIdValue}`)
        const data = await response.json()

        // Measure response time
        const responseTime = Date.now() - startTime
        lastResponseTime = Date.now()

        // Adjust polling interval based on response time and state
        if (data.state === 'waiting' && data.next_transition_at) {
          // If waiting, poll less frequently unless transition is soon
          const timeUntilTransition = new Date(data.next_transition_at) - new Date()
          if (timeUntilTransition > 60000) {
            pollInterval = Math.min(20000, pollInterval * 1.2) // Increase interval, max 20s
          } else if (timeUntilTransition < 10000) {
            pollInterval = 2000 // Poll more frequently when transition is imminent
          }
        } else if (data.state === 'preparing' || data.state === 'ready') {
          // Poll more frequently during state transitions
          pollInterval = 2000
        } else if (responseTime > 1000) {
          // If server is slow, back off
          pollInterval = Math.min(30000, pollInterval * 1.5)
        } else if (responseTime < 200) {
          // If server is fast, can poll more frequently
          pollInterval = Math.max(3000, pollInterval * 0.9)
        }

        // Validate state data before processing
        if (!this.validateStateData(data)) {
          console.error('QuizSSE: Invalid state data from polling', data)
          throw new Error('Invalid state data')
        }

        if (data.should_refresh) {
          this.handleReload()
        } else {
          this.updateUIState(data)
          this.clearErrorNotification()

          // Schedule next poll
          this.pollingTimeout = setTimeout(performPoll, pollInterval)
        }
      } catch (error) {
        console.error('QuizSSE: Polling error:', error)

        // Exponential backoff on errors
        pollInterval = Math.min(60000, pollInterval * 2)

        // Show error notification after 3 consecutive failures
        if (!this.pollErrorCount) this.pollErrorCount = 0
        this.pollErrorCount++

        if (this.pollErrorCount >= 3) {
          this.showErrorNotification('Having trouble connecting to quiz server. Will keep trying...')
        }

        // Retry after delay
        this.pollingTimeout = setTimeout(performPoll, pollInterval)
      }
    }

    // Start polling
    performPoll()

    // Update UI to show polling mode
    if (this.hasStatusTarget && !interval) {
      this.statusTarget.textContent = 'Using polling mode'
      this.statusTarget.classList.remove('text-red-600', 'text-green-600')
      this.statusTarget.classList.add('text-yellow-600')
    }
  }

  showErrorNotification(message) {
    // Remove any existing notification
    this.clearErrorNotification()

    // Create notification element
    const notification = document.createElement('div')
    notification.id = 'quiz-error-notification'
    notification.className = 'fixed top-4 right-4 bg-red-500 text-white px-6 py-4 rounded-lg shadow-lg z-50 max-w-md'
    notification.innerHTML = `
      <div class="flex items-center">
        <svg class="w-6 h-6 mr-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
        </svg>
        <div>
          <p class="font-semibold">Connection Error</p>
          <p class="text-sm mt-1">${message}</p>
        </div>
      </div>
      <button onclick="this.parentElement.remove()" class="absolute top-2 right-2 text-white hover:text-gray-200">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
        </svg>
      </button>
    `

    document.body.appendChild(notification)

    // Auto-remove after 10 seconds
    setTimeout(() => {
      notification.remove()
    }, 10000)
  }

  clearErrorNotification() {
    const notification = document.getElementById('quiz-error-notification')
    if (notification) {
      notification.remove()
    }
  }
}