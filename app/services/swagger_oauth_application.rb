# Reconciles the OAuth client that the Swagger UI at /api uses.
#
# Swagger moved from the implicit grant to authorization code + PKCE. A browser
# cannot keep a client secret, so the client must be public, and the PKCE
# callback must be registered as an exact redirect URI.
#
# Unlike PwaOauthApplication, this record predates the code and its production
# contents cannot be seen from here, so `ensure!` only ever adds: it keeps every
# existing redirect URI and scope, and leaves the secret in place. Doorkeeper
# still verifies a secret that a caller supplies to a public client, so anything
# already authenticating with this client's secret keeps working.
class SwaggerOauthApplication
  # Must match the clientId in public/api/index.html.
  UID = '27fe637fbd8c430efac4c2ba97bc490eb1c01604d7c16b70b9cd66d8427c53e5'.freeze
  NAME = 'Memverse API Docs'.freeze
  SCOPES = 'public read write'.freeze
  DEFAULT_REDIRECT_URIS = ['https://www.memverse.com/api/o2c.html'].freeze

  def self.ensure!
    application = Doorkeeper::Application.find_or_initialize_by(uid: UID)
    if application.new_record?
      application.name = NAME
      application.scopes = SCOPES
    end
    application.confidential = false
    application.redirect_uri = (application.redirect_uri.to_s.split | redirect_uris).join("\n")
    application.save!
    application
  end

  def self.redirect_uris
    ENV.fetch('MEMVERSE_SWAGGER_REDIRECT_URIS', DEFAULT_REDIRECT_URIS.join(','))
       .split(',')
       .map(&:strip)
       .reject(&:empty?)
  end

  private_class_method :redirect_uris
end
