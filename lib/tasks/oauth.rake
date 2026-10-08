namespace :oauth do
  desc 'Create or update the public Memverse PWA OAuth application'
  task ensure_pwa_application: :environment do
    application = PwaOauthApplication.ensure!
    puts "Memverse PWA OAuth client ready: #{application.uid}"
  end

  desc 'Make the Swagger UI OAuth client public and register its PKCE callback'
  task ensure_swagger_application: :environment do
    application = SwaggerOauthApplication.ensure!
    puts "Swagger UI OAuth client ready: #{application.uid}"
    puts "  confidential:  #{application.confidential}"
    puts "  redirect URIs: #{application.redirect_uri.split.join(', ')}"
  rescue ActiveRecord::RecordInvalid => e
    abort <<~MSG
      Swagger UI OAuth client was NOT changed: #{e.record.errors.full_messages.to_sentence}
      Redirect URIs it would have saved: #{e.record.redirect_uri.split.join(', ')}
      Fix or remove the invalid URI on this record, then re-run this task.
    MSG
  rescue ArgumentError => e
    abort "Swagger UI OAuth client was NOT changed: #{e.message}"
  end
end
