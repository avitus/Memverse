# Memverse Style Guide

*Last Updated: August 5, 2025*

This document defines the visual design standards and CSS conventions for the Memverse application. All new features and updates should follow these guidelines to maintain consistency across the platform.

## Table of Contents
- [Color Palette](#color-palette)
- [Typography](#typography)
- [Spacing & Layout](#spacing--layout)
- [Components](#components)
- [Forms & Inputs](#forms--inputs)
- [Buttons](#buttons)
- [Modals & Overlays](#modals--overlays)
- [Tables](#tables)
- [Responsive Design](#responsive-design)
- [CSS Conventions](#css-conventions)

---

## Color Palette

### Primary Colors

#### Greys (Main UI Colors)
```scss
$black-text:      #1F2229;  // Almost black - primary text, links
$dark-grey:       #262626;  // Dark grey
$text-primary:    #333333;  // Main text color
$text-secondary:  #555555;  // Secondary text
$text-muted:      #666666;  // Muted text
$grey-medium:     #717171;  // Medium grey
$grey-light:      #a6a4a4;  // Light grey
$border-dark:     #afaeae;  // Dark borders
$border-light:    #bfbebe;  // Light borders, body background
$background:      #f2f1f1;  // Light background for panels
```

#### Greens (Action Colors)
```scss
$green-darkest:   #3c5313;  // Darkest green
$green-dark:      #577a1a;  // Dark green
$green-primary:   #6B9620;  // Primary green (buttons, actions)
$green-hover:     #7ca529;  // Green hover state
$green-menu:      #99cc33;  // Menu green (#9c3)
```

#### Accent Colors
```scss
$red-dark:        #993333;  // Dark red
$red-error:       #aa0101;  // Error red
$red-accent:      #983626;  // Red accent
$orange-dark:     #b95c2e;  // Dark orange
$orange-light:    #e17329;  // Light orange
$yellow:          #ffcc00;  // Yellow (#fc0)
$blue:            #1f8ec2;  // Blue
```

### Semantic Colors
```scss
$color-success:   #6B9620;  // Green
$color-error:     #aa0101;  // Red
$color-warning:   #ffcc00;  // Yellow
$color-info:      #1f8ec2;  // Blue
```

---

## Typography

### Font Stack
```scss
$font-family-base: 'Open Sans', Arial, Helvetica, sans-serif;
```

### Font Sizes
```scss
$font-size-base:   0.8125em;  // 13px (base)
$font-size-small:  0.875rem;  // 14px
$font-size-large:  1.125rem;  // 18px
$font-size-h1:     2rem;      // 32px
$font-size-h2:     1.5rem;    // 24px
$font-size-h3:     1.25rem;   // 20px
$font-size-h4:     1.125rem;  // 18px
```

### Line Heights
```scss
$line-height-base:    1.5;
$line-height-heading: 1.25;
$line-height-tight:   1.15;
```

### Font Weights
```scss
$font-weight-normal: 400;
$font-weight-bold:   600;
$font-weight-heavy:  700;
```

---

## Spacing & Layout

### Spacing Scale
```scss
$spacing-xs:   0.25rem;  // 4px
$spacing-sm:   0.5rem;   // 8px
$spacing-md:   1rem;     // 16px
$spacing-lg:   1.5rem;   // 24px
$spacing-xl:   2rem;     // 32px
$spacing-xxl:  3rem;     // 48px
```

### Container Widths
```scss
$container-width:      1080px;  // Main wrapper
$container-width-lg:   1280px;  // Large container
```

### Border Radius
```scss
$border-radius-sm:     4px;     // Small elements (buttons)
$border-radius-base:   5px;     // Default radius
$border-radius-lg:     8px;     // Large elements
```

---

## Components

### Panels & Cards
```scss
.panel {
  background-color: #f2f1f1;
  border: 1px solid #bfbebe;
  border-radius: 5px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.panel-header {
  border-bottom: 1px solid #bfbebe;
  padding-bottom: 1rem;
  margin-bottom: 1rem;
}
```

### Shadows
```scss
$shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.08);
$shadow-base: 0 4px 6px rgba(0, 0, 0, 0.1), 0 1px 3px rgba(0, 0, 0, 0.08);
$shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.15);
```

---

## Forms & Inputs

### Input Styles
```scss
input[type="text"],
input[type="email"],
input[type="password"],
textarea,
select {
  font-family: $font-family-base;
  font-size: $font-size-base;
  padding: 0.5rem;
  border: 1px solid #bfbebe;
  border-radius: 4px;
  background-color: #fff;
  color: #333;
  
  &:focus {
    outline: none;
    border-color: #6B9620;
    box-shadow: 0 0 0 2px rgba(107, 150, 32, 0.2);
  }
}
```

### Labels
```scss
label {
  display: block;
  margin-bottom: 0.25rem;
  color: #333;
  font-weight: 600;
}
```

---

## Buttons

### Base Button
```scss
.btn {
  font-family: $font-family-base;
  font-size: 0.875rem;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 0.2s ease;
  line-height: 1.15;
  text-decoration: none;
  display: inline-block;
  
  &:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
  }
}
```

### Button Variants

#### Primary (Green)
```scss
.btn-primary,
.green-button {
  background-color: #6B9620;
  color: #fff;
  border-color: #577a1a;
  text-shadow: 0 -1px 1px rgba(0, 0, 0, 0.25);
  font-weight: bold;
  
  &:hover {
    background-color: #7ca529;
    border-color: #577a1a;
  }
}
```

#### Secondary (Grey)
```scss
.btn-secondary {
  background-color: #bfbebe;
  color: #333;
  border-color: #afaeae;
  
  &:hover {
    background-color: #afaeae;
    border-color: #717171;
  }
}
```

#### Button Sizes
```scss
.btn-sm {
  padding: 0.25rem 0.75rem;
  font-size: 0.75rem;
}

.btn-lg {
  padding: 0.75rem 1.5rem;
  font-size: 1.125rem;
}
```

---

## Modals & Overlays

### Modal Container
```scss
.modal {
  background-color: #f2f1f1;
  border: 1px solid #bfbebe;
  border-radius: 5px;
  padding: 25px 30px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 0 1px 3px rgba(0, 0, 0, 0.08);
}

.modal-overlay {
  background: rgba(31, 34, 41, 0.75); // Using #1F2229
}

.modal-header {
  border-bottom: 1px solid #bfbebe;
  padding-bottom: 15px;
  margin-bottom: 20px;
}

.modal-title {
  color: #1F2229;
  font-size: 1.25rem;
  font-weight: 600;
}
```

---

## Tables

### Basic Table
```scss
table {
  width: 100%;
  border-collapse: collapse;
  margin: 1em 0;
}

th, td {
  padding: 0.5em;
  text-align: left;
  border-bottom: 1px solid #bfbebe;
}

th {
  background-color: #afaeae;
  color: #1F2229;
  font-weight: 600;
}

tbody tr:hover {
  background-color: #f9f9f9;
}
```

---

## Responsive Design

### Breakpoints
```scss
$breakpoint-xs: 480px;   // Mobile
$breakpoint-sm: 768px;   // Tablet
$breakpoint-md: 1024px;  // Desktop
$breakpoint-lg: 1280px;  // Large desktop
```

### Media Query Mixins
```scss
@mixin mobile {
  @media (max-width: #{$breakpoint-sm - 1px}) {
    @content;
  }
}

@mixin tablet {
  @media (min-width: #{$breakpoint-sm}) and (max-width: #{$breakpoint-md - 1px}) {
    @content;
  }
}

@mixin desktop {
  @media (min-width: #{$breakpoint-md}) {
    @content;
  }
}
```

---

## CSS Conventions

### Naming Convention
- Use hyphenated lowercase for class names: `.my-class-name`
- Use descriptive names that indicate purpose: `.verse-list`, `.quiz-question`
- Prefix JavaScript hooks with `js-`: `.js-toggle-modal`

### File Organization
```
app/assets/stylesheets/
├── base.scss           # Base styles, resets
├── layout.scss         # Layout and structure
├── mv_*.scss          # Feature-specific styles (mv_verse.scss, mv_quiz.scss)
├── vendor/            # Third-party styles
└── micromodal.css     # Modal library styles
```

### SCSS Best Practices
1. **Nesting**: Limit nesting to 3 levels deep
2. **Variables**: Use variables for repeated values
3. **Mixins**: Create mixins for repeated patterns
4. **Comments**: Document complex sections
5. **Ordering**: Structure properties logically:
   - Positioning (position, top, right, etc.)
   - Box model (display, width, height, padding, margin)
   - Typography (font, line-height, text-align)
   - Visual (background, border, box-shadow)
   - Animation (transition, animation)

### Example Component
```scss
// Quiz question component
.quiz-question {
  // Structure
  position: relative;
  display: block;
  margin-bottom: $spacing-lg;
  
  // Box model
  padding: $spacing-md;
  
  // Visual
  background-color: $background;
  border: 1px solid $border-light;
  border-radius: $border-radius-base;
  
  // States
  &:hover {
    border-color: $border-dark;
  }
  
  // Child elements
  &__title {
    margin-bottom: $spacing-sm;
    color: $black-text;
    font-size: $font-size-h4;
    font-weight: $font-weight-bold;
  }
  
  &__content {
    color: $text-primary;
    line-height: $line-height-base;
  }
}
```

---

## Usage Guidelines

1. **Consistency**: Always use defined color variables rather than hard-coded values
2. **Accessibility**: Ensure sufficient color contrast (WCAG AA standards)
3. **Performance**: Combine similar selectors and minimize specificity
4. **Maintainability**: Document any deviations from the style guide

---

## References
- [CLAUDE.md](./CLAUDE.md) - Development guidelines
- [UPGRADE_PLAN.md](./UPGRADE_PLAN.md) - Modernization roadmap