#!/bin/bash

echo "========================================="
echo "Running All Test Suites"
echo "========================================="
echo ""

# Run RSpec tests
echo "1. Running RSpec Tests..."
echo "-----------------------------------------"
bundle exec rspec --format progress 2>&1 | tail -5
echo ""

# Run Cucumber tests
echo "2. Running Cucumber Tests..."
echo "-----------------------------------------"
bundle exec cucumber features --format progress 2>&1 | tail -5
echo ""

# Run JavaScript tests
echo "3. Running JavaScript Tests (Vitest)..."
echo "-----------------------------------------"
npm run test:run 2>&1 | tail -10
echo ""

echo "========================================="
echo "Test Summary Complete"
echo "========================================="