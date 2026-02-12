# frozen_string_literal: true

# Load the QuizSseThrottle middleware
require Rails.root.join("app/middleware/quiz_sse_throttle")

# Add the middleware to the stack
Rails.application.config.middleware.use QuizSseThrottle