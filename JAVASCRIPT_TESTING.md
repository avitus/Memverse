# JavaScript Testing with Vitest

This project uses Vitest for JavaScript unit testing. Vitest is a fast, modern testing framework that provides excellent developer experience and compatibility with existing test patterns.

## Setup

1. Install Node.js dependencies:
   ```bash
   npm install
   ```

2. Run tests:
   ```bash
   npm test          # Run tests in watch mode
   npm run test:run  # Run tests once and exit
   ```

## Additional Commands

- **Test UI**: `npm run test:ui` - Opens a browser-based UI for exploring and debugging tests
- **Coverage**: `npm run test:coverage` - Generates test coverage reports

## Test Structure

JavaScript tests are located in `/test/javascript/`:
- `*.test.js` - Test files using Vitest's test syntax
- `helpers.js` - Shared utilities for loading JavaScript source files
- `setup.js` - Global test setup including jQuery mocks

## Writing Tests

```javascript
import { describe, it, expect } from 'vitest';
import { functionToTest } from './helpers.js';

describe('Feature Name', () => {
  it('should do something', () => {
    const result = functionToTest('input');
    expect(result).toBe('expected output');
  });
});
```

## Migrating from Jasmine

This project was migrated from Jasmine to Vitest in August 2025. The migration involved:
- Moving tests from `/spec/javascripts/` to `/test/javascript/`
- Converting Jasmine syntax to Vitest syntax
- Creating jQuery mocks for Node.js environment
- Updating CI/CD configuration

## CI/CD Integration

The CircleCI configuration has been updated to:
1. Install Node.js dependencies
2. Run Vitest tests as part of the test suite
3. Cache node_modules for faster builds

## Troubleshooting

- If tests fail with jQuery-related errors, check the jQuery mock in `/test/javascript/setup.js`
- For missing global functions, ensure they're exported in `/test/javascript/helpers.js`
- Use `npm run test:ui` to debug individual test failures interactively