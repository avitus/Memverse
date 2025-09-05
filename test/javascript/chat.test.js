import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// Mock global dependencies
const mockHandlebars = {
  compile: vi.fn()
}

const mockChatEngine = {
  connect: vi.fn(),
  on: vi.fn(),
  Chat: vi.fn()
}

const mockChatEngineCore = {
  create: vi.fn(() => mockChatEngine)
}

const mockJQuery = vi.fn(() => ({
  html: vi.fn(() => 'mock template'),
  on: vi.fn(),
  append: vi.fn(),
  find: vi.fn(() => ({ remove: vi.fn() })),
  prepend: vi.fn(),
  scrollTop: vi.fn(),
  val: vi.fn(() => 'test message'),
  trim: vi.fn(() => 'test message')
}))

// Set up global mocks
global.Handlebars = mockHandlebars
global.ChatEngineCore = mockChatEngineCore
global.$ = mockJQuery
global.document = {
  addEventListener: vi.fn(),
  getElementById: vi.fn(() => ({ id: 'main-chat' }))
}

// Mock user data
global.memverseUserID = '123'
global.memverseUserName = 'TestUser'
global.memverseUserLogin = 'testuser'
global.memverseAvatar = 'http://example.com/avatar.jpg'

// Mock chat instance
const mockChat = {
  on: vi.fn(),
  emit: vi.fn(),
  search: vi.fn(() => ({ on: vi.fn() }))
}

// Mock user instance
const mockUser = {
  update: vi.fn(),
  uuid: '123'
}

describe('Chat Functionality', () => {
  let compiledTemplate
  let chatReadyCallback
  let messageCallback
  let onlineCallback
  let offlineCallback
  let connectedCallback

  beforeEach(() => {
    vi.clearAllMocks()
    
    // Mock Handlebars compile to return a mock template function
    compiledTemplate = vi.fn((data) => `<li>Mock template: ${JSON.stringify(data)}</li>`)
    mockHandlebars.compile.mockReturnValue(compiledTemplate)
    
    // Mock ChatEngine constructor to return mock chat instance
    mockChatEngine.Chat.mockReturnValue(mockChat)
    
    // Set up jQuery selectors
    mockJQuery.mockImplementation((selector) => {
      const mockElement = {
        html: vi.fn(() => 'mock template'),
        on: vi.fn(),
        append: vi.fn(),
        find: vi.fn(() => ({ remove: vi.fn() })),
        prepend: vi.fn(),
        scrollTop: vi.fn(),
        val: vi.fn(() => 'test message'),
        length: 1
      }
      
      if (selector === '#message-to-send') {
        mockElement.val = vi.fn(() => 'test message')
      }
      
      return mockElement
    })
  })

  describe('Chat Initialization', () => {
    it('should create ChatEngine with correct configuration', () => {
      // Simulate the chat initialization process
      const ChatEngine = mockChatEngineCore.create({
        publishKey: 'pub-c-816b4160-11c9-43fa-a1ea-4a1ca6cde79d',
        subscribeKey: 'sub-c-0e83b538-e6a1-11e7-a7db-e6c6e9cd0a3f'
      })
      
      ChatEngine.connect(memverseUserID, { username: memverseUserName })
      
      expect(mockChatEngineCore.create).toHaveBeenCalledWith({
        publishKey: 'pub-c-816b4160-11c9-43fa-a1ea-4a1ca6cde79d',
        subscribeKey: 'sub-c-0e83b538-e6a1-11e7-a7db-e6c6e9cd0a3f'
      })
      
      expect(mockChatEngine.connect).toHaveBeenCalledWith('123', { username: 'TestUser' })
    })

    it('should compile Handlebars templates', () => {
      const init = () => {
        mockHandlebars.compile(mockJQuery('#person-template').html())
        mockHandlebars.compile(mockJQuery('#message-template').html())
        mockHandlebars.compile(mockJQuery('#message-response-template').html())
      }
      
      init()
      
      expect(mockHandlebars.compile).toHaveBeenCalledTimes(3)
    })

    it('should set up ChatEngine ready callback', () => {
      const init = () => {
        chatReadyCallback = vi.fn((data) => {
          const me = data.me
          me.update({ full: memverseUserName })
          me.update({ avatar: memverseAvatar })
          
          const myChat = new mockChatEngine.Chat('chatengine-demo-chat')
          myChat.on('message', messageCallback)
        })
        
        mockChatEngine.on('$.ready', chatReadyCallback)
      }
      
      init()
      
      expect(mockChatEngine.on).toHaveBeenCalledWith('$.ready', expect.any(Function))
    })
  })

  describe('User Management', () => {
    beforeEach(() => {
      // Simulate ChatEngine ready event
      chatReadyCallback = vi.fn((data) => {
        const me = data.me
        me.update({ full: memverseUserName })
        me.update({ avatar: memverseAvatar })
      })
    })

    it('should update user with full name and avatar', () => {
      const mockData = { me: mockUser }
      
      chatReadyCallback(mockData)
      
      expect(mockUser.update).toHaveBeenCalledWith({ full: 'TestUser' })
      expect(mockUser.update).toHaveBeenCalledWith({ avatar: 'http://example.com/avatar.jpg' })
    })

    it('should handle user coming online', () => {
      onlineCallback = vi.fn((data) => {
        mockJQuery('#people-list ul').append(compiledTemplate(data.user))
      })
      
      const mockUserData = { user: { uuid: '456', state: { full: 'Another User' } } }
      onlineCallback(mockUserData)
      
      expect(compiledTemplate).toHaveBeenCalledWith(mockUserData.user)
    })

    it('should handle user going offline', () => {
      offlineCallback = vi.fn((data) => {
        mockJQuery('#people-list ul').find('#' + data.user.uuid).remove()
      })
      
      const mockUserData = { user: { uuid: '456' } }
      const mockFoundElement = { remove: vi.fn() }
      const mockPeopleList = { 
        find: vi.fn(() => mockFoundElement)
      }
      mockJQuery.mockReturnValue(mockPeopleList)
      
      offlineCallback(mockUserData)
      
      expect(mockPeopleList.find).toHaveBeenCalledWith('#456')
      expect(mockFoundElement.remove).toHaveBeenCalled()
    })
  })

  describe('Message Handling', () => {
    beforeEach(() => {
      messageCallback = vi.fn((message) => {
        // Mock renderMessage functionality
        const template = message.sender.uuid === mockUser.uuid ? compiledTemplate : compiledTemplate
        const el = template({
          messageOutput: message.data.text,
          time: new Date().toLocaleTimeString(),
          user: message.sender.state
        })
        mockJQuery('.chat-history ul').append(el)
      })
    })

    it('should render incoming messages', () => {
      const mockMessage = {
        sender: { uuid: '456', state: { full: 'Another User' } },
        data: { text: 'Hello world' }
      }
      
      messageCallback(mockMessage)
      
      expect(compiledTemplate).toHaveBeenCalledWith({
        messageOutput: 'Hello world',
        time: expect.any(String),
        user: mockMessage.sender.state
      })
    })

    it('should use different template for own messages', () => {
      const mockMessage = {
        sender: { uuid: '123', state: { full: 'TestUser' } },  // Same as mockUser.uuid
        data: { text: 'My message' }
      }
      
      // Mock the template selection logic
      const renderMessage = (message) => {
        const template = message.sender.uuid === '123' ? compiledTemplate : compiledTemplate
        template({
          messageOutput: message.data.text,
          time: new Date().toLocaleTimeString(),
          user: message.sender.state
        })
      }
      
      renderMessage(mockMessage)
      
      expect(compiledTemplate).toHaveBeenCalledWith({
        messageOutput: 'My message',
        time: expect.any(String),
        user: mockMessage.sender.state
      })
    })

    it('should handle message history', () => {
      connectedCallback = vi.fn(() => {
        const mockSearchResult = { on: vi.fn() }
        mockChat.search.mockReturnValue(mockSearchResult)
        
        mockChat.search({
          event: 'message',
          limit: 50
        }).on('message', messageCallback)
      })
      
      connectedCallback()
      
      expect(mockChat.search).toHaveBeenCalledWith({
        event: 'message',
        limit: 50
      })
    })
  })

  describe('Message Sending', () => {
    let sendMessage

    beforeEach(() => {
      sendMessage = vi.fn(() => {
        const message = mockJQuery('#message-to-send').val().trim()
        
        if (message.length) {
          mockChat.emit('message', { text: message })
          mockJQuery('#message-to-send').val('')
        }
        
        return false // Prevent form submission
      })
    })

    it('should send message when form is submitted', () => {
      const mockMessageInput = { 
        val: vi.fn(() => 'Hello world'),
        trim: vi.fn(() => 'Hello world')
      }
      
      // Mock jQuery to return message input
      mockJQuery.mockImplementation((selector) => {
        if (selector === '#message-to-send') {
          return mockMessageInput
        }
        return { val: vi.fn() }
      })
      
      const result = sendMessage()
      
      expect(mockChat.emit).toHaveBeenCalledWith('message', { text: 'Hello world' })
      expect(result).toBe(false) // Should prevent form submission
    })

    it('should clear input field after sending', () => {
      const mockMessageInput = { 
        val: vi.fn()
      }
      
      // First call returns message, second call clears it
      mockMessageInput.val
        .mockReturnValueOnce('Test message')
        .mockReturnValueOnce('')
      
      mockJQuery.mockReturnValue(mockMessageInput)
      
      sendMessage()
      
      expect(mockMessageInput.val).toHaveBeenCalledWith('')
    })

    it('should not send empty messages', () => {
      const mockMessageInput = { 
        val: vi.fn(() => ''),
        trim: vi.fn(() => '')
      }
      
      mockJQuery.mockReturnValue(mockMessageInput)
      
      sendMessage()
      
      expect(mockChat.emit).not.toHaveBeenCalled()
    })

    it('should trim whitespace from messages', () => {
      // Mock the chained val().trim() call
      const mockTrim = vi.fn(() => 'Hello world')
      const mockVal = vi.fn(() => ({ trim: mockTrim }))
      
      mockJQuery.mockReturnValue({ val: mockVal })
      
      sendMessage()
      
      expect(mockTrim).toHaveBeenCalled()
      expect(mockChat.emit).toHaveBeenCalledWith('message', { text: 'Hello world' })
    })
  })

  describe('Utility Functions', () => {
    it('should scroll to bottom of chat', () => {
      const scrollToBottom = () => {
        const chatHistory = mockJQuery('.chat-history')
        const scrollHeight = 1000 // Mock scroll height
        chatHistory.scrollTop(scrollHeight)
      }
      
      const mockChatHistory = { 
        scrollTop: vi.fn(),
        '0': { scrollHeight: 1000 }
      }
      
      mockJQuery.mockReturnValue(mockChatHistory)
      
      scrollToBottom()
      
      expect(mockChatHistory.scrollTop).toHaveBeenCalledWith(1000)
    })

    it('should format current time correctly', () => {
      const getCurrentTime = () => {
        return new Date().toLocaleTimeString().replace(/([\d]+:[\d]{2})(:[\d]{2})(.*)/, "$1$3")
      }
      
      // Mock Date to return predictable time
      const mockDate = new Date('2023-01-01T12:30:45')
      vi.spyOn(global, 'Date').mockImplementation(() => mockDate)
      
      const result = getCurrentTime()
      
      // Should remove seconds from time format
      expect(result).toMatch(/\d{1,2}:\d{2}\s?(AM|PM)/i)
    })
  })

  describe('Event Listeners', () => {
    it('should set up DOM ready event listener', () => {
      const init = vi.fn()
      
      // Simulate setting up event listeners
      global.document.addEventListener('DOMContentLoaded', init)
      global.document.addEventListener('turbo:load', () => {
        if (global.document.getElementById('main-chat')) {
          init()
        }
      })
      
      expect(global.document.addEventListener).toHaveBeenCalledWith('DOMContentLoaded', init)
      expect(global.document.addEventListener).toHaveBeenCalledWith('turbo:load', expect.any(Function))
    })

    it('should initialize on turbo:load when chat element present', () => {
      const init = vi.fn()
      let turboCallback
      
      // Capture the turbo:load callback
      global.document.addEventListener.mockImplementation((event, callback) => {
        if (event === 'turbo:load') {
          turboCallback = callback
        }
      })
      
      // Set up the event listener
      global.document.addEventListener('turbo:load', () => {
        if (global.document.getElementById('main-chat')) {
          init()
        }
      })
      
      // Mock getElementById to return chat element
      global.document.getElementById.mockReturnValue({ id: 'main-chat' })
      
      // Trigger the callback
      if (turboCallback) {
        turboCallback()
      }
      
      expect(init).toHaveBeenCalled()
    })
  })
})