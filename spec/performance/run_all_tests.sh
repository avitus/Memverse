#!/bin/bash

# Script to run all performance and chaos engineering tests
# Usage: ./spec/performance/run_all_tests.sh

set -e

echo "=================================================="
echo "Live Quiz SSE Performance and Chaos Testing Suite"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if Redis is running
if ! redis-cli ping > /dev/null 2>&1; then
    echo -e "${RED}Error: Redis is not running. Please start Redis first.${NC}"
    exit 1
fi

# Function to run a test category
run_test_category() {
    local category=$1
    local env_var=$2
    local spec_path=$3

    echo -e "\n${YELLOW}Running $category Tests...${NC}"
    echo "----------------------------------------"

    if [ "$DRY_RUN" = "true" ]; then
        echo "Would run: $env_var=true bundle exec rspec $spec_path"
    else
        if $env_var=true bundle exec rspec $spec_path --format documentation; then
            echo -e "${GREEN}✓ $category tests passed${NC}"
        else
            echo -e "${RED}✗ $category tests failed${NC}"
            FAILED_TESTS+=("$category")
        fi
    fi
}

# Parse command line arguments
DRY_RUN=false
QUICK_TEST=false
FAILED_TESTS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --quick)
            QUICK_TEST=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--quick]"
            exit 1
            ;;
    esac
done

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}DRY RUN MODE - No tests will actually be executed${NC}"
fi

if [ "$QUICK_TEST" = "true" ]; then
    echo -e "${YELLOW}QUICK TEST MODE - Running with reduced duration${NC}"
    export QUICK_TEST=true
fi

# Run each test category
echo -e "\n${GREEN}Starting test suite...${NC}\n"

# 1. Unit tests for chaos scenarios (these don't need special env vars)
echo -e "\n${YELLOW}Running Chaos Engineering Tests...${NC}"
echo "----------------------------------------"
if [ "$DRY_RUN" = "true" ]; then
    echo "Would run: bundle exec rspec spec/chaos/live_quiz_chaos_spec.rb"
else
    if bundle exec rspec spec/chaos/live_quiz_chaos_spec.rb --format documentation; then
        echo -e "${GREEN}✓ Chaos tests passed${NC}"
    else
        echo -e "${RED}✗ Chaos tests failed${NC}"
        FAILED_TESTS+=("Chaos")
    fi
fi

# 2. Load tests
run_test_category "Load" "LOAD_TEST" "spec/performance/live_quiz_load_spec.rb"

# 3. Stability tests
run_test_category "Stability" "STABILITY_TEST" "spec/stability/live_quiz_stability_spec.rb"

# 4. Benchmark tool demonstration
echo -e "\n${YELLOW}Running Benchmark Tool (30 second demo)...${NC}"
echo "----------------------------------------"
if [ "$DRY_RUN" = "true" ]; then
    echo "Would run: ruby test/performance/benchmark_quiz_sse.rb -u 10 -d 30"
else
    if [ -f "test/performance/benchmark_quiz_sse.rb" ]; then
        echo "Note: This requires the Rails server to be running on localhost:3000"
        echo "Starting benchmark with 10 users for 30 seconds..."

        if ruby test/performance/benchmark_quiz_sse.rb -u 10 -d 30 -o tmp/benchmark_demo.json; then
            echo -e "${GREEN}✓ Benchmark completed${NC}"
            echo "Results saved to tmp/benchmark_demo.json"
        else
            echo -e "${RED}✗ Benchmark failed (is the Rails server running?)${NC}"
        fi
    else
        echo -e "${RED}Benchmark script not found${NC}"
    fi
fi

# Summary
echo -e "\n=================================================="
echo "Test Suite Summary"
echo "=================================================="

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
else
    echo -e "${RED}The following test categories failed:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    exit 1
fi

echo -e "\n${YELLOW}Tips:${NC}"
echo "- Run with --dry-run to see what tests would be executed"
echo "- Run with --quick for faster execution with reduced test duration"
echo "- Check spec/performance/README.md for detailed documentation"
echo "- Individual tests can be run with their respective environment variables"

echo -e "\n${GREEN}Done!${NC}"