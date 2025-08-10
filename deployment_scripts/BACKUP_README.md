# Memverse Backup Process

## Working Backup Solution

After testing multiple approaches, the **verified_backup.sh** script is the only reliable backup method that properly handles MySQL permissions and verifies the backup integrity.

## How to Use

### 1. Copy the script to the server
```bash
scp deployment_scripts/verified_backup.sh avitus@www.memverse.com:/tmp/
```

### 2. Run the backup
```bash
ssh avitus@www.memverse.com
chmod +x /tmp/verified_backup.sh
/tmp/verified_backup.sh
```

### 3. Follow the prompts
- The script will prompt for the MySQL password
- It will test the connection before attempting backup
- It will verify the backup actually contains data

## What the Script Does

1. **Tests Database Connection** - Ensures password is correct before proceeding
2. **Creates Database Backup** - Uses `--no-tablespaces` to avoid PROCESS privilege issues
3. **Verifies Backup** - Checks file size and line count to ensure backup succeeded
4. **Backs Up Code** - Archives current deployment and releases
5. **Backs Up Paperclip Files** - Critical for Active Storage migration
6. **Creates Verification Script** - Allows you to verify backup integrity later

## Important Notes

- The MySQL user `memverse` does not have PROCESS privilege, so we use `--no-tablespaces`
- The password is stored in `Rails.application.secrets[:mysql]`
- Always verify the backup contains actual data (check line count)
- Keep backups until Active Storage migration is verified

## Backup Location

Backups are stored in:
- `/var/backups/memverse/rails7_upgrade_YYYYMMDD_HHMMSS/`
- Symlink to latest: `/var/backups/memverse/latest_rails7_backup`

## Files Created

- `database_full.sql.gz` - Compressed database backup
- `code_backup.tar.gz` - Application code
- `paperclip_*.tar.gz` - Paperclip file attachments
- `verify_backup.sh` - Script to verify backup integrity
- `RESTORE_INSTRUCTIONS.txt` - How to restore from this backup

## Why Other Methods Failed

1. **Capistrano Tasks** - RVM loading issues and shell escaping problems
2. **Direct mysqldump** - PROCESS privilege requirement caused silent failures
3. **Rails Runner** - Bundle command not found in SSH session

The verified_backup.sh script avoids all these issues by:
- Running directly on the server
- Prompting for password instead of trying to extract it
- Using mysqldump options that don't require special privileges
- Actually verifying the backup succeeded