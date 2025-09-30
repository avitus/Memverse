# Quiz Champion Badge Implementation

## Overview
The Quiz Champion badge is automatically awarded to users who win the weekly Bible knowledge quiz.

## Implementation Details

### Badge Details
- **Name**: Quiz Champion
- **Color**: solo (special badge)
- **Description**: "Won a weekly Bible knowledge quiz"

### How It Works
1. The KnowledgeQuiz worker runs twice weekly (Tuesdays at 17:00 UTC and Saturdays at 23:00 UTC)
2. When the quiz completes, the worker determines the winner based on the highest score
3. The worker automatically awards the Quiz Champion badge to the winner
4. If the winner already has the badge, no duplicate is created (handled by Badge#award_badge)

### Files Modified
1. **db/seeds.rb**: Added Quiz Champion badge creation for development environment
2. **app/workers/knowledge_quiz.rb**: Added badge awarding logic in `record_final_scoreboard` method (lines 422-435)
3. **spec/workers/knowledge_quiz_spec.rb**: Added comprehensive tests for badge awarding
4. **db/migrate/20250930222702_add_quiz_champion_badge.rb**: Migration to create badge in production

### Key Code Changes

In `KnowledgeQuiz#record_final_scoreboard`:
```ruby
# Award Quiz Champion badge to winner
begin
  quiz_champion_badge = Badge.where(name: 'Quiz Champion').first
  if quiz_champion_badge
    winner_user = User.find(gold_ribbon_id)
    quiz_champion_badge.award_badge(winner_user)
    Sidekiq.logger.info "===> Awarded Quiz Champion badge to #{gold_ribbon_name} (ID: #{gold_ribbon_id})"
  else
    Sidekiq.logger.error "===> Quiz Champion badge not found - cannot award to winner"
  end
rescue => e
  Sidekiq.logger.error "===> Failed to award Quiz Champion badge: #{e.message}"
  Sidekiq.logger.error e.backtrace.first(5).join("\n")
end
```

### Error Handling
- If the badge doesn't exist, an error is logged but the quiz continues
- If the winner user cannot be found, an error is logged but the quiz continues
- All errors are logged to Sidekiq logger for monitoring

### Testing
The implementation includes comprehensive test coverage:
- Awards badge when winner exists
- Handles missing badge gracefully
- Handles invalid winner ID gracefully
- Prevents duplicate badge awards
- Logs all actions for debugging

### Deployment Steps
1. Deploy the code changes
2. Run the migration: `rails db:migrate`
3. Verify the badge exists: `Badge.where(name: 'Quiz Champion').first`
4. Monitor Sidekiq logs after the next quiz to confirm badges are being awarded

### Future Enhancements
Consider implementing:
- Tiered badges (Bronze/Silver/Gold) based on number of wins
- Special badges for consecutive wins
- Badge for participation milestones
- Leaderboard integration