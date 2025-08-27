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

*Last Updated: August 2025*