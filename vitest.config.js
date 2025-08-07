import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['test/javascript/**/*.test.js'],
    setupFiles: ['test/javascript/setup.js'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      include: ['app/assets/javascripts/**/*.js'],
      exclude: [
        'app/assets/javascripts/vendor/**',
        'app/assets/javascripts/jquery*.js',
        '**/*.min.js'
      ]
    }
  },
  resolve: {
    alias: {
      '@': '/app/assets/javascripts'
    }
  }
})