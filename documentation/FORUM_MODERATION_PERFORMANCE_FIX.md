# Forum Moderation Page Performance Fix

## Problem Identified
The forum moderation page at `/forum/admin/moderation` was taking several minutes to load due to **missing database indexes** on the `thredded_posts` table.

## Root Cause
The `thredded_posts` table had **NO indexes at all**, causing:
- Full table scans on every query filtering by `moderation_state`
- Expensive joins on `user_id`, `postable_id`, and `messageboard_id`
- Slow sorting and pagination operations

## Solution Implemented

### Database Indexes Added
Created migration `20251106000002_add_remaining_thredded_posts_indexes.rb` that added the following indexes:

1. **`index_thredded_posts_on_moderation_state`** - For filtering posts by moderation status
2. **`index_thredded_posts_on_user_id`** - For user joins
3. **`index_thredded_posts_on_postable_id`** - For topic associations
4. **`index_thredded_posts_on_messageboard_id`** - For messageboard filtering
5. **`index_thredded_posts_for_display`** - Composite index on `(moderation_state, updated_at DESC)` for moderation page queries
6. **`index_thredded_posts_on_postable_id_and_created_at`** - For chronological post ordering

## Expected Performance Improvement
- **Before**: Full table scans on every query (O(n) complexity)
- **After**: Index lookups (O(log n) complexity)
- **Expected speedup**: 100x-1000x for typical queries

## Additional Performance Recommendations

### 1. Implement Pagination
If not already implemented, ensure the moderation page uses pagination:
```ruby
# In the controller or view
@posts = Thredded::Post.where(moderation_state: 'pending_moderation')
                       .includes(:user, :postable)
                       .page(params[:page])
                       .per(25)
```

### 2. Add Query Optimization
Use `includes` to prevent N+1 queries:
```ruby
# Eager load associations
@posts = Thredded::Post.pending_moderation
                       .includes(:user, :postable, :messageboard)
                       .order(updated_at: :desc)
```

### 3. Consider Caching
For frequently accessed data:
```ruby
# Cache moderation counts
Rails.cache.fetch('thredded_pending_moderation_count', expires_in: 5.minutes) do
  Thredded::Post.pending_moderation.count
end
```

### 4. Background Processing
Consider moving heavy operations to background jobs:
```ruby
# Process bulk moderation actions in background
class BulkModerationWorker
  include Sidekiq::Worker

  def perform(post_ids, action)
    Thredded::Post.where(id: post_ids).update_all(moderation_state: action)
  end
end
```

### 5. Monitor Query Performance
Add query logging in development:
```ruby
# In config/environments/development.rb
config.after_initialize do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end
```

### 6. Database Maintenance
Schedule regular database maintenance:
```sql
-- Analyze table statistics for query optimizer
ANALYZE TABLE thredded_posts;

-- Optimize table to reclaim space and defragment
OPTIMIZE TABLE thredded_posts;
```

## Testing the Fix

1. **Verify indexes are in place**:
   ```bash
   bundle exec rails console
   ActiveRecord::Base.connection.indexes('thredded_posts').map(&:name)
   ```

2. **Test the moderation page**:
   - Navigate to `/forum/admin/moderation`
   - Page should load in < 1 second

3. **Monitor slow queries**:
   - Check Rails logs for query times
   - Use MySQL slow query log if issues persist

## Long-term Recommendations

1. **Regular Index Review**: Periodically review database indexes across all tables
2. **Query Performance Monitoring**: Implement APM tools (New Relic, Scout) to catch slow queries
3. **Database Scaling**: As data grows, consider:
   - Read replicas for heavy read operations
   - Database partitioning for very large tables
   - Archiving old moderation data

## Rollback Plan
If issues arise, remove the indexes:
```ruby
class RemoveThreddedPostsIndexes < ActiveRecord::Migration[7.1]
  def change
    remove_index :thredded_posts, name: 'index_thredded_posts_on_moderation_state'
    remove_index :thredded_posts, name: 'index_thredded_posts_on_user_id'
    remove_index :thredded_posts, name: 'index_thredded_posts_on_postable_id'
    remove_index :thredded_posts, name: 'index_thredded_posts_on_messageboard_id'
    remove_index :thredded_posts, name: 'index_thredded_posts_for_display'
    remove_index :thredded_posts, name: 'index_thredded_posts_on_postable_id_and_created_at'
  end
end
```