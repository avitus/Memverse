class PwaOauthApplication
  UID = 'memverse-pwa'.freeze
  NAME = 'Memverse PWA'.freeze
  SCOPES = 'public read write'.freeze
  DEFAULT_REDIRECT_URIS = [
    'https://avitus.github.io/Memverse/authentication/login-callback',
    'http://localhost:5078/authentication/login-callback'
  ].freeze

  def self.ensure!
    application = Doorkeeper::Application.find_or_initialize_by(uid: UID)
    application.assign_attributes(
      name: NAME,
      redirect_uri: redirect_uris.join("\n"),
      confidential: false,
      scopes: SCOPES
    )
    application.save!
    application
  end

  def self.redirect_uris
    ENV.fetch('MEMVERSE_PWA_REDIRECT_URIS', DEFAULT_REDIRECT_URIS.join(','))
       .split(',')
       .map(&:strip)
       .reject(&:empty?)
  end

  private_class_method :redirect_uris
end
