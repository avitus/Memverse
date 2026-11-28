# Deployment Guide for Memverse

## Overview

Memverse uses Capistrano for deployment to production servers. As of August 2025, the production deployment branch has been changed from `master` to `main`.

## Branch Configuration

- **Production Branch**: `main`
- **Ruby Version**: 3.2.6
- **Rails Version**: 7.1.5.2
- **Server**: www.memverse.com

## Deployment Configuration Files

### Primary Configuration
- `config/deploy.rb` - Main deployment configuration
  - Sets branch to `main`
  - Configures shared files and directories
  - Defines deployment tasks

### Environment-Specific Configuration
- `config/deploy/production.rb` - Production server settings
  - Server: www.memverse.com
  - User: avitus
  - Ruby version: 3.2.6

## Pre-Deployment Checklist

1. **Ensure all tests pass**
   ```bash
   bundle exec rspec
   bundle exec cucumber features
   npm test
   ```

2. **Update your local main branch**
   ```bash
   git checkout main
   git pull origin main
   ```

3. **Verify database migrations**
   ```bash
   bundle exec rake db:migrate:status
   ```

4. **Check for pending security updates**
   ```bash
   bundle audit
   ```

## Deployment Commands

### Standard Deployment
```bash
cap production deploy
```

The production deploy reuses installed gems in `shared/bundle`. Capistrano precompiles
assets once into `shared/public/assets`, saves the manifest with the release and keeps
two older fingerprints per asset. Old pages can still request their CSS and JavaScript.

### Check Deployment Status
```bash
cap production deploy:check
```

### Rollback (if needed)
```bash
cap production deploy:rollback
```

## Post-Deployment Verification

1. **Check application status**
   - Visit https://www.memverse.com
   - Test login functionality
   - Verify verse memorization features work

2. **Monitor logs**
   ```bash
   cap production logs:tail
   ```

3. **Check Sidekiq status**
   ```bash
   sudo systemctl status sidekiq
   ```

4. **Monitor error tracking**
   - Check Sentry for any new errors
   - Monitor New Relic for performance issues

## Important Notes

### Branch Change from master to main
- The production branch was changed from `master` to `main` in August 2025
- All deployments now pull from the `main` branch
- Ensure your local `main` branch is up to date before deploying

### Shared Files
The following files are shared between deployments and not stored in Git:
- `config/secrets.yml`
- `config/secrets.yml.key`
- `config/master.key`
- `config/database.yml`

### Shared Directories
The following directories persist between deployments:
- `log/`
- `tmp/pids/`
- `tmp/cache/`
- `tmp/sockets/`
- `public/ckeditor_assets/`
- `public/uploads/` (Paperclip legacy files)
- `storage/` (Active Storage files)

### Background Jobs
The scheduler and workers continue running while Capistrano prepares the release. It
waits for both systemd stop commands to succeed before running migrations, then starts
the services from `current` after publication. A preparation failure leaves jobs running.
A failure after the stop requires checking the schema and the active release before restarting jobs.
Use `SKIP_SIDEKIQ_START=1` to stop jobs at the start and keep them stopped throughout a cutover.

### Search Index
Thinking Sphinx is automatically reindexed after deployment.

## Troubleshooting

### Asset Compilation Issues
If assets fail to compile, ensure Node.js is available:
```bash
cap production deploy:assets:precompile
```

### Database Migration Failures
Keep Sidekiq stopped. Inspect the migration status and the `current` symlink, repair
or complete the migration, then retry the deploy. Start jobs manually only after
confirming the published code is compatible with the resulting schema.

### Sidekiq Issues
To restart Sidekiq manually:
```bash
cap production sidekiq:restart
```

## Emergency Procedures

### Quick Rollback
Confirm the previous release can run against the current schema. Rollback restores
its asset manifest and stops Sidekiq before switching `current`. It restarts jobs
after publication. Database changes require a separate recovery decision.
```bash
cap production deploy:rollback
```

### Manual Restart
To restart the application manually:
```bash
cap production deploy:restart
```

## Contact Information

For deployment issues or questions, contact the development team.

---

Last updated: August 2025
Branch configuration changed from `master` to `main`