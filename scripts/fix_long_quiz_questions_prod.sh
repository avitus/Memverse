#!/bin/bash
# Script to fix long quiz questions in production

echo "Running fix_long_quiz_questions.rb in production environment..."
RAILS_ENV=production bundle exec rails runner fix_long_quiz_questions.rb