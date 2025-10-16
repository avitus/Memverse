// Vitest setup file
// Add any global test setup here

// Mock window.location for tests
Object.defineProperty(window, 'location', {
  value: {
    href: 'http://localhost:3000',
    reload: () => {},
    assign: () => {},
    replace: () => {}
  },
  writable: true
})