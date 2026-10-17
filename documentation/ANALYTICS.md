# Analytics and bot mitigation

Added October 2026 as the first step of the redesign (see
`documentation/redesign/DESIGN_BRIEF.md`). Before this, the site carried a dead Universal
Analytics snippet and the only usage data was in server logs.

## What is tracked

Analytics are first-party, server-side, via the `ahoy_matey` gem. Nothing is sent to a
third party. Visitors are identified by two first-party cookies (`ahoy_visitor`,
`ahoy_visit`; the cookieless mode was rejected because it merges people behind one
network and can attach one user's events to another user's visit). IPs are stored masked.
Logged-in activity is attributed by `user_id`, set on the visit at sign-in and on the
sign-up event explicitly.

Tables: `ahoy_visits` (one row per visit, with landing page, referrer, browser, OS,
device type, user) and `ahoy_events` (name, JSON properties, time, visit, user). The
landing page and referrer are stored without query strings (`Ahoy::Store#track_visit`),
so confirmation and password-reset tokens never reach the table; `utm_*` values are
extracted into their own columns first.

| Event | Where it is recorded | Properties |
|---|---|---|
| `$view` | every successful, non-XHR HTML GET (`AnalyticsTracking` concern in `ApplicationController`) | `controller`, `action`, `path`, `locale` |
| `signed_up` | `Users::RegistrationsController#create` | `user_id`, `login` |
| `verse_added` | `MemversesController#ajax_add` when a verse is actually added | `verse_id`, `ref`, `first_verse` (true on the user's first memverse) |
| `verse_rated` | `MemversesController#mark_test_quick` | `memverse_id`, `verse_id`, `rating` (1–5), `newly_memorized` |
| `reference_tested` | `MemversesController#score_ref_test` | `memverse_id`, `verse_id`, `correct` |

Not tracked at all (no visit, no event): anything under `admin/`, `utils`,
`rails_admin/`, `api/`, `apidocs`, `ckeditor/`, `turbo/` (`Ahoy.exclude_method`), and
crawlers or requests with no user agent (Ahoy's `browser`-based bot detection).

No `$view` event, but a visit may still be created (Ahoy tracks visits in a
`before_action`, the page-view hook runs afterwards): redirects, error responses, and
JSON/XHR calls to tracked controllers.

Configuration lives in `config/initializers/ahoy.rb`. Models are `Ahoy::Visit` and
`Ahoy::Event` (`app/models/ahoy/`).

### Swapping the provider

The page-view hook is one method (`AnalyticsTracking#track_page_view`). To add GA4 or
Plausible alongside, add their script to the layout; to replace Ahoy, change that method
and the four `ahoy.track` calls listed above. Do not reintroduce the UA snippet.

## Queries

Weekly reach per page (unique users, with visitor as fallback for anonymous traffic).
Group by `path` to rank individual URLs; swap in `controller` and `action` to match the
per-action method used in `documentation/redesign/PAGE_INVENTORY.md`:

```sql
SELECT JSON_UNQUOTE(JSON_EXTRACT(e.properties, '$.path'))   AS path,
       COUNT(*)                                             AS page_views,
       COUNT(DISTINCT COALESCE(e.user_id, v.visitor_token)) AS reach
FROM ahoy_events e
JOIN ahoy_visits v ON v.id = e.visit_id
WHERE e.name = '$view' AND e.time >= NOW() - INTERVAL 7 DAY
GROUP BY path
ORDER BY reach DESC;
```

Daily active reviewers and ratings:

```sql
SELECT DATE(time) AS day,
       COUNT(DISTINCT user_id) AS reviewers,
       COUNT(*)                AS ratings
FROM ahoy_events
WHERE name = 'verse_rated' AND time >= NOW() - INTERVAL 30 DAY
GROUP BY day ORDER BY day;
```

Sign-up to first verse, and sign-up to first rating (the onboarding funnel):

```sql
SELECT s.user_id,
       s.time AS signed_up_at,
       MIN(a.time) AS first_verse_at,
       MIN(r.time) AS first_rating_at
FROM ahoy_events s
LEFT JOIN ahoy_events a ON a.user_id = s.user_id AND a.name = 'verse_added'
LEFT JOIN ahoy_events r ON r.user_id = s.user_id AND r.name = 'verse_rated'
WHERE s.name = 'signed_up' AND s.time >= NOW() - INTERVAL 30 DAY
GROUP BY s.user_id, s.time;
```

Device and browser split for people who review:

```sql
SELECT v.device_type, v.browser, COUNT(DISTINCT e.user_id) AS users
FROM ahoy_events e JOIN ahoy_visits v ON v.id = e.visit_id
WHERE e.name = 'verse_rated' AND e.time >= NOW() - INTERVAL 30 DAY
GROUP BY v.device_type, v.browser ORDER BY users DESC;
```

In a Rails console the same data is reachable as `Ahoy::Event.where(name: "$view")` and
`Ahoy::Visit`.

### Retention

`ahoy_events` grows by roughly one row per page view and per rating (on the order of
20k rows a day at October 2026 volumes). Prune old visits together with their events, in
that order, so no event is left pointing at a deleted visit:

```ruby
old_visits = Ahoy::Visit.where("started_at < ?", 1.year.ago)
Ahoy::Event.where(visit_id: old_visits.select(:id)).delete_all
old_visits.delete_all
```

Run it from a cron or rake task when it matters.

## Bot mitigation

In October 2026 about 70% of all Rails requests were crawlers walking the blog index and
forum post permalinks: ShapBot and a distributed headless-Chrome scraper on
`/forum/posts/:id`, and bingbot, Reflectionbot, SemrushBot, Amzn-SearchBot,
SERankingBacklinksBot and KeenableBot exhaustively fetching every `?page=`, `?tag_name=`
and `?search=` permutation of `/blog`. Three layers now apply, in order:

1. **User-agent block** (`AttackProtectionMiddleware::BLOCKED_SCRAPER_AGENTS`, 403):
   ShapBot, Reflectionbot, KeenableBot, SemrushBot, SERankingBacklinksBot,
   Amzn-SearchBot. Googlebot and bingbot are not blocked.
2. **robots.txt** (`public/robots.txt`): disallows `/forum/posts/`, `/forum/private-topics/`,
   forum `/page-N` listings, legacy `/blog/blogs/` and `/blog/main` routes, blog URLs with
   a `page`, `tag_name`, `search` or `category_id` parameter, and any `page=` URL; plus
   explicit disallow-all entries for the scrapers above and PetalBot. A tracking-only
   query string stays crawlable.
3. **X-Robots-Tag / meta robots** (`RobotsDirectives` concern): `noindex, nofollow` on forum
   post permalinks (including their 302 to the topic), on legacy blog listing routes, and
   on any Thredded or Bloggity page with a `page` param or a query string. Top-level
   `/blog`, individual posts, `/forum` and topic pages stay indexable.
4. **Rack::Attack throttle** (`config/initializers/rack_attack.rb`) as a backstop for
   crawlers that ignore all of the above: 120 GETs per IP per 10 minutes under `/forum` or
   `/blog` (GET and HEAD), and 30 per IP per 10 minutes for `/blog` URLs carrying a
   listing parameter (`page`, `tag_name`, `search`, `category_id`). Throttled requests
   get a 429 with `Retry-After` set to the time left in the window. Client IPs come from
   Rack's forwarded-for handling; loopback and private proxies are trusted by default and
   `TRUSTED_PROXY_IPS` (default: fish-eagle's address, for the migration overlap) adds
   public ones. The counter store is Redis in production
   (`REDIS_URL`, namespace `rack_attack`) and an in-memory store elsewhere. Logged-in users
   are not exempt; the limits are far above human reading speed.

The distributed scraper rotates through hundreds of thousands of IPs with ordinary browser
user agents, so per-IP throttling cannot stop it. If forum load is still a problem after
this, the next step is a CDN or bot-management layer (Cloudflare) in front of nginx, or
caching topic pages for anonymous visitors.

## Tests

- `spec/requests/analytics_tracking_spec.rb`: page views, bot and admin exclusion, user
  attribution, the four product events.
- `spec/requests/robots_directives_spec.rb`: header and meta tag on noindex pages, absent
  on normal pages.
- `spec/requests/rack_attack_spec.rb`: throttle returns 429 past the limit.
- `spec/middleware/attack_protection_middleware_spec.rb`: scraper agents blocked, bingbot
  allowed.
