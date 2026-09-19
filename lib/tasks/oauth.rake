namespace :oauth do
  desc 'Create or update the public Memverse PWA OAuth application'
  task ensure_pwa_application: :environment do
    application = PwaOauthApplication.ensure!
    puts "Memverse PWA OAuth client ready: #{application.uid}"
  end
end
