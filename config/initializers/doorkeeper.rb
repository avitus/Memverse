Doorkeeper.configure do
  # Change the ORM that doorkeeper will use.
  # Currently supported options are :active_record, :mongoid2, :mongoid3,
  # :mongoid4, :mongo_mapper
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    # fail "Please configure doorkeeper resource_owner_authenticator block located in #{__FILE__}"
    # Put your resource owner authentication logic here.
    # Example implementation:
    #   User.find_by_id(session[:user_id]) || redirect_to(new_user_session_url)

    # Recommended approach if using Devise (ALV)
    current_user || warden.authenticate!(:scope => :user)
  end

  # Resource owner lookup for the legacy `password` grant.
  #
  # DEPRECATED: retained only for the shipped iOS and Flutter/Android clients,
  # which authenticate with username + password. `allow_grant_flow_for_client`
  # below confines this flow to those legacy clients. Remove this block, the
  # `password` entry in `grant_flows`, and the `allow_grant_flow_for_client`
  # and `custom_access_token_expires_in` blocks once both apps have shipped an
  # authorization code + PKCE release.
  resource_owner_from_credentials do |_routes|
    request.params[:user] = { email: request.params[:username], password: request.params[:password] }
    request.env['devise.allow_params_authentication'] = true
    user = request.env['warden'].authenticate!(scope: :user)
    request.env['warden'].logout
    user
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  admin_authenticator do
    #   # Put your admin authentication logic here.
    #   # Example implementation:
    #   Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
    ( current_user && current_user.admin? ) || redirect_to( root_url )
  end

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  # access_token_expires_in 2.hours (ALV - this is the default)
  access_token_expires_in 2.hours

  # The legacy mobile clients parse neither `expires_in` nor `refresh_token`,
  # and persist the access token indefinitely. Expiring their tokens would
  # leave them presenting a dead token with no code path to recover, so the
  # legacy password grant keeps the non-expiring behaviour it was built
  # against. Everything else (PWA, Swagger UI) gets the 2 hour default.
  #
  # NOTE: returning nil here does NOT mean "never expires" - it falls through
  # to `access_token_expires_in`. Float::INFINITY is what disables expiry.
  # See doorkeeper-5.8.2 lib/doorkeeper/oauth/authorization/token.rb:26-35.
  custom_access_token_expires_in do |context|
    context.grant_type == Doorkeeper::OAuth::PASSWORD ? Float::INFINITY : 2.hours
  end

  # Assign a custom TTL for implicit grants.
  # custom_access_token_expires_in do |oauth_client|
  #   oauth_client.application.additional_settings.implicit_oauth_expiration
  # end

  # Use a custom class for generating the access token.
  # https://github.com/doorkeeper-gem/doorkeeper#custom-access-token-generator
  # access_token_generator "::Doorkeeper::JWT"

  # Reuse access token for the same resource owner within an application (disabled by default)
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  # reuse_access_token

  # Public browser clients use rotating refresh tokens for persistent sessions.
  use_refresh_token

  # Require public clients to prove they initiated each authorization request.
  force_pkce

  # Only accept hashed PKCE challenges; `plain` exposes the verifier in the
  # authorization request.
  pkce_code_challenge_methods %w[S256]

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter :confirmation => true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  # enable_application_owner :confirmation => false

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  default_scopes  :public
  optional_scopes :read, :write, :admin

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Change the native redirect uri for client apps
  # When clients register with the following redirect uri, they won't be redirected to any server and the authorization code will be displayed within the provider
  # The value can be any string. Use nil to disable this feature. When disabled, clients must provide a valid URL
  # (Similar behaviour: https://developers.google.com/accounts/docs/OAuth2InstalledApp#choosingredirecturi)
  #
  # native_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  # force_ssl_in_redirect_uri !Rails.env.development?
  force_ssl_in_redirect_uri { |uri| uri.host != 'localhost' }

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "implicit"           => Implicit Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  # If not specified, Doorkeeper enables authorization_code and
  # client_credentials.
  #
  # implicit and password grant flows have risks that you should understand
  # before enabling:
  #   http://tools.ietf.org/html/rfc6819#section-4.4.2
  #   http://tools.ietf.org/html/rfc6819#section-4.4.3
  #
  grant_flows %w[authorization_code password]

  # The `password` grant is available only to the legacy mobile clients. The
  # PWA is a public client and must use authorization code + PKCE, so it is
  # refused here even though the grant is enabled server-wide.
  allow_grant_flow_for_client do |grant_flow, client|
    grant_flow != Doorkeeper::OAuth::PASSWORD || client&.uid != PwaOauthApplication::UID
  end

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  skip_authorization do |resource_owner, client|
    # client.superapp? or resource_owner.admin?
    true # ALV - this is ok for now since apps are all trusted
  end

  # WWW-Authenticate Realm (default "Doorkeeper").
  # realm "Doorkeeper"
end
