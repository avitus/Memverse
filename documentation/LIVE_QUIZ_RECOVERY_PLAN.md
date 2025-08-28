# Live Quiz Recovery Plan

## Summary of the Issue

The modern live quiz view (`live_quiz_modern.html.erb`) was deleted in commit `24028360` on August 28, 2025, which consolidated everything onto the legacy view. This resulted in the loss of significant modernization work.

## Lost Functionality from Modern View

### 1. **Stimulus Controller Integration**
The modern view used Rails 7's Stimulus framework with data attributes:
```erb
<div class="white-box-with-margins" 
     data-controller="live-quiz"
     data-live-quiz-quiz-id-value="<%= @quiz.id %>"
     data-live-quiz-user-id-value="<%= current_user.id %>"
     data-live-quiz-user-name-value="<%= current_user.name_or_login %>"
     data-live-quiz-user-login-value="<%= current_user.login %>"
     data-live-quiz-translation-value="<%= current_user.translation %>"
     data-live-quiz-num-questions-value="<%= @num_questions %>"
     data-live-quiz-pubnub-subscribe-key-value="<%= PN.env[:subscribe_key] %>"
     data-live-quiz-pubnub-publish-key-value="<%= PN.env[:publish_key] %>">
```

### 2. **Modern CSS Classes and Layout**
- Used Tailwind-like utility classes: `hidden`, `absolute`, `top-16`, `right-3`, `w-80`, `max-h-96`, `overflow-y-auto`, `bg-gray-50`, `p-4`, `rounded-lg`, `shadow-lg`, `z-10`
- Modern flexbox layouts: `flex`, `flex-wrap`, `gap-2`, `items-center`, `justify-center`
- Better organized structure with cleaner HTML

### 3. **Improved Question Dots UI**
```erb
<div class="flex flex-wrap gap-2">
  <% for q in 1..@num_questions %>
    <span class="q-dot w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center text-sm font-medium hover:bg-gray-300 transition-colors cursor-pointer"
          data-live-quiz-target="questionDot">
      <%= q %>
    </span>
  <% end %>
</div>
```

### 4. **Better Chat Integration**
Modern chat input with Stimulus targets:
```erb
<input type="text" 
       data-live-quiz-target="chatInput"
       class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
       placeholder="Type your message...">
```

### 5. **Improved Timer Display**
```erb
<div id="quiz-timer" data-live-quiz-target="timer">
  <%= @minutes %>:<%= @seconds.to_s.rjust(2, '0') %>
</div>
```

### 6. **Better Participant Count**
```erb
<span id="quizzers-count" data-live-quiz-target="participantCount">0</span>
```

## Current State (Legacy View)

The legacy view uses:
- jQuery for all interactions
- Inline styles and older CSS conventions
- No Stimulus integration
- Basic HTML structure without modern CSS classes
- Older form helpers for chat

## Recovery Strategy

### Phase 1: Create a New Modern View (Recommended)
Rather than modifying the legacy view, create a new modern view that can coexist:

1. **Create `live_quiz_modern.html.erb`** as a separate view
2. **Add a feature flag** in the controller to switch between views
3. **Progressively migrate** functionality from legacy to modern

### Phase 2: Restore Modern Features
1. **Stimulus Controller** - Create `app/javascript/controllers/live_quiz_controller.js`
2. **Modern Styles** - Add dedicated SCSS file for modern quiz styles
3. **Improved UX** - Restore the better question dots, chat, and timer UI

### Phase 3: Testing Strategy
1. Keep both views functional during transition
2. Add feature specs for modern view
3. Ensure backward compatibility

## Implementation Steps

### Step 1: Create Feature Flag
In `LiveQuizController`:
```ruby
def show
  # ... existing code ...
  
  if params[:modern] == 'true' || current_user.prefer_modern_quiz?
    render 'live_quiz_modern'
  else
    render 'live_quiz'
  end
end
```

### Step 2: Restore Modern View
Create `app/views/live_quiz/live_quiz_modern.html.erb` with the recovered content from git history.

### Step 3: Create Stimulus Controller
Create `app/javascript/controllers/live_quiz_controller.js` to handle modern interactions.

### Step 4: Add Modern Styles
Create `app/assets/stylesheets/mv_live_quiz_modern.scss` for Tailwind-compatible styles.

### Step 5: Progressive Migration
Gradually move users to the modern view once it's stable.

## Benefits of This Approach

1. **No Breaking Changes** - Legacy view remains untouched
2. **A/B Testing** - Can compare performance and user satisfaction
3. **Gradual Migration** - Move users when ready
4. **Easy Rollback** - Can revert to legacy if issues arise
5. **Clean Separation** - Modern code doesn't interfere with legacy

## Timeline

1. **Day 1**: Restore modern view file and create feature flag
2. **Day 2**: Create Stimulus controller and modern styles
3. **Day 3**: Test both views thoroughly
4. **Day 4**: Deploy with feature flag disabled by default
5. **Week 2**: Enable for beta testers
6. **Week 3**: Gradual rollout to all users

## Conclusion

The best approach is to restore the modern view as a separate file rather than trying to retrofit the legacy view. This allows for a clean separation of concerns and a gradual, safe migration path.