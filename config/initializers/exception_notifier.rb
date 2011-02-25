# No longer using exception notification - using Exceptional web service instead

#admin_email = YAML.load_file("#{Rails.root}/config/settings.yml")[RAILS_ENV]['admin_email']
#ExceptionNotifier.exception_recipients = admin_email