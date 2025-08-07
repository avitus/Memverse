namespace :paperclip do
  desc "Migrate Paperclip attachments to Active Storage"
  task migrate_to_active_storage: :environment do
    require 'open-uri'
    require 'fileutils'
    
    puts "Starting Paperclip to Active Storage migration..."
    puts "=" * 50
    
    # Track migration statistics
    stats = {
      sermon_mp3s: { migrated: 0, failed: 0, skipped: 0 },
      ckeditor_pictures: { migrated: 0, failed: 0, skipped: 0 },
      ckeditor_attachments: { migrated: 0, failed: 0, skipped: 0 }
    }
    
    # Migrate Sermon MP3 files
    puts "\nMigrating Sermon MP3 files..."
    Sermon.find_each do |sermon|
      next unless sermon.mp3_file_name.present?
      
      begin
        # Skip if already migrated
        if sermon.respond_to?(:mp3_attachment) && sermon.mp3_attachment.attached?
          stats[:sermon_mp3s][:skipped] += 1
          print "S"
          next
        end
        
        # Construct Paperclip file path
        paperclip_path = Rails.root.join(
          'public', 'system', 'sermons', 'mp3s',
          sermon.id.to_s.rjust(9, '0').scan(/\d{3}/).join('/'),
          'original', sermon.mp3_file_name
        )
        
        if File.exist?(paperclip_path)
          sermon.mp3_attachment.attach(
            io: File.open(paperclip_path),
            filename: sermon.mp3_file_name,
            content_type: sermon.mp3_content_type
          )
          stats[:sermon_mp3s][:migrated] += 1
          print "."
        else
          puts "\n  Warning: File not found for Sermon ##{sermon.id}: #{paperclip_path}"
          stats[:sermon_mp3s][:failed] += 1
          print "F"
        end
      rescue => e
        puts "\n  Error migrating Sermon ##{sermon.id}: #{e.message}"
        stats[:sermon_mp3s][:failed] += 1
        print "E"
      end
    end
    
    # Migrate CKEditor Pictures
    puts "\n\nMigrating CKEditor Pictures..."
    Ckeditor::Picture.find_each do |picture|
      next unless picture.data_file_name.present?
      
      begin
        # Skip if already migrated
        if picture.respond_to?(:data_attachment) && picture.data_attachment.attached?
          stats[:ckeditor_pictures][:skipped] += 1
          print "S"
          next
        end
        
        # Try to find the original file
        original_path = Rails.root.join(
          'public', 'ckeditor_assets', 'pictures',
          picture.id.to_s, "original_#{picture.data_file_name}"
        )
        
        # If original doesn't exist, try without prefix
        unless File.exist?(original_path)
          original_path = Rails.root.join(
            'public', 'ckeditor_assets', 'pictures',
            picture.id.to_s, picture.data_file_name
          )
        end
        
        if File.exist?(original_path)
          picture.data_attachment.attach(
            io: File.open(original_path),
            filename: picture.data_file_name,
            content_type: picture.data_content_type
          )
          stats[:ckeditor_pictures][:migrated] += 1
          print "."
        else
          puts "\n  Warning: File not found for Picture ##{picture.id}: #{original_path}"
          stats[:ckeditor_pictures][:failed] += 1
          print "F"
        end
      rescue => e
        puts "\n  Error migrating Picture ##{picture.id}: #{e.message}"
        stats[:ckeditor_pictures][:failed] += 1
        print "E"
      end
    end
    
    # Migrate CKEditor Attachment Files
    puts "\n\nMigrating CKEditor Attachment Files..."
    Ckeditor::AttachmentFile.find_each do |attachment|
      next unless attachment.data_file_name.present?
      
      begin
        # Skip if already migrated
        if attachment.respond_to?(:data_attachment) && attachment.data_attachment.attached?
          stats[:ckeditor_attachments][:skipped] += 1
          print "S"
          next
        end
        
        # Construct Paperclip file path
        paperclip_path = Rails.root.join(
          'public', 'ckeditor_assets', 'attachments',
          attachment.id.to_s, attachment.data_file_name
        )
        
        if File.exist?(paperclip_path)
          attachment.data_attachment.attach(
            io: File.open(paperclip_path),
            filename: attachment.data_file_name,
            content_type: attachment.data_content_type
          )
          stats[:ckeditor_attachments][:migrated] += 1
          print "."
        else
          puts "\n  Warning: File not found for Attachment ##{attachment.id}: #{paperclip_path}"
          stats[:ckeditor_attachments][:failed] += 1
          print "F"
        end
      rescue => e
        puts "\n  Error migrating Attachment ##{attachment.id}: #{e.message}"
        stats[:ckeditor_attachments][:failed] += 1
        print "E"
      end
    end
    
    # Print migration summary
    puts "\n\n" + "=" * 50
    puts "Migration Summary:"
    puts "=" * 50
    
    stats.each do |model, counts|
      total = counts.values.sum
      puts "\n#{model.to_s.humanize}:"
      puts "  Total records: #{total}"
      puts "  Migrated: #{counts[:migrated]}"
      puts "  Skipped (already migrated): #{counts[:skipped]}"
      puts "  Failed: #{counts[:failed]}"
    end
    
    puts "\n" + "=" * 50
    puts "Migration completed!"
    
    if stats.values.any? { |counts| counts[:failed] > 0 }
      puts "\nWARNING: Some files failed to migrate. Please check the logs above."
    else
      puts "\nAll files migrated successfully!"
    end
  end
  
  desc "Verify Active Storage migration"
  task verify_migration: :environment do
    puts "Verifying Active Storage migration..."
    puts "=" * 50
    
    issues = []
    
    # Check Sermons
    puts "\nChecking Sermons..."
    Sermon.where.not(mp3_file_name: nil).find_each do |sermon|
      if sermon.respond_to?(:mp3_attachment) && !sermon.mp3_attachment.attached?
        issues << "Sermon ##{sermon.id}: MP3 not migrated (#{sermon.mp3_file_name})"
      end
    end
    
    # Check CKEditor Pictures
    puts "Checking CKEditor Pictures..."
    Ckeditor::Picture.where.not(data_file_name: nil).find_each do |picture|
      if picture.respond_to?(:data_attachment) && !picture.data_attachment.attached?
        issues << "Picture ##{picture.id}: Image not migrated (#{picture.data_file_name})"
      end
    end
    
    # Check CKEditor Attachments
    puts "Checking CKEditor Attachments..."
    Ckeditor::AttachmentFile.where.not(data_file_name: nil).find_each do |attachment|
      if attachment.respond_to?(:data_attachment) && !attachment.data_attachment.attached?
        issues << "Attachment ##{attachment.id}: File not migrated (#{attachment.data_file_name})"
      end
    end
    
    puts "\n" + "=" * 50
    if issues.empty?
      puts "✅ All files successfully migrated to Active Storage!"
    else
      puts "❌ Found #{issues.count} migration issues:"
      issues.each { |issue| puts "  - #{issue}" }
    end
  end
  
  desc "Clean up old Paperclip files after successful migration"
  task cleanup: :environment do
    puts "This will remove all Paperclip files. Make sure you have:"
    puts "  1. Successfully migrated all files (run rake paperclip:verify_migration)"
    puts "  2. Created backups of all Paperclip directories"
    puts "\nType 'yes' to continue: "
    
    response = STDIN.gets.chomp
    unless response.downcase == 'yes'
      puts "Cleanup cancelled."
      exit
    end
    
    puts "\nCleaning up Paperclip files..."
    
    # Remove Paperclip directories
    directories = [
      Rails.root.join('public', 'system', 'sermons'),
      Rails.root.join('public', 'ckeditor_assets', 'pictures'),
      Rails.root.join('public', 'ckeditor_assets', 'attachments')
    ]
    
    directories.each do |dir|
      if Dir.exist?(dir)
        puts "Removing #{dir}..."
        FileUtils.rm_rf(dir)
      end
    end
    
    puts "Cleanup completed!"
  end
end