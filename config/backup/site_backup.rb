# encoding: utf-8

##
# Backup Generated: site_backup
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t site_backup [-c <path_to_configuration_file>]
#

database_yml = File.expand_path('../../database.yml',  __FILE__)
RAILS_ENV    = ENV['RAILS_ENV'] || 'development'

require 'yaml'
config = YAML.load_file(database_yml)

Backup::Model.new(:site_backup, 'Description for site_backup') do
  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 250 megabytes
  # if the backup file size exceeds 250 megabytes
  #
  split_into_chunks_of 100
  ##
  # Archive [Archive]
  #
  # Adding a file:
  #   archive.add "/path/to/a/file.rb"
  #
  # Adding an directory (including sub-directories):
  #   archive.add "/path/to/a/directory/"
  #
  # Excluding a file:
  #   archive.exclude "/path/to/an/excluded_file.rb"
  #
  # Excluding a directory (including sub-directories):
  #   archive.exclude "/path/to/an/excluded_directory/
  #
  archive :my_archive do |archive|
    archive.add "/memverse.com/shared/public"
    # archive.exclude "/path/to/a/excluded_file.rb"
    # archive.exclude "/path/to/a/excluded_folder/"
  end

  database MySQL do |db|
    db.name               = config[RAILS_ENV]["database"]
    db.username           = config[RAILS_ENV]["username"]
    db.password           = config[RAILS_ENV]["password"]
    db.host               = config[RAILS_ENV]["host"]
    db.port               = config[RAILS_ENV]["port"]
    db.socket             = config[RAILS_ENV]["socket"]
    db.skip_tables        = []
  end

  ##
  # Local (Copy) [Storage]
  #
  store_with Local do |local|
    local.path       = "~/memverse.com/auto_backup"
    local.keep       = 5
  end

  ##
  # Dropbox File Hosting Service [Storage]
  #
  # Access Type:
  #
  #  - :app_folder (Default)
  #  - :dropbox
  #
  # Note:
  #
  #  Initial backup must be performed manually to authorize
  #  this machine with your Dropbox account.
  #
  store_with Dropbox do |db|
    db.api_key     = "hum0xzpxp80o5mi"
    db.api_secret  = "5y5s5ltv2vyepzg"
    db.access_type = :app_folder
    db.path        = "/"
    db.keep        = 25
  end

  ##
  # Gzip [Compressor]
  #
  compress_with Gzip

  ##
  # Mail [Notifier]
  #
  # The default delivery method for Mail Notifiers is 'SMTP'.
  # See the Wiki for other delivery options.
  # https://github.com/meskyanichi/backup/wiki/Notifiers
  #
#  notify_by Mail do |mail|
#    mail.on_success           = false
#    mail.on_warning           = true
#    mail.on_failure           = true

#    mail_settings = ActionMailer::Base.smtp_settings

#    mail.from                 = mail_settings.user_name
#    mail.to                   = "admin@memverse.com, alexcwatt@memverse.com"
#    mail.address              = mail_settings.address
#    mail.port                 = 587
#    mail.domain               = mail_settings.domain
#    mail.user_name            = mail_settings.user_name
#    mail.password             = mail_settings.password
#    mail.authentication       = mail_settings.authentication
#    mail.enable_starttls_auto = mail_settings.enable_starttls_auto
#  end

end
