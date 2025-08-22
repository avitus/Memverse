#!/bin/bash

# Test verification script to check all test suites
# This script runs each test suite and reports results

echo "========================================="
echo "Test Suite Verification"
echo "========================================="
echo ""

# Check Redis is running
echo "Checking Redis..."
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis is running"
else
    echo "❌ Redis is not running. Starting Redis..."
    redis-server --daemonize yes
    sleep 2
fi
echo ""

# Run RSpec tests
echo "Running RSpec tests..."
if bundle exec rspec --format progress --format json --out tmp/rspec_results.json > /dev/null 2>&1; then
    RSPEC_TOTAL=$(jq '.summary.example_count' tmp/rspec_results.json)
    RSPEC_FAILURES=$(jq '.summary.failure_count' tmp/rspec_results.json)
    echo "✅ RSpec: $RSPEC_TOTAL tests, $RSPEC_FAILURES failures"
else
    echo "❌ RSpec tests failed to complete"
fi
echo ""

# Run Vitest JavaScript tests
echo "Running JavaScript tests (Vitest)..."
if npm run test:run > tmp/vitest_results.txt 2>&1; then
    VITEST_PASSED=$(grep -o "[0-9]* passed" tmp/vitest_results.txt | head -1)
    echo "✅ Vitest: $VITEST_PASSED"
else
    echo "❌ Vitest tests failed"
fi
echo ""

# Run Cucumber tests (sample of features)
echo "Running Cucumber tests (sample)..."
echo "Testing sign_in feature..."
if bundle exec cucumber features/users/sign_in.feature --format progress > /dev/null 2>&1; then
    echo "✅ sign_in.feature passed"
else
    echo "❌ sign_in.feature failed"
fi

echo "Testing sign_up feature..."
if bundle exec cucumber features/users/sign_up.feature --format progress > /dev/null 2>&1; then
    echo "✅ sign_up.feature passed"
else
    echo "❌ sign_up.feature failed"
fi

echo "Testing learn_verse feature..."
if bundle exec cucumber features/memverses/learn_verse.feature --format progress > /dev/null 2>&1; then
    echo "✅ learn_verse.feature passed"
else
    echo "❌ learn_verse.feature failed"
fi
echo ""

echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""
echo "To run full test suite:"
echo "  RSpec:    bundle exec rspec"
echo "  Vitest:   npm test"
echo "  Cucumber: bundle exec cucumber features"
echo ""
echo "Known Issues:"
echo "- Some Cucumber features with JavaScript require Chrome headless"
echo "- FinalVerse seeding warning is expected in test environment"
echo "- Deprecation warnings are tracked but don't affect test results"
echo ""