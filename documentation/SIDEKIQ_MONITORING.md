# Sidekiq Health Monitoring

This document describes the enhanced Sidekiq configuration and health monitoring system implemented for the Memverse application.

## Queue Priority System

The application now uses a 4-tier queue priority system:

- **critical** (weight: 8) - User-facing, time-sensitive operations
  - `KnowledgeQuiz` - Live Bible knowledge quizzes
  - `ScheduledQuiz` - Quiz scheduling and management

- **high** (weight: 4) - Important but not urgent operations
  - `SendReminders` - User email reminders
  - `ForumReviewNotifier` - Admin forum notifications

- **default** (weight: 2) - Regular background tasks
  - `UpdateMetrics` - Daily statistics updates

- **low** (weight: 1) - Maintenance tasks, bulk operations
  - `RefreshTagCloud` - Tag cloud regeneration
  - `UpdateSubsections` - Passage subsection updates
  - `SubsectionPassages` - Passage processing

## Health Monitoring Endpoints

The following endpoints are available for monitoring Sidekiq health (requires admin authentication):

### Web Dashboard
- **URL**: `/admin/sidekiq_health/dashboard`
- **Purpose**: Human-readable dashboard showing queue status, failed jobs, and performance metrics
- **Features**: Auto-refreshes every 30 seconds, queue management actions

### Health Check API
- **URL**: `/admin/sidekiq_health/health_check`
- **Purpose**: JSON health status for automated monitoring
- **Response**: HTTP 200 (healthy) or 503 (unhealthy) with detailed status information

### Metrics API
- **URL**: `/admin/sidekiq_health/metrics`
- **Purpose**: Detailed performance metrics in JSON format
- **Data**: Server stats, queue depths, job performance, Redis metrics

## Configuration Files

### `/config/sidekiq.yml`
- Queue priorities and weights
- Redis connection pooling
- Environment-specific overrides
- Dead job retention settings

### `/config/initializers/sidekiq.rb`
- Redis connection configuration
- Error handling and alerting
- Performance monitoring middleware
- Health check setup
- Custom logging configuration

### `/config/sidekiq_schedule.yml`
- Cron job scheduling with appropriate queue assignments
- All scheduled jobs now use priority queues

## Monitoring Features

### Performance Tracking
- Job execution time monitoring
- Slow job detection (>30 seconds)
- Queue depth alerts
- Redis connection health

### Error Handling
- Enhanced error logging with context
- Critical job failure alerts
- Automatic retry management
- Dead job monitoring

### Health Checks
- Redis connectivity testing
- Queue depth thresholds
- Server heartbeat monitoring
- Job processing time analysis

## Environment Variables

- `REDIS_URL` - Redis connection string (default: redis://127.0.0.1:6379/0)
- `SIDEKIQ_REDIS_POOL_SIZE` - Connection pool size (default: 30)

## Usage Examples

### Check System Health
```bash
curl -H "Authorization: ..." https://yourapp.com/admin/sidekiq_health/health_check
```

### View Performance Metrics
```bash
curl -H "Authorization: ..." https://yourapp.com/admin/sidekiq_health/metrics
```

### Access Web Dashboard
Visit: `https://yourapp.com/admin/sidekiq_health/dashboard`

## Production Deployment

1. Restart Sidekiq workers to pick up new queue configuration
2. Monitor logs for any configuration issues
3. Set up automated health check monitoring
4. Configure alerting for critical job failures
5. Adjust queue concurrency if needed based on load

## Queue Management

The dashboard provides controls to:
- Pause/resume individual queues
- Retry all failed jobs
- Clear dead jobs
- View recent job failures
- Monitor job execution times

Jobs are processed according to queue weight, ensuring critical user-facing operations get priority over maintenance tasks.