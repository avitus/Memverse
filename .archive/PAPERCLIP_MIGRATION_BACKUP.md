# Paperclip to Active Storage Migration - Backup Documentation
*Created: 2025-08-07*

## CRITICAL: Backup Checklist

### Before Starting Migration:

1. **Database Backup**
   ```bash
   # Create timestamped database backup
   mysqldump -u [username] -p memverse_production > memverse_production_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **File System Backup**
   ```bash
   # Backup all Paperclip attachment directories
   tar -czf paperclip_files_backup_$(date +%Y%m%d_%H%M%S).tar.gz \
     public/system/ \
     public/ckeditor_assets/
   ```

3. **Current Attachment Inventory**
   
   ### Sermon Model Attachments
   - **Location**: `public/system/sermons/mp3s/`
   - **Database fields**: 
     - mp3_file_name
     - mp3_content_type
     - mp3_file_size
     - mp3_updated_at
   
   ### CKEditor Picture Attachments
   - **Location**: `public/ckeditor_assets/pictures/`
   - **URL Pattern**: `/ckeditor_assets/pictures/:id/:style_:basename.:extension`
   - **Styles**: 
     - original
     - content (800px max width)
     - thumb (118x100px)
   
   ### CKEditor File Attachments
   - **Location**: `public/ckeditor_assets/attachments/`
   - **URL Pattern**: `/ckeditor_assets/attachments/:id/:filename`

4. **Database Column Preservation**
   ```sql
   -- Backup existing Paperclip columns before migration
   CREATE TABLE sermons_paperclip_backup AS SELECT * FROM sermons;
   CREATE TABLE ckeditor_assets_paperclip_backup AS SELECT * FROM ckeditor_assets;
   ```

## Rollback Plan

### If Migration Fails:

1. **Restore Database**
   ```bash
   mysql -u [username] -p memverse_production < memverse_production_[timestamp].sql
   ```

2. **Restore Files**
   ```bash
   tar -xzf paperclip_files_backup_[timestamp].tar.gz -C /
   ```

3. **Revert Code**
   ```bash
   git checkout [pre-migration-commit]
   bundle install
   ```

## File Mapping for Migration

### Sermon MP3 Files
- **From**: `public/system/sermons/mp3s/[id]/original/[filename]`
- **To**: Active Storage blob storage

### CKEditor Pictures
- **From**: `public/ckeditor_assets/pictures/[id]/[style]_[filename]`
- **To**: Active Storage with variants

### CKEditor Attachments
- **From**: `public/ckeditor_assets/attachments/[id]/[filename]`
- **To**: Active Storage blob storage

## Verification Checklist

After migration, verify:
- [ ] All sermon MP3 files are accessible
- [ ] All CKEditor images display correctly
- [ ] All CKEditor file attachments download properly
- [ ] No broken links in existing content
- [ ] File upload functionality works for new files
- [ ] Database integrity maintained