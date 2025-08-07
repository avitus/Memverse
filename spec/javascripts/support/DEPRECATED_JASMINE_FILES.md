# Deprecated Jasmine Files

These files were part of the Jasmine JavaScript testing framework which has been replaced with Vitest as of August 2025.

## Migration Information
- JavaScript tests have been migrated to `/test/javascript/`
- Test runner: Vitest (npm test)
- Configuration: `/vitest.config.js`

## Legacy Files (Can be removed after confirming no deployment dependencies)
- jasmine_config.rb
- jasmine_helper.rb  
- jasmine_runner.rb
- jasmine.yml
- jquery-2.0.2.min.js (jQuery test dependency)
- jquery-ui.min.js (jQuery UI test dependency)

## New Test Commands
- Run tests: `npm test` or `npm run test:run`
- Watch mode: `npm test`
- Test UI: `npm run test:ui`
- Coverage: `npm run test:coverage`