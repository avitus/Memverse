import { Controller } from "@hotwired/stimulus"
import PubNub from 'pubnub'

// Connects to data-controller="live-quiz"
export default class extends Controller {
  static targets = [
    "chatArea", "chatInput", "chatStatus",
    "question", "answer", "timer", "scoreboard",
    "questionDot", "participantCount", "preparingOverlay"
  ]

  static values = {
    quizId: Number,
    userId: Number,
    userName: String,
    userLogin: String,
    translation: String,
    numQuestions: Number,
    quizPreparing: Boolean,
    pubnubSubscribeKey: String,
    pubnubPublishKey: String
  }

  connect() {
    console.log('LiveQuizController: Connected with quiz ID:', this.quizIdValue)

    // Initialize core properties
    this.refreshing = false
    this.checkInterval = null
    this.countdownInterval = null

    // Start the unified state monitoring
    this.startStateMonitoring()

    // Initialize quiz components that are always needed
    this.initializeQuiz()
    this.bindEvents()
  }

  disconnect() {
    this.cleanup()
  }

  // ========================================================================
  // Unified State Management - Single Source of Truth
  // ========================================================================

  async startStateMonitoring() {
    try {
      const state = await this.fetchQuizState()
      this.handleQuizState(state)
    } catch (error) {
      console.error('LiveQuizController: Error fetching quiz state:', error)
      // Retry after a delay
      this.scheduleNextCheck(5000)
    }
  }

  async fetchQuizState() {
    // Include whether preparing overlay is visible in the request
    const preparingVisible = this.hasPreparingOverlayTarget &&
                           this.preparingOverlayTarget.style.display !== 'none'

    const response = await fetch(`/live_quiz/quiz_state/${this.quizIdValue}?preparing_visible=${preparingVisible}`, {
      headers: {
        'Accept': 'application/json',
        'X-Quiz-Preparing': preparingVisible ? 'true' : 'false'
      }
    })

    if (!response.ok) {
      throw new Error(`Failed to fetch quiz state: ${response.status}`)
    }

    return response.json()
  }

  handleQuizState(state) {
    console.log('LiveQuizController: Quiz state:', state)

    // Clear any existing check interval
    if (this.checkInterval) {
      clearTimeout(this.checkInterval)
      this.checkInterval = null
    }

    // Handle immediate refresh if needed
    if (state.should_refresh) {
      console.log('LiveQuizController: Server says refresh now')
      this.refreshPage()
      return
    }

    // Handle different states
    switch(state.state) {
      case 'waiting':
        this.handleWaitingState(state)
        break
      case 'preparing':
        this.handlePreparingState(state)
        break
      case 'ready':
        this.handleReadyState(state)
        break
      case 'running':
        this.handleRunningState(state)
        break
      case 'finished':
        this.handleFinishedState(state)
        break
      case 'none':
        this.handleNoQuizState(state)
        break
      default:
        console.warn('LiveQuizController: Unknown state:', state.state)
    }

    // Schedule next check if there's a transition time
    if (state.next_transition_at) {
      const serverTime = new Date(state.server_time)
      const transitionTime = new Date(state.next_transition_at)
      const msUntilTransition = transitionTime - serverTime

      console.log('LiveQuizController: Next transition in', Math.round(msUntilTransition / 1000), 'seconds')

      if (msUntilTransition > 0) {
        // Schedule check just after the transition time
        this.scheduleNextCheck(msUntilTransition + 1000)

        // Update countdown display
        this.updateCountdownDisplay(msUntilTransition)
      } else {
        // We're past transition time, check again soon
        this.scheduleNextCheck(2000)
      }
    } else if (state.state === 'preparing') {
      // In preparing state without transition time, check frequently
      this.scheduleNextCheck(2000)
    }
  }

  handleWaitingState(state) {
    console.log('LiveQuizController: Quiz is waiting to start')
    // Hide preparing overlay if visible
    if (this.hasPreparingOverlayTarget) {
      this.preparingOverlayTarget.style.display = 'none'
    }
    // Show countdown to quiz start
    this.showStatus('Waiting for quiz to start...')
  }

  handlePreparingState(state) {
    console.log('LiveQuizController: Quiz is preparing')
    // Show preparing overlay if not already visible
    if (this.hasPreparingOverlayTarget && this.preparingOverlayTarget.style.display === 'none') {
      this.preparingOverlayTarget.style.display = 'flex'
    }
    this.showStatus('Quiz is initializing...')
  }

  handleReadyState(state) {
    console.log('LiveQuizController: Quiz is ready!')

    // Check if we're showing the preparing overlay and should refresh
    if (this.hasPreparingOverlayTarget && this.preparingOverlayTarget.style.display !== 'none') {
      console.log('LiveQuizController: Preparing overlay visible, refreshing page')
      this.refreshPage()
    } else {
      // Initialize PubNub if not already done
      if (!this.pubnub) {
        this.initializePubNub()
      }
      this.showStatus('Quiz is ready - Chat is open!')
    }
  }

  handleRunningState(state) {
    console.log('LiveQuizController: Quiz is running')
    // Hide preparing overlay if visible
    if (this.hasPreparingOverlayTarget) {
      this.preparingOverlayTarget.style.display = 'none'
    }
    // Ensure PubNub is initialized
    if (!this.pubnub) {
      this.initializePubNub()
    }
    this.showStatus('Quiz in progress')
  }

  handleFinishedState(state) {
    console.log('LiveQuizController: Quiz has finished')
    this.showStatus('Quiz has ended')
    this.stopCountdown()
  }

  handleNoQuizState(state) {
    console.log('LiveQuizController: No quiz scheduled')
    this.showStatus('No quiz currently scheduled')
    this.stopCountdown()
  }

  scheduleNextCheck(delayMs) {
    // Clear any existing check
    if (this.checkInterval) {
      clearTimeout(this.checkInterval)
    }

    console.log('LiveQuizController: Scheduling next check in', Math.round(delayMs / 1000), 'seconds')

    this.checkInterval = setTimeout(() => {
      this.startStateMonitoring()
    }, delayMs)
  }

  updateCountdownDisplay(msRemaining) {
    // Stop any existing countdown interval
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }

    const endTime = Date.now() + msRemaining

    // Update countdown immediately
    this.updateCountdownText(msRemaining)

    // Start interval to update countdown every second
    this.countdownInterval = setInterval(() => {
      const remaining = endTime - Date.now()
      if (remaining <= 0) {
        clearInterval(this.countdownInterval)
        this.countdownInterval = null
        this.updateCountdownText(0)
      } else {
        this.updateCountdownText(remaining)
      }
    }, 1000)
  }

  updateCountdownText(msRemaining) {
    if (!this.hasTimerTarget) return

    if (msRemaining <= 0) {
      this.timerTarget.textContent = 'Starting...'
      return
    }

    const totalSeconds = Math.floor(msRemaining / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60

    this.timerTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  stopCountdown() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
  }

  showStatus(message) {
    const statusEl = document.getElementById('countdown-till')
    if (statusEl) {
      statusEl.innerHTML = `<strong>Status:</strong> ${message}`
    }
  }

  refreshPage() {
    // Prevent multiple refreshes
    if (!this.refreshing) {
      this.refreshing = true
      console.log('LiveQuizController: Refreshing page...')

      // Use Turbo if available, otherwise standard reload
      if (typeof Turbo !== 'undefined') {
        Turbo.visit(window.location.href, { action: 'replace' })
      } else {
        window.location.reload()
      }
    }
  }

  // ========================================================================
  // PubNub and Quiz Functionality (unchanged from before)
  // ========================================================================

  initializePubNub() {
    if (this.pubnub) {
      console.log('LiveQuizController: PubNub already initialized')
      return
    }

    console.log('LiveQuizController: Initializing PubNub')

    // Initialize PubNub with v7 API
    this.pubnub = new PubNub({
      publishKey: this.pubnubPublishKeyValue,
      subscribeKey: this.pubnubSubscribeKeyValue,
      userId: `user-${this.userIdValue}`, // v7 uses userId instead of uuid
      presenceTimeout: 60,
      heartbeatInterval: 30
    })

    // Set up message listener
    this.pubnub.addListener({
      message: (messageEvent) => {
        this.handleMessage(messageEvent.message)
      },
      presence: (presenceEvent) => {
        this.handlePresence(presenceEvent)
      },
      status: (statusEvent) => {
        this.handleStatus(statusEvent)
      }
    })

    // Subscribe to quiz channel with presence
    const channel = `quiz-${this.quizIdValue}`
    this.pubnub.subscribe({
      channels: [channel],
      withPresence: true
    })
  }

  initializeQuiz() {
    this.currentQuestion = 0
    this.userScore = 0
    this.participants = new Map()
    this.questionStartTime = null
    this.timerInterval = null
  }

  bindEvents() {
    // Chat input handling
    if (this.hasChatInputTarget) {
      this.chatInputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendChat()
        }
      })
    }
  }

  // Message Handling
  handleMessage(message) {
    if (!message || !message.meta) return

    switch(message.meta) {
      case 'chat':
        this.handleChat(message.data)
        break
      case 'chat_status':
        this.handleChatStatus(message)
        break
      case 'question':
        this.handleQuestion(message)
        break
      case 'scoreboard':
        this.handleScoreboard(message)
        break
      case 'quiz_start':
        this.handleQuizStart(message)
        break
      case 'quiz_end':
        this.handleQuizEnd(message)
        break
      case 'error':
        this.handleError(message)
        break
    }
  }

  handleChat(data) {
    if (!data) return

    const { user, msg, user_id } = data
    this.displayChat(user, msg, 'chat', user_id)
  }

  handleChatStatus(message) {
    if (this.hasChatStatusTarget) {
      this.chatStatusTarget.textContent = message.status
    }

    this.displayChat(
      'Memverse Server',
      `Chat Channel ${message.status}`,
      'system'
    )
  }

  handleQuestion(data) {
    this.currentQuestion = data.q_num
    this.questionStartTime = Date.now()

    // Update question display
    this.displayQuestion(data)

    // Start timer
    this.startTimer(data.time_alloc)

    // Update progress indicators
    this.updateProgressDots(data.q_num)
  }

  handleScoreboard(data) {
    if (!data.scoreboard) return

    this.updateScoreboardDisplay(data.scoreboard)
  }

  handleQuizStart(data) {
    this.showNotification('Quiz is starting!', 'success')
    this.resetQuizDisplay()
  }

  handleQuizEnd(data) {
    this.showNotification('Quiz has ended!', 'info')
    this.stopTimer()

    if (data.winner) {
      this.announceWinner(data.winner)
    }
  }

  handleError(message) {
    console.error('Quiz error:', message)
    this.showNotification(message.error || 'An error occurred', 'error')
  }

  handlePresence(event) {
    if (this.hasParticipantCountTarget) {
      // Update participant count based on presence
      const occupancy = event.occupancy || 0
      this.participantCountTarget.textContent = occupancy
    }
  }

  handleStatus(event) {
    if (event.category === 'PNConnectedCategory') {
      console.log('Connected to PubNub')
      this.showNotification('Connected to quiz room', 'success')
    } else if (event.category === 'PNNetworkDownCategory') {
      console.error('Network is down')
      this.showNotification('Connection lost. Retrying...', 'warning')
    }
  }

  // Display Methods
  displayQuestion(data) {
    const { q_num, q_type, q_ref, q_passages, mc_question,
            mc_option_a, mc_option_b, mc_option_c, mc_option_d } = data

    let questionHTML = ''
    let answerHTML = ''

    switch(q_type) {
      case 'recitation':
        questionHTML = this.formatQuestionText(q_ref)
        answerHTML = q_passages[this.translationValue] || q_passages['NIV']
        break

      case 'reference':
        questionHTML = q_passages[this.translationValue] || q_passages['NIV']
        answerHTML = this.formatQuestionText(q_ref)
        break

      case 'mcq':
        questionHTML = this.formatMCQ(mc_question, mc_option_a, mc_option_b, mc_option_c, mc_option_d)
        answerHTML = data.mc_answer
        break
    }

    // Update question display
    const questionTarget = this.questionTargets.find(t => t.dataset.questionNumber == q_num)
    if (questionTarget) {
      questionTarget.innerHTML = questionHTML
      questionTarget.dataset.answer = answerHTML
      questionTarget.dataset.questionId = data.q_id
      questionTarget.classList.add('active')
    }
  }

  formatQuestionText(text) {
    return `<p class="text-lg font-medium">${this.escapeHtml(text)}</p>`
  }

  formatMCQ(question, optionA, optionB, optionC, optionD) {
    return `
      <div class="mcq-question">
        <p class="text-lg font-medium mb-4">${this.escapeHtml(question)}</p>
        <div class="space-y-2">
          <button class="mcq-option" data-action="click->live-quiz#selectAnswer" data-answer="A">
            A. ${this.escapeHtml(optionA)}
          </button>
          <button class="mcq-option" data-action="click->live-quiz#selectAnswer" data-answer="B">
            B. ${this.escapeHtml(optionB)}
          </button>
          <button class="mcq-option" data-action="click->live-quiz#selectAnswer" data-answer="C">
            C. ${this.escapeHtml(optionC)}
          </button>
          <button class="mcq-option" data-action="click->live-quiz#selectAnswer" data-answer="D">
            D. ${this.escapeHtml(optionD)}
          </button>
        </div>
      </div>
    `
  }

  displayChat(user, message, type, userId = null) {
    if (!this.hasChatAreaTarget) return

    const chatEntry = document.createElement('div')
    chatEntry.className = `chat-entry chat-${type}`

    const timestamp = new Date().toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit'
    })

    chatEntry.innerHTML = `
      <span class="chat-timestamp">${timestamp}</span>
      <span class="chat-user" data-user-id="${userId || ''}">${this.escapeHtml(user)}:</span>
      <span class="chat-message">${this.escapeHtml(message)}</span>
    `

    this.chatAreaTarget.appendChild(chatEntry)
    this.chatAreaTarget.scrollTop = this.chatAreaTarget.scrollHeight
  }

  updateScoreboardDisplay(scoreboard) {
    if (!this.hasScoreboardTarget) return

    const sortedScores = scoreboard.sort((a, b) => b.score - a.score)

    let scoreboardHTML = '<h3 class="font-bold mb-2">Leaderboard</h3>'
    scoreboardHTML += '<ol class="space-y-1">'

    sortedScores.slice(0, 10).forEach((participant, index) => {
      const medal = index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : ''
      scoreboardHTML += `
        <li class="flex justify-between">
          <span>${medal} ${index + 1}. ${this.escapeHtml(participant.name)}</span>
          <span class="font-mono">${participant.score}</span>
        </li>
      `
    })

    scoreboardHTML += '</ol>'
    this.scoreboardTarget.innerHTML = scoreboardHTML
  }

  updateProgressDots(currentQuestion) {
    this.questionDotTargets.forEach((dot, index) => {
      dot.classList.remove('current', 'completed')

      if (index + 1 < currentQuestion) {
        dot.classList.add('completed')
      } else if (index + 1 === currentQuestion) {
        dot.classList.add('current')
      }
    })
  }

  // Timer Methods
  startTimer(duration) {
    this.stopTimer()

    let timeRemaining = duration

    this.timerInterval = setInterval(() => {
      timeRemaining--

      if (this.hasTimerTarget) {
        const minutes = Math.floor(timeRemaining / 60)
        const seconds = timeRemaining % 60
        this.timerTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
      }

      if (timeRemaining <= 0) {
        this.stopTimer()
        this.submitAnswer(0) // Time's up, submit 0 score
      }
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  // Actions
  sendChat() {
    if (!this.hasChatInputTarget) return

    const message = this.chatInputTarget.value.trim()
    if (!message) return

    const channel = `quiz-${this.quizIdValue}`

    this.pubnub.publish({
      channel: channel,
      message: {
        meta: 'chat',
        data: {
          user: this.userNameValue,
          user_id: this.userIdValue,
          msg: message
        }
      }
    }, (status) => {
      if (status.error) {
        console.error('Failed to send chat:', status)
        this.showNotification('Failed to send message', 'error')
      }
    })

    this.chatInputTarget.value = ''
  }

  selectAnswer(event) {
    const button = event.currentTarget
    const answer = button.dataset.answer

    // Visual feedback
    button.classList.add('selected')

    // Calculate score based on time taken
    const timeTaken = (Date.now() - this.questionStartTime) / 1000
    const score = Math.max(10 - Math.floor(timeTaken / 2), 1)

    this.submitAnswer(score)
  }

  submitAnswer(score) {
    const questionTarget = this.questionTargets.find(t =>
      t.dataset.questionNumber == this.currentQuestion
    )

    if (!questionTarget) return

    const questionId = questionTarget.dataset.questionId

    // Send score to server
    fetch('/live_quiz/record_score', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken()
      },
      body: JSON.stringify({
        quiz_id: this.quizIdValue,
        usr_id: this.userIdValue,
        usr_name: this.userNameValue,
        usr_login: this.userLoginValue,
        question_id: questionId,
        question_num: this.currentQuestion,
        score: score
      })
    }).catch(error => {
      console.error('Failed to submit score:', error)
    })

    // Show answer
    if (questionTarget.dataset.answer) {
      this.showAnswer(questionTarget.dataset.answer)
    }
  }

  showAnswer(answer) {
    if (this.hasAnswerTarget) {
      this.answerTarget.innerHTML = `
        <div class="answer-reveal">
          <h4 class="font-bold">Answer:</h4>
          <p>${answer}</p>
        </div>
      `
    }
  }

  // Utility Methods
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }

  showNotification(message, type = 'info') {
    // Create a temporary notification element
    const notification = document.createElement('div')
    notification.className = `notification notification-${type}`
    notification.textContent = message

    document.body.appendChild(notification)

    // Auto-remove after 5 seconds
    setTimeout(() => {
      notification.remove()
    }, 5000)
  }

  announceWinner(winner) {
    this.showNotification(`🎉 ${winner.name} wins with ${winner.score} points!`, 'success')
  }

  resetQuizDisplay() {
    this.questionTargets.forEach(target => {
      target.innerHTML = ''
      target.classList.remove('active')
    })

    this.questionDotTargets.forEach(dot => {
      dot.classList.remove('current', 'completed')
    })

    if (this.hasAnswerTarget) {
      this.answerTarget.innerHTML = ''
    }

    this.currentQuestion = 0
    this.userScore = 0
  }

  cleanup() {
    // Stop all intervals
    if (this.checkInterval) {
      clearTimeout(this.checkInterval)
      this.checkInterval = null
    }

    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }

    this.stopTimer()

    // Cleanup PubNub
    if (this.pubnub) {
      const channel = `quiz-${this.quizIdValue}`
      this.pubnub.unsubscribe({ channels: [channel] })
      this.pubnub.removeListener(this)
    }
  }
}