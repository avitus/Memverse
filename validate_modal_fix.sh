#!/bin/bash

echo "Validating Quiz Modal Fix"
echo "========================="

# Check if the view file has the proper structure
echo -e "\nChecking live_quiz_modern.html.erb structure..."

# Look for the closing conditional tag
if grep -n "^<% end %> <!-- End of quiz interface conditional -->" app/views/live_quiz/live_quiz_modern.html.erb > /dev/null; then
    echo "✓ Found proper closing tag for quiz interface conditional"
    
    # Get line numbers
    SCRIPT_START=$(grep -n "<script type=\"text/javascript\">" app/views/live_quiz/live_quiz_modern.html.erb | head -1 | cut -d: -f1)
    COND_END=$(grep -n "^<% end %> <!-- End of quiz interface conditional -->" app/views/live_quiz/live_quiz_modern.html.erb | cut -d: -f1)
    
    echo "  Script starts at line: $SCRIPT_START"
    echo "  Conditional ends at line: $COND_END"
    
    if [ "$SCRIPT_START" -lt "$COND_END" ]; then
        echo "✓ JavaScript is inside the conditional block"
    else
        echo "✗ JavaScript is outside the conditional block!"
    fi
else
    echo "✗ Could not find proper closing tag"
fi

# Check for the schedule partial
echo -e "\nChecking for quiz schedule partial..."
if grep -n "render partial: \"quiz_schedule\"" app/views/live_quiz/live_quiz_modern.html.erb > /dev/null; then
    echo "✓ Quiz schedule partial is rendered"
else
    echo "✗ Quiz schedule partial not found"
fi

# Look for the conditional structure
echo -e "\nChecking conditional structure..."
if grep -B2 -A2 "if !@quiz_running && @next_quiz_time" app/views/live_quiz/live_quiz_modern.html.erb > /dev/null; then
    echo "✓ Proper conditional for showing schedule vs quiz"
else
    echo "✗ Conditional structure not found"
fi

# Run a quick RSpec test to verify
echo -e "\nRunning specific test..."
bundle exec rspec spec/features/live_quiz_spec.rb -e "shows quiz schedule when no quiz is running" --format documentation