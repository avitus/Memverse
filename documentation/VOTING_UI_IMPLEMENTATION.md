# Voting UI Implementation Plan

## Overview
This document outlines the implementation of voting buttons in the Thredded forum UI for the feedback messageboard.

## Completed Implementation

### 1. View Overrides Created
- `/app/views/thredded/topics/_topic.html.erb` - Shows vote count badges in topic lists
- `/app/views/thredded/topics/_header.html.erb` - Shows voting buttons on topic pages
- `/app/views/thredded/topics/index.html.erb` - Adds sorting options for feedback board

### 2. Helper Methods Enhanced
- `thredded_topic_voting()` - Handles both Topic and TopicView objects
- `topic_vote_count_badge()` - Displays vote counts with appropriate styling

### 3. Styling Added
- `/app/assets/stylesheets/thredded_voting.scss` - Complete voting UI styles
- Badge styles for vote counts (green for positive, red for negative)
- Interactive voting buttons with hover states
- Responsive design that works on mobile

### 4. AJAX Functionality
- Voting happens without page reload
- Visual feedback immediately updates
- Vote counts update dynamically
- Remove vote link appears/disappears as needed

### 5. Controller Decorator
- `/app/controllers/thredded/topics_controller_decorator.rb`
- Adds vote sorting capability to feedback messageboard
- Preserves default sorting for other messageboards

## Features Implemented

### Topic List View
- Vote count badges appear next to topic titles
- Only shown for topics with non-zero votes
- Color-coded: green for positive, red for negative
- Sorting options: "Most Recent" and "Most Votes"

### Topic Detail View
- Voting buttons in the header (up/down arrows)
- Current vote score displayed between arrows
- Voted state highlighted in green (upvote) or red (downvote)
- "Remove vote" link when user has voted
- "Login to vote" prompt for anonymous users

### Behavior
- One vote per user per topic
- Clicking opposite vote changes the vote
- Clicking same vote removes it
- All actions via AJAX for smooth UX

## Technical Details

### Database Schema
The `acts_as_votable` gem creates these tables:
- `votes` - Stores all voting records
- Links to users and topics via polymorphic associations

### Security
- Only authenticated users can vote
- CSRF protection via Rails tokens
- Server-side validation prevents multiple votes

### Performance Considerations
- Vote counts are calculated on demand
- Could add caching if needed for high-traffic sites
- Sorting by votes uses SQL aggregation

## Testing the Implementation

1. Visit `/forum/feedback`
2. Create a test topic
3. Try voting up/down
4. Check vote persistence after page reload
5. Test sorting by votes
6. Verify AJAX updates work correctly

## Future Enhancements

1. **Vote Analytics**
   - Track voting trends over time
   - Show most active voters
   - Display voting statistics

2. **Enhanced Sorting**
   - Sort by "Hot" (combination of votes and recency)
   - Sort by "Controversial" (many votes, mixed sentiment)

3. **Vote Notifications**
   - Notify topic authors when their topics get votes
   - Weekly digest of top-voted items

4. **Vote Reasons**
   - Allow users to add comments when voting
   - Show vote breakdown by user type/role

5. **Vote Weights**
   - Give more weight to votes from active users
   - Consider user reputation in vote calculations

## Maintenance

- Run `rake feedback:stats` to see voting statistics
- Monitor vote table growth - consider archiving old votes
- Check AJAX error logs for failed vote attempts