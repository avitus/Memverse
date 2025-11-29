# Quiz System Fix Plan

## Phase 1: Immediate Fixes (Priority)

### 1.1 Fix JavaScript Timezone Display Issue
**Problem**: Quiz times may be displaying incorrectly due to DST handling
**Solution**:
```javascript
// Update showLocalTimes function in live_quiz.js
showLocalTimes: function() {
  $('.schedule-local').each(function() {
    var utcTimeStr = $(this).data('utc-time');
    var timeParts = utcTimeStr.split(':');
    var utcHours = parseInt(timeParts[0]);
    var utcMinutes = parseInt(timeParts[1]);

    // Get next occurrence of this day/time combination
    var dayName = $(this).siblings('.schedule-day-name').text();
    var nextOccurrence = getNextOccurrence(dayName, utcHours, utcMinutes);

    // Format in user's local time
    var localTimeStr = nextOccurrence.toLocaleString([], {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
      timeZoneName: 'short'
    });

    $(this).text(localTimeStr);
  });
}

function getNextOccurrence(dayName, utcHour, utcMinute) {
  var daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  var targetDay = daysOfWeek.indexOf(dayName);

  var now = new Date();
  var nextDate = new Date();

  // Find next occurrence of target day
  var daysUntilTarget = (targetDay - now.getUTCDay() + 7) % 7;
  if (daysUntilTarget === 0 &&
      (now.getUTCHours() > utcHour ||
       (now.getUTCHours() === utcHour && now.getUTCMinutes() >= utcMinute))) {
    daysUntilTarget = 7;
  }

  nextDate.setUTCDate(now.getUTCDate() + daysUntilTarget);
  nextDate.setUTCHours(utcHour, utcMinute, 0, 0);

  return nextDate;
}
```

### 1.2 Add Quiz Health Check Monitoring
**Problem**: Quiz might be failing silently
**Solution**: Add health check endpoint and monitoring

```ruby
# app/controllers/admin/quiz_health_controller.rb
class Admin::QuizHealthController < ApplicationController
  before_action :authenticate_admin!

  def status
    @quiz_status = {
      redis_status: check_redis_status,
      last_run: check_last_run,
      next_scheduled: check_next_scheduled,
      sidekiq_jobs: check_sidekiq_jobs,
      recent_errors: check_recent_errors
    }
  end

  private

  def check_redis_status
    $redis.hgetall("quiz-bible-knowledge")
  rescue => e
    { error: e.message }
  end

  def check_last_run
    Tweet.where(importance: 2)
         .where("news LIKE ?", "%Bible knowledge quiz%")
         .order(created_at: :desc)
         .first
  end

  def check_next_scheduled
    Quiz.next_knowledge_quiz_time
  end

  def check_sidekiq_jobs
    require 'sidekiq-cron'

    Sidekiq::Cron::Job.all.select { |j|
      j.name.include?("quiz")
    }.map { |j|
      {
        name: j.name,
        cron: j.cron,
        last_enqueue: j.last_enqueue_time,
        status: j.status
      }
    }
  end

  def check_recent_errors
    # Check application logs for quiz errors
    []
  end
end
```

## Phase 2: Debugging and Monitoring

### 2.1 Enhanced Logging in KnowledgeQuiz Worker
Add detailed logging at each step:
- Job start/end times
- Lock acquisition status
- Each question processing
- PubNub publish confirmations
- Error details with full stack traces

### 2.2 Add Sidekiq Job Monitoring
```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.on(:startup) do
    Rails.logger.info "Sidekiq starting with cron jobs:"
    Sidekiq::Cron::Job.all.each do |job|
      Rails.logger.info "  - #{job.name}: #{job.cron} (#{job.status})"
    end
  end

  config.server_middleware do |chain|
    chain.add QuizJobLogger
  end
end

class QuizJobLogger
  def call(worker, job, queue)
    if worker.class.name == 'KnowledgeQuiz'
      Rails.logger.info "[QUIZ] Starting KnowledgeQuiz job at #{Time.current}"
      start_time = Time.current

      yield

      duration = Time.current - start_time
      Rails.logger.info "[QUIZ] KnowledgeQuiz completed in #{duration.round(2)}s"
    else
      yield
    end
  rescue => e
    Rails.logger.error "[QUIZ] KnowledgeQuiz failed: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
```

## Phase 3: Long-term Improvements

### 3.1 Refactor Quiz Scheduling System
- Move from cron-based to database-driven scheduling
- Store quiz schedules with proper timezone handling
- Allow admins to adjust quiz times through UI

### 3.2 Implement Quiz State Machine
- Use state machine pattern for quiz lifecycle
- Better handling of edge cases (crashes, timeouts)
- Automatic recovery mechanisms

### 3.3 Add Real-time Monitoring Dashboard
- WebSocket-based live quiz status
- Participant count tracking
- Error alerts for admins

## Testing Plan

### Local Testing
1. Test timezone conversions with different browser timezones
2. Simulate DST transitions
3. Test Sidekiq job execution
4. Test error recovery scenarios

### Production Testing
1. Deploy fixes to staging first
2. Run manual quiz test at off-hours
3. Monitor logs during next scheduled quiz
4. Have rollback plan ready

## Implementation Order
1. Fix JavaScript timezone display (immediate)
2. Add health check endpoint (same day)
3. Deploy enhanced logging (before next quiz)
4. Monitor next quiz execution closely
5. Implement long-term fixes based on findings