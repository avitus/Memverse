# Feedback & Voting System Setup

This document explains how to set up and use the new feedback voting system built on top of Thredded.

## Overview

Instead of Uservoice, we use the existing Thredded forum with added voting functionality. This provides:
- Zero external dependencies
- Integrated user experience
- Voting on feature requests and bug reports
- Categories for organization
- Admin moderation tools

## Initial Setup

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Run the migrations** (the `votes` table migration is in `db/migrate`):
   ```bash
   rails db:migrate
   ```

3. **Create the feedback messageboard**:
   ```bash
   rake feedback:setup
   ```

## Post-Setup Steps

1. **Create a Welcome Topic** (optional but recommended)
   - Go to `/forum/feedback`
   - Click "New Topic" 
   - Create a pinned topic explaining how the feedback system works
   - Use the content in the appendix below
   - **Important**: Topics must be created through the web interface to ensure they have the required initial post

## How It Works

### For Users
- Visit `/forum/feedback` to access the feedback board
- Create topics for feature requests, bug reports, or improvements
- Vote on existing topics using the up/down arrows
- Most voted topics get priority consideration

### For Admins
- View voting statistics: `rake feedback:stats`
- Moderate through existing Thredded admin tools
- Topics automatically sorted by vote count in the messageboard

## Implementation files

The Thredded views were overridden and the sorting added in October 2025; nothing is left to do here.

| File | Role |
|---|---|
| `config/initializers/thredded_voting.rb` | `acts_as_votable` on `Thredded::Topic`, `Topic#vote_score` |
| `config/initializers/thredded_voting_decorator.rb` | `SortedTopicArray` (keeps Kaminari pagination) and the `Thredded::TopicsController` decorator that sorts the `feedback` board by votes, both by default and with `?sort=votes`; other boards keep Thredded's order |
| `app/controllers/thredded_votes_controller.rb` | `POST /thredded_votes/:id/upvote`, `POST .../downvote`, `DELETE .../unvote` (JSON for AJAX) |
| `app/helpers/thredded_voting_helper.rb` | `thredded_topic_voting` (Topic or TopicView) and `topic_vote_count_badge` |
| `app/views/thredded/topics/_topic.html.erb` | vote-count badge in topic lists (green positive, red negative, hidden at zero) |
| `app/views/thredded/topics/_header.html.erb` | up/down buttons, score and "Remove vote" on a topic page; "Login to vote" for guests |
| `app/views/thredded/topics/index.html.erb` | "Most Recent" / "Most Votes" sort links on the feedback board |
| `app/views/thredded/topics/show.html.erb`, `app/views/shared/_thredded_voting.html.erb` | topic page and the shared voting partial |
| `app/assets/stylesheets/thredded_voting.scss` | styles (`.thredded-voting`, `.vote-button`, `.vote-score`, `.voted`) |
| `lib/tasks/feedback_setup.rake` | `feedback:setup` (board + Feature Request / Bug Report / Improvement categories), `feedback:stats` |
| `db/migrate/20250819223753_acts_as_votable_migration.rb` | the `votes` table |

Behaviour: one vote per user per topic; clicking the opposite arrow changes the vote, clicking the
same arrow removes it; everything is AJAX with CSRF tokens; counts are computed on demand.

## Styling

The voting UI includes basic styling, but you can customize it by overriding these CSS classes:
- `.thredded-voting` - Main container
- `.vote-button` - Up/down vote buttons
- `.vote-score` - Vote count display
- `.voted` - Active vote state

## API Usage

If you need voting via AJAX:

```javascript
// Upvote
$.post('/thredded_votes/' + topicId + '/upvote.json')

// Downvote  
$.post('/thredded_votes/' + topicId + '/downvote.json')

// Remove vote
$.ajax({
  url: '/thredded_votes/' + topicId + '/unvote.json',
  type: 'DELETE'
})
```

## Benefits Over Uservoice

1. **Privacy**: All data stays in your system
2. **Integration**: Uses existing user accounts
3. **Cost**: Completely free
4. **Customization**: Full control over features and UI
5. **Moderation**: Leverage existing forum moderation tools

## Maintenance

- Run `rake feedback:stats` to see voting trends
- Archive completed feature requests
- Use Thredded's built-in moderation for spam control
- Consider pinning important topics or roadmap updates

## Technical Notes

### Topic Creation Requirements
Thredded requires all topics to have at least one post. Topics created programmatically without posts will cause errors when viewed. Always create topics through the web interface or ensure you create an initial post when creating topics via code.

### Database Character Set Limitation  
The current MySQL database uses `utf8mb3` character set which doesn't support 4-byte Unicode characters (emojis). This is noted in the modernization plan for future upgrade to `utf8mb4`.

## Appendix: welcome topic content

After `rake feedback:setup`, create this topic in the Feedback board through the web interface
(topics created in code without an initial post break when viewed), then pin it and optionally lock it.

**Title:** How to Use the Feedback Board (PINNED)

**Content:**

> Welcome to the Memverse Feedback & Feature Requests board!
>
> This is where you can:
> - **Suggest new features** for Memverse
> - **Report bugs** you encounter
> - **Vote on ideas** from other users
>
> **How voting works.** Each topic can be voted up or down. The most popular suggestions will be given
> priority consideration. Click ▲ to upvote a suggestion you support, ▼ to downvote if you don't think
> it's needed; you can remove your vote at any time.
>
> **Before posting:** search first (someone may have already suggested your idea); be specific, with
> details and examples; one idea per topic, so voting stays meaningful; choose the right category
> (Feature Request for new functionality, Bug Report for something broken, Improvement for enhancing an
> existing feature).
>
> **What happens next?** We regularly review the highest-voted suggestions. When we decide to implement
> something, we'll update the topic with our plans.
>
> Thank you for helping make Memverse better!
