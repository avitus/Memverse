# Memverse Style Guide

This document defines the visual design standards and coding conventions for the Memverse application.

## Table of Contents
1. [Color Palette](#color-palette)
2. [Typography](#typography)
3. [CSS/SASS Conventions](#csssass-conventions)
4. [Component Naming](#component-naming)
5. [Layout Patterns](#layout-patterns)
6. [JavaScript/jQuery Conventions](#javascriptjquery-conventions)
7. [Accessibility](#accessibility)
8. [Responsive Design](#responsive-design)

## Heritage staging redesign

The staging branch uses the Heritage 1.4 design language. `HeritageHelper#heritage_enabled?`
enables it by default in the Rails staging environment. Set `MEMVERSE_HERITAGE=1` for local
preview or `MEMVERSE_HERITAGE=0` to restore the legacy presentation without changing data.
The implementation remains server-rendered Rails with progressive JavaScript; canvas preview
forms and sample data are not deployed.

`heritage_application.scss` is the redesign entry point. It places existing component mechanics
in a lower-priority `legacy` CSS cascade layer, then loads the Heritage foundations and page
patterns. Do not load `application.css` alongside it: that restores unlayered legacy styles.
The public homepage, signed-in Today page, navigation and footer use the same shell. The primary
Review action opens passage review; single-verse review remains available under Explore.

`heritage.scss` scopes foundation tokens and page components under `.mv-heritage`. Use warm
paper (#f7f4ee), white surfaces (#fffefd), navy text (#253b54), copper actions (#98512f),
and sage success. Georgia is used for Scripture and editorial headings; Arial is used for
controls. Native selects reserve 40px on the right and inset their chevron 14px. Interactive
controls have at least 44px targets and visible focus. The appearance control persists only
in the browser.

Shared Rails authentication lives in `devise/shared/_heritage.html.erb`. Preserve Devise
routes, CSRF tokens, reset tokens, confirmation and referral fields. Never substitute
prototype success messages for server responses. Fields use visible labels, password-manager
autocomplete, and separate Show/Hide buttons. The existing validation policy remains authoritative.

Verse collection selection survives filtering, sorting and pagination; all matching is additive.
Columns use fixed declarations, including reserved sort indicators. Compact view retains access
to all metrics through All details. Bulk deletion confirms the full selected count. Pending means
paused and preserves review history. The live search retains its 200ms timing and handles stale
responses, composition, translation changes, failed lookup and confirmed addition.

Progress charts use existing JSON endpoints, a 1 year/All time selector and accessible data tables.
Review minutes are estimated daily requirements; consistency counts sessions in the preceding year.
Passage review presents continuous Scripture and reveals ratings below the passage after typing.
The passage review shell preserves the pinned QuietReview canvas: a compact brand header,
top-right passage picker and reading help, centered heading, 25px Georgia Scripture with
1.95 line spacing (22px on mobile), and copper verse numbers and focus states. Upcoming
passages use keyboard-accessible buttons in a scrollable dropdown, above the reading area.
Successful rating saves unlock an explicit Next passage action. Awards retain original eligibility
and bronze/silver/gold finishes, using SVG medallions adapted from the approved canvas.

### Canvas coverage (November 7, 2026)

The Memverse canvas (project `462325534328770560`) has 21 components. Twenty represent
application pages or route states; the design-system component supplies shared foundations.
Canvas-only sample accounts, preview selectors, and simulated saves are replaced with Rails data
and existing server actions.

| Canvas design | Rails destination | Component / pinned revision |
| --- | --- | --- |
| Navy & copper · Landing | Signed-out `/` | 462396588447387648 / 462396588447387649 |
| Navy & copper · Today | Signed-in `/` | 462396245789532160 / 469892871043039232 |
| Dashboard · Heritage | `/users/:id` | 469887795507384320 / 469892856572694528 |
| Profile · Heritage settings | `/update_profile` | 469886147158487040 / 469892537562320896 |
| Manage verses | `/manage_verses` | 469890787795161088 / 469896406883274752 |
| Progress | `/progress` | 469897030748221440 / 469898364302028800 |
| Add verses | `/add_verse` | 469904081952063488 / 469907004144623616 |
| Passage review | `/review` | 462399451038912512 / 469892863430365184 |
| Sign in | `/users/sign_in` | 469907834654568448 / 469908814318178304 |
| Create account | `/users/sign_up` | 469907844456681472 / 469908819468750848 |
| Forgot password | `/users/password/new` | 469907849682780160 / 469911142555353088 |
| Reset password | `/users/password/edit` with reset token | 469907915847913472 / 469911147458498560 |
| Confirm email | `/users/confirmation/new` and confirmation feedback | 469907923246661632 / 469911152533594112 |
| Account access | `/users/edit` | 469907928204333056 / 469907928204333057 |
| Blog · Index | `/blog/` | 469881757005647872 / 469884771321909248 |
| Blog · Article and comments | `/blog/:blog/:article` | 469881751557263360 / 469881751557263361 |
| Blog · Browse and search | `/blog/blog_search` | 469881764224053248 / 469881764224053249 |
| Blog · Category | Blog index with `category_id` | 469881937390104576 / 469881937390104577 |
| Blog · Tag | Blog index with `tag_name` | 469881942926577664 / 469881942926577665 |
| Blog · Older posts | Blog index with `page` | 469881948446273536 / 469881948446273537 |
| Memverse · Design system | Shared tokens, controls, forms, and charts | 469884063197564928 / 469908824871018496 |

The public landing page includes the Scripture illustration, navy belief strip, blue/sage/copper
feature cards, local Psalm 23:1 practice, community links, and invitation. The Today page uses
blue review, copper retention, and sage practice panels. Its counts, queue, six-month history,
and completed-session days come only from the signed-in account. Empty histories stay empty;
prototype chart values are never substituted. Existing onboarding and devotional content remain
available below the Today panels.

`_heritage_landing.scss` adapts the pinned landing layout; `_heritage_canvas.scss` supplies the
Today panels and shared accents, with matching dark tokens. Primary actions retain copper fills
and accessible foregrounds. Blog search overrides the engine's legacy table with article results;
category, tag, and archive views share the journal layout and preserve their server filters.
Journal categories and tags use copper labels instead of the old image icons. Excerpts decode
HTML entities as plain text and remain escaped; journal search actions use the copper fill.
The dashboard includes its review entry and collection distribution; Add verses includes the
copper guidance panel and suggested passages wired to the existing live search without adding
anything until the user chooses an Add action.

## Color Palette

### Primary Colors

#### Grays (Modern with blue undertones)
- **gray-900**: `#1a1a1d` - Primary text, dark backgrounds
- **gray-800**: `#2d2d30` - Body text
- **gray-700**: `#48484a` - Secondary text
- **gray-600**: `#636366` - Tertiary text
- **gray-500**: `#6e6e73` - Muted text
- **gray-400**: `#a1a1a6` - Borders, dividers
- **gray-300**: `#b0b0b5` - Light borders
- **gray-200**: `#c7c7cc` - Background accents
- **gray-100**: `#f5f5f7` - Light backgrounds

#### Greens (Success, Growth, Achievement)
- **green-dark**: `#365314` - Dark accents
- **green-medium-dark**: `#4d7c0f` - Hover states
- **green-medium**: `#65a30d` - Active elements
- **green-primary**: `#84cc16` - Primary green (memorized verses)
- **green-light**: `#a3e635` - Highlights, badges

#### Reds (Warnings, Errors, Important)
- **red-dark**: `#993333` - Error states
- **red-primary**: `#983626` - Primary red
- **red-bright**: `#aa0101` - Alerts
- **red-orange**: `#b95c2e` - Warnings
- **red-light**: `#e17329` - Light warnings

#### Accent Colors
- **yellow-primary**: `#facc15` - Highlights, achievements
- **blue-primary**: `#3b82f6` - Links, interactive elements

### Background Colors
- **body-bg**: `#e5e5e7` - Main page background
- **white-box-bg**: `#ffffff` - Content containers

### Semantic Colors
- **success**: `$green-primary`
- **warning**: `$red-orange`
- **error**: `$red-bright`
- **info**: `$blue-primary`

## Typography

### Font Stack
```scss
font-family: 'Open Sans', Arial, Helvetica, sans-serif;
```

### Base Font Size
- **Body**: `0.8125em` (13px)
- **Line Height**: `1.5`

### Font Sizes (Tag Cloud Example)
- `.cloud1`: 80%
- `.cloud2-3`: 90%
- `.cloud4-5`: 100%
- `.cloud6`: 120%
- `.cloud7`: 140%

### Text Styling
- Links: `color: #1a1a1d`, no underline by default
- Links (hover): underline
- Visited links: maintain same color as unvisited

## CSS/SASS Conventions

### File Organization
```
app/assets/stylesheets/
├── application.scss     # Main manifest file
├── variables.scss       # Color and variable definitions
├── base.scss           # Base element styles
├── layout.scss         # Layout structure
├── mv_*.scss          # Feature-specific styles (mv_ prefix)
└── extras.scss        # Additional utilities
```

### Naming Convention
- **Feature files**: Prefix with `mv_` (e.g., `mv_home.scss`, `mv_users.scss`)
- **Engine styles**: Direct name (e.g., `thredded_voting.scss`)
- **Vendor styles**: Keep original names (e.g., `jquery.countdown.scss`)

### Class Naming Patterns

#### Semantic Classes
- **Container classes**: `.white-box-bg`, `.test-verse`, `.verse-test-area`
- **Component classes**: `.top-heading`, `.verse-ref`, `.verse-tl`
- **State classes**: `.visible`, `.focusField`, `.idleField`
- **Action classes**: `.submit`, `.toggle-hint`, `.add`

#### BEM-like Structure (where applicable)
```html
<div class="verse-test">
  <div class="verse-test-area">
    <div class="verse-test-buttons">
```

#### Table Classes
- `.tl` - Translation column
- `.ref` - Reference column
- `.txt` - Text column
- `.add` - Action column

## Component Naming

### Common Components
1. **Buttons**
   - `.submit` - Form submission buttons
   - `.test-button` - Testing interface buttons
   - `.info-button` - Information/help buttons
   - `.score-test-buttons` - Rating button containers

2. **Forms**
   - `.verseguess` - Verse input textarea
   - `#filter` - Search/filter inputs
   - `.focusField` / `.idleField` - Input states

3. **Containers** ⚠️
   - **`.white-box-bg`** - **REQUIRED**: Primary content container for ALL pages
     - Always use this as your main wrapper
     - Provides consistent styling across the application
     - Do not create custom containers with duplicate styling
   - `.mnemonic` - Mnemonic help boxes
   - `.feedback` - Feedback sections
   - `.tooltip` - Tooltip containers

4. **Navigation**
   - `.tool-tip-nav` - Navigation with tooltips
   - `#toggle-hint` - Collapsible hints

## Layout Patterns

### Standard Page Structure

**IMPORTANT**: Always use the `.white-box-bg` class as the main container for all content pages. This provides consistent padding, background, and styling across the application.

```html
<div class="white-box-bg">
  <div class="[feature-name]">
    <div class="top-heading">
      <h2>Page Title</h2>
    </div>
    <div class="[content-area]">
      <!-- Main content -->
    </div>
  </div>
</div>
```

#### Container Classes Usage:
- **`.white-box-bg`** - Primary container for ALL main content areas (forms, lists, dashboards, etc.)
  - Provides white background, proper padding, and consistent margins
  - Do NOT create custom container classes with similar styling
  - Located in base styles, available globally
- **`.white-box-with-margins`** - Legacy variant with additional margins (avoid in new code)

### Grid System
- Uses floats with classes like `.flt_rht` (float right)
- No formal grid framework currently implemented

## JavaScript/jQuery Conventions

### jQuery Usage
- **Version**: jQuery 1.12.4 (legacy, scheduled for modernization)
- **UI Library**: jQuery UI for interactions
- **No conflict mode**: Not currently enabled

### Common Patterns

#### AJAX Forms
```javascript
$('form').submit(function() {
  $.post(this.action, $(this).serialize(), null, "script");
  return false;
});
```

#### Event Delegation
```javascript
$(document).on('click', '.submit', function() {
  // Handle click
});
```

#### Filtering Pattern
```javascript
function filter(selector, query) {
  $(selector).each(function() {
    ($(this).text().search(new RegExp(query, "i")) < 0) 
      ? $(this).hide().removeClass('visible') 
      : $(this).show().addClass('visible');
  });
}
```

### Plugin Integration
- **MicroModal**: Modern modal dialogs
- **Best in Place**: In-line editing
- **PubNub**: Real-time features
- **JustGage**: Progress visualization

## Accessibility

### Current Standards
- Semantic HTML structure
- Form labels and associations
- Alt text for images
- Keyboard navigation support

### Areas for Improvement
- ARIA labels for dynamic content
- Screen reader announcements
- Focus management in SPAs
- Color contrast validation

## Responsive Design

### Breakpoints
Currently uses basic responsive patterns without formal breakpoints. Mobile support is achieved through:
- Flexible layouts
- Mobile-specific views where needed
- Responsive form elements

### Mobile Considerations
- Touch-friendly button sizes
- Simplified navigation for mobile
- Optimized verse testing interface

## Best Practices

### DO:
- Use semantic class names that describe content, not appearance
- Leverage SASS variables for colors and common values
- Maintain the `mv_` prefix for new feature styles
- Test in multiple browsers including mobile
- Keep specificity low (avoid deep nesting)

### DON'T:
- Use inline styles except when absolutely necessary
- Create global styles without proper scoping
- Use `!important` unless fixing third-party conflicts
- Mix presentation classes with JavaScript hooks
- Forget to update this guide when adding new patterns

## Migration Notes

As part of the modernization effort:
1. jQuery will be progressively replaced with vanilla JavaScript
2. CSS will migrate towards CSS Grid and Flexbox
3. A modern CSS framework (Tailwind/Bootstrap 5) is under consideration
4. Component-based styling will be introduced with the modern framework

---

*Last Updated: November 7, 2026*
