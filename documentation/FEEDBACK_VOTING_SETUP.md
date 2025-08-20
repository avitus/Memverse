# Feedback & Voting System Setup

This document explains how to set up and use the new feedback voting system built on top of Thredded.

## Overview

Instead of Uservoice, we now use the existing Thredded forum with added voting functionality. This provides:
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

2. **Generate voting tables**:
   ```bash
   rails generate acts_as_votable:migration
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
   - You can use the content from `FEEDBACK_WELCOME_TOPIC.md`
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

## Customizing Thredded Views

To add voting to Thredded topic lists, create view overrides:

1. Copy Thredded's topic partial:
   ```bash
   mkdir -p app/views/thredded/topics
   cp $(bundle show thredded)/app/views/thredded/topics/_topic.html.erb app/views/thredded/topics/
   ```

2. Add voting display to the topic partial:
   ```erb
   <!-- In _topic.html.erb, add this where you want voting to appear -->
   <%= thredded_topic_voting(topic) %>
   ```

3. For the feedback messageboard only, you can check:
   ```erb
   <% if topic.messageboard.slug == 'feedback' %>
     <%= thredded_topic_voting(topic) %>
   <% end %>
   ```

## Vote Sorting

To sort topics by votes in the feedback board:

```ruby
# In a controller or view
@topics = @messageboard.topics.left_joins(:votes_for)
  .group('thredded_topics.id')
  .order('COUNT(votes.id) DESC')
```

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