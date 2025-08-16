# Database Credentials Setup Guide

## Rails 7.1 Best Practices for Database Configuration

### Overview
Rails 7.1 recommends using encrypted credentials for storing sensitive information like database passwords. This guide explains how to properly configure database credentials for the Memverse application.

### Configuration Hierarchy

The updated `config/database.yml` uses a hierarchy of configuration sources:

1. **Environment Variables** (highest priority)
2. **Rails Credentials** (encrypted, version-controlled)
3. **Default Values** (for non-sensitive data)

### Current Configuration

```yaml
production:
  username: <%= ENV.fetch("DATABASE_USERNAME", "memverse") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD") { Rails.application.credentials.dig(:database, :password) } %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
```

This configuration:
- First checks for environment variables
- Falls back to Rails credentials
- Uses sensible defaults where appropriate

### Setting Up Credentials Locally

1. Edit credentials:
   ```bash
   EDITOR="nano" rails credentials:edit
   ```

2. Add database credentials:
   ```yaml
   database:
     password: your_secure_password_here
   ```

3. Save and exit

### Production Server Setup Options

#### Option 1: Environment Variables (Recommended for Production)
Set environment variables on the production server:

```bash
# Add to ~/.bashrc or /etc/environment
export DATABASE_USERNAME="memverse"
export DATABASE_PASSWORD="your_production_password"
export DATABASE_HOST="localhost"
```

#### Option 2: Rails Credentials
Ensure the `config/master.key` file exists on the production server:

```bash
# Copy master.key to production server
scp config/master.key user@production:/path/to/app/shared/config/
```

#### Option 3: Shared database.yml (Current Setup)
If using a shared `database.yml` on the server (symlinked during deployment), ensure it contains:

```yaml
production:
  adapter: mysql2
  database: memverse_production
  username: memverse
  password: actual_password_here
  host: localhost
  socket: /var/run/mysqld/mysqld.sock
  pool: 30
  reconnect: true
  encoding: utf8
  collation: utf8_general_ci
```

### Security Best Practices

1. **Never commit passwords to version control**
2. **Use strong, unique passwords for production**
3. **Rotate credentials regularly**
4. **Limit database user permissions to only what's needed**
5. **Use SSL/TLS for database connections when possible**

### Troubleshooting

If you encounter database connection errors:

1. Check if environment variables are set:
   ```bash
   echo $DATABASE_PASSWORD
   ```

2. Verify Rails can read credentials:
   ```bash
   rails console
   Rails.application.credentials.dig(:database, :password)
   ```

3. Test database connection:
   ```bash
   rails db:migrate:status RAILS_ENV=production
   ```

### Migration Path

Since the production server currently uses a shared `database.yml` with hardcoded credentials, you have two options:

1. **Keep current setup** (simplest): Continue using the shared `database.yml` on the server
2. **Migrate to credentials** (more secure): Update the server to use Rails credentials or environment variables

For now, to maintain compatibility with the existing setup, the database.yml supports both approaches.