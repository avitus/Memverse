# Modern Rails Credentials Deployment Guide

## Overview
This guide explains how to deploy Memverse using Rails 7.1's encrypted credentials system instead of a shared database.yml file.

## Step 1: Set Up Credentials Locally

### Option A: Use the Setup Script
```bash
ruby setup_database_credentials.rb
```

### Option B: Manual Setup
```bash
EDITOR="nano" rails credentials:edit
```

Add the following structure:
```yaml
database:
  username: memverse
  password: your_secure_password_here
  host: localhost

# Keep existing credentials like:
secret_key_base: xxx...
postmark:
  api_token: xxx...
```

## Step 2: Verify Credentials
```bash
rails console
Rails.application.credentials.database
# Should show: {:username=>"memverse", :password=>"[FILTERED]", :host=>"localhost"}
```

## Step 3: Update Production Server

### 3.1 Copy master.key to Production
The master.key is required to decrypt credentials on the server.

```bash
# From your local machine:
scp config/master.key avitus@www.memverse.com:~/memverse.com/shared/config/
```

### 3.2 Remove Old Shared database.yml
Since we're now using credentials, we need to remove the old approach:

```bash
# On production server:
cd ~/memverse.com/shared/config
mv database.yml database.yml.backup
```

### 3.3 Update Capistrano Configuration
We need to remove database.yml from linked_files since it will now come from the repository:

Edit `config/deploy.rb`:
```ruby
# Change this line:
set :linked_files, fetch(:linked_files, []).push('config/secrets.yml', 'config/secrets.yml.key', 'config/master.key', 'config/database.yml')

# To this (remove 'config/database.yml'):
set :linked_files, fetch(:linked_files, []).push('config/secrets.yml', 'config/secrets.yml.key', 'config/master.key')
```

## Step 4: Deploy

```bash
bundle exec cap production deploy
```

## Step 5: Verify Deployment

After deployment, verify the database connection:

```bash
# On production server:
cd ~/memverse.com/current
bundle exec rails console -e production
ActiveRecord::Base.connection.execute("SELECT 1")
```

## Rollback Plan

If something goes wrong:

1. Restore the shared database.yml:
   ```bash
   cd ~/memverse.com/shared/config
   mv database.yml.backup database.yml
   ```

2. Re-add database.yml to linked_files in Capistrano

3. Redeploy

## Security Benefits

1. **Encrypted at rest**: Database password is encrypted in credentials.yml.enc
2. **Version controlled**: Encrypted credentials can be safely committed
3. **Single source of truth**: No need to maintain separate database.yml files
4. **Audit trail**: Changes to credentials are tracked in git
5. **Environment consistency**: Same configuration method across all environments

## Troubleshooting

### "Missing encryption key" error
- Ensure config/master.key exists on the server
- Check permissions: `chmod 600 ~/memverse.com/shared/config/master.key`

### "Database connection failed"
- Verify credentials: `bundle exec rails credentials:show`
- Check database.yml is using credentials syntax
- Ensure master.key is correct

### "Cannot decrypt credentials"
- Master.key might be incorrect
- Try copying master.key from local machine again

## Next Steps

After successful deployment:
1. Delete the backup database.yml file
2. Document the database password in your secure password manager
3. Consider rotating the database password regularly
4. Set up monitoring for database connectivity