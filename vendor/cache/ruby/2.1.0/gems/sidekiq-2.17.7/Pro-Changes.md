Sidekiq Pro Changelog
=======================

Please see [http://sidekiq.org/pro](http://sidekiq.org/pro) for more details and how to buy.

1.4.3
-----------

- Reverse sorting of Batches in Web UI [#1098]
- Refactoring for Sidekiq 3.0, Pro now requires Sidekiq 2.17.5

1.4.2
-----------

- Tolerate expired Batches in the web UI.
- Fix 100% CPU usage when using weighted queues and reliable fetch.

1.4.1
-----------

- Add batch progress bar to batch detail page. [#1398]
- Fix race condition in initializing Lua scripts


1.4.0
-----------

- Default batch expiration has been extended to 3 days, from 1 day previously.
- Batches now sort in the Web UI according to expiry time, not creation time.
- Add user-configurable batch expiry.  If your batches might take longer
  than 72 hours to process, you can extend the expiration date.

```ruby
b = Sidekiq::Batch.new
b.expires_in 5.days
...
```

1.3.2
-----------

- Lazy load Lua scripts so a Redis connection is not required on bootup.

1.3.1
-----------

- Fix a gemspec packaging issue which broke the Batch UI.

1.3.0
-----------

Thanks to @jonhyman for his contributions to this Sidekiq Pro release.

This release includes new functionality based on the SCAN command newly
added to Redis 2.8.  Pro still works with Redis 2.4 but some
functionality will be unavailable.

- Job Filtering in the Web UI!
  You can now filter retries and scheduled jobs in the Web UI so you
  only see the jobs relevant to your needs.  Queues cannot be filtered;
  Redis does not provide the same SCAN operation on the LIST type.
  **Redis 2.8**
  ![Filtering](https://f.cloud.github.com/assets/2911/1619465/f47529f2-5657-11e3-8cd1-33899eb72aad.png)
- SCAN support in the Sidekiq::SortedSet API.  Here's an example that
  finds all jobs which contain the substring "Warehouse::OrderShip"
  and deletes all matching retries.  If the set is large, this API
  will be **MUCH** faster than standard iteration using each.
  **Redis 2.8**
```ruby
  Sidekiq::RetrySet.new.scan("Warehouse::OrderShip") do |job|
    job.delete
  end
```

- Sidekiq::Batch#jobs now returns the set of JIDs added to the batch.
- Sidekiq::Batch#jids returns the complete set of JIDs associated with the batch.
- Sidekiq::Batch#remove\_jobs(jid, jid, ...) removes JIDs from the set, allowing early termination of jobs if they become irrelevant according to application logic.
- Sidekiq::Batch#include?(jid) allows jobs to check if they are still
  relevant to a Batch and exit early if not.
- Sidekiq::SortedSet#find\_job(jid) now uses server-side Lua if possible **Redis 2.6** [jonhyman]
- The statsd integration now sets global job counts:
```ruby
  jobs.count
  jobs.success
  jobs.failure
```

- Change shutdown logic to push leftover jobs in the private queue back
  into the public queue when shutting down with Reliable Fetch.  This
  allows the safe decommission of a Sidekiq Pro process when autoscaling. [jonhyman]
- Add support for weighted random fetching with Reliable Fetch [jonhyman]
- Pro now requires Sidekiq 2.17.0

1.2.5
-----------

- Convert Batch UI to use Sidekiq 2.16's support for extension localization.
- Update reliable\_push to work with Sidekiq::Client refactoring in 2.16
- Pro now requires Sidekiq 2.16.0

1.2.4
-----------

- Convert Batch UI to Bootstrap 3
- Pro now requires Sidekiq 2.15.0
- Add Sidekiq::Batch::Status#delete [#1205]

1.2.3
-----------

- Pro now requires Sidekiq 2.14.0
- Fix bad exception handling in batch callbacks [#1134]
- Convert Batch UI to ERB

1.2.2
-----------

- Problem with reliable fetch which could lead to lost jobs when Sidekiq
  is shut down normally.  Thanks to MikaelAmborn for the report. [#1109]

1.2.1
-----------

- Forgot to push paging code necessary for `delete_job` performance.

1.2.0
-----------

- **LEAK** Fix batch key which didn't expire in Redis.  Keys match
  /b-[a-f0-9]{16}-pending/, e.g. "b-4f55163ddba10aa0-pending" [#1057]
- **Reliable fetch now supports multiple queues**, using the algorithm spec'd
  by @jackrg [#1102]
- Fix issue with reliable\_push where it didn't return the JID for a pushed
  job when sending previously cached jobs to Redis.
- Add fast Sidekiq::Queue#delete\_job(jid) API which leverages Lua so job lookup is
  100% server-side.  Benchmark vs Sidekiq's Job#delete API. **Redis 2.6**

```
Sidekiq Pro API
  0.030000   0.020000   0.050000 (  1.640659)
Sidekiq API
 17.250000   2.220000  19.470000 ( 22.193300)
```

- Add fast Sidekiq::Queue#delete\_by\_class(klass) API to remove all
  jobs of a given type.  Uses server-side Lua for performance. **Redis 2.6**

1.1.0
-----------

- New `sidekiq/pro/reliable_push` which makes Sidekiq::Client resiliant
  to Redis network failures. [#793]
- Move `sidekiq/reliable_fetch` to `sidekiq/pro/reliable_fetch`


1.0.0
-----------

- Sidekiq Pro changelog moved to mperham/sidekiq for public visibility.
- Add new Rack endpoint for easy polling of batch status via JavaScript.  See `sidekiq/rack/batch_status`

0.9.3
-----------

- Fix bad /batches path in Web UI
- Fix Sinatra conflict with sidekiq-failures

0.9.2
-----------

- Fix issue with lifecycle notifications not firing.

0.9.1
-----------

- Update due to Sidekiq API changes.

0.9.0
-----------

- Rearchitect Sidekiq's Fetch code to support different fetch
strategies.  Add a ReliableFetch strategy which works with Redis'
RPOPLPUSH to ensure we don't lose messages, even when the Sidekiq
process crashes unexpectedly. [mperham/sidekiq#607]

0.8.2
-----------

- Reimplement existing notifications using batch on_complete events.

0.8.1
-----------

- Rejigger batch callback notifications.


0.8.0
-----------

- Add new Batch 'callback' notification support, for in-process
  notification.
- Symbolize option keys passed to Pony [mperham/sidekiq#603]
- Batch no longer requires the Web UI since Web UI usage is optional.
  You must require is manually in your Web process:

```ruby
require 'sidekiq/web'
require 'sidekiq/batch/web'
mount Sidekiq::Web => '/sidekiq'
```


0.7.1
-----------

- Worker instances can access the associated jid and bid via simple
  accessors.
- Batches can now be modified while being processed so, e.g. a batch
  job can add additional jobs to its own batch.

```ruby
def perform(...)
  batch = Sidekiq::Batch.new(bid) # instantiate batch associated with this job
  batch.jobs do
    SomeWorker.perform_async # add another job
  end
end
```

- Save error backtraces in batch's failure info for display in Web UI.
- Clean up email notification a bit.


0.7.0
-----------

- Add optional batch description
- Mutable batches.  Batches can now be modified to add additional jobs
  at runtime.  Example would be a batch job which needs to create more
  jobs based on the data it is processing.

```ruby
batch = Sidekiq::Batch.new(bid)
batch.jobs do
  # define more jobs here
end
```
- Fix issues with symbols vs strings in option hashes


0.6.1
-----------

- Webhook notification support


0.6
-----------

- Redis pubsub
- Email polish


0.5
-----------

- Batches
- Notifications
- Statsd middleware
