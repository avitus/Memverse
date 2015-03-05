# Changelog

## 0.7.4

- bug
  - Symbols instead of strings for user input.

## 0.7.3

- enhancements
  - [#204] Allow to overwrite scope in routes
- internals
  - Returns only present keys in Token Response (may imply a backwards
    incompatible change). https://github.com/applicake/doorkeeper/issues/220
- bug
  - [#290] Support for Rails 4 when 'protected_attributes' gem is present.


## 0.7.2

- enhancements
  - [#272] Allow issuing multiple access_tokens for one user/application for multiple devices
  - [#170] Increase length of allowed redirect URIs
  - [#239] Do not try to load unavailable Request class for the current phase.
  - [#273] Relax jquery-rails gem dependency

## 0.7.1

- bug
  - [#269] Rails 3.2 raised `ActiveModel::MassAssignmentSecurity::Error`.

## 0.7.0

- enhancements
  - [#229] Rails 4!
- internals
  - [#203] Changing table name to be specific in column_names_with_table
  - [#215] README update
  - [#227] Use Rails.config.paths["config/routes"] instead of assuming "config/routes.rb" exists
  - [#262] Add jquery as gem dependency
  - [#263] Add a configuration for ActiveRecord.establish_connection
  - Deprecation and Ruby warnings (PRs merged outside of GitHub).

## 0.6.7

- internals
  - [#188] Add IDs to the show views for integration testing [@egtann](https://github.com/egtann)

## 0.6.6

- enhancements
  - [#187] Raise error if configuration is not set

## 0.6.5

- enhancements
  - [#184] Vendor the Bootstrap CSS [@tylerhunt](https://github.com/tylerhunt)

## 0.6.4

- bug
  - [#180] Add localization to authorized_applications destroy notice [@aalvarado](https://github.com/aalvarado)

## 0.6.3

- bugfixes
  - [#163] Error response content-type header should be application/json [@ggayan](https://github.com/ggayan)
  - [#175] Make token.expires_in_seconds return nil when expires_in is nil [@miyagawa](https://github.com/miyagawa)
- enhancements
  - [#166, #172, #174] Behavior to automatically authorize based on a configured proc
- internals
  - [#168] Using expectation syntax for controller specs [@rdsoze](https://github.com/rdsoze)

## 0.6.2

- bugfixes
  - [#162] Remove ownership columns from base migration template [@rdsoze](https://github.com/rdsoze)

## 0.6.1

- bugfixes
  - [#160] Removed |routes| argument from initializer authenticator blocks
- documentation
  - [#160] Fixed description of context of authenticator blocks

## 0.6.0

- enhancements
  - Mongoid `orm` configuration accepts only :mongoid2 or :mongoid3
  - Authorization endpoint does not redirect in #new action anymore. It wasn't specified by OAuth spec
  - TokensController now inherits from ActionController::Metal. There might be performance upgrades
  - Add link to authorization in Applications scaffold
  - [#116] MongoMapper support [@carols10cents](https://github.com/carols10cents)
  - [#122] Mongoid3 support [@petergoldstein](https://github.com/petergoldstein)
  - [#150] Introduce test redirect uri for applications
- bugfixes
  - [#157] Response token status should be `:ok`, not `:success` [@theycallmeswift](https://github.com/theycallmeswift)
  - [#159] Remove ActionView::Base.field_error_proc override (fixes #145)
- internals
  - Update development dependencies
  - Several refactorings
  - Rails/ORM are easily swichable with env vars (rails and orm)
  - Travis now tests against Mongoid v2

## 0.5.0.rc1

Official support for rubinius was removed.

- enhancements
  - Configure the way access token is retrieved from request (default to bearer header)
  - Authorization Code expiration time is now configurable
  - Add support for mongoid
  - [#78, #128, #137, #138] Application Ownership
  - [#92] Allow users to skip controllers
  - [#99] Remove deprecated warnings for data-* attributes [@towerhe](https://github.com/towerhe)
  - [#101] Return existing access_token for PasswordAccessTokenRequest [@benoist](https://github.com/benoist)
  - [#104] Changed access token scopes example code to default_scopes and optional_scopes [@amkirwan](https://github.com/amkirwan)
  - [#107] Fix typos in initializer
  - [#123] i18n for validator, flash messages [@petergoldstein](https://github.com/petergoldstein)
  - [#140] ActiveRecord is the default value for the ORM [@petergoldstein](https://github.com/petergoldstein)
- internals
  - [#112, #120] Replacing update_attribute with update_column to eliminate deprecation warnings [@rmoriz](https://github.com/rmoriz), [@petergoldstein](https://github.com/petergoldstein)
  - [#121] Updating all development dependencies to recent versions. [@petergoldstein](https://github.com/petergoldstein)
  - [#144] Adding MongoDB dependency to .travis.yml [@petergoldstein](https://github.com/petergoldstein)
  - [#143] Displays errors for unconfigured error messages [@timgaleckas](https://github.com/timgaleckas)
- bugfixes
  - [#102] Not returning 401 when access token generation fails [@cslew](https://github.com/cslew)
  - [#125] Doorkeeper is using ActiveRecord version of as_json in ORM agnostic code [@petergoldstein](https://github.com/petergoldstein)
  - [#142] Prevent double submission of password based authentication [@bdurand](https://github.com/bdurand)
- documentation
  - [#141] Add rack-cors middleware to readme [@gottfrois](https://github.com/gottfrois)

## 0.4.2

- bugfixes:
  - [#94] Uninitialized Constant in Password Flow

## 0.4.1

- enhancements:
  - Backport: Move doorkeeper_for extension to Filter helper

## 0.4.0

- deprecation
  - Deprecate authorization_scopes
- database changes
  - AccessToken#resource_owner_id is not nullable
- enhancements
  - [#83] Add Resource Owner Password Credentials flow [@jaimeiniesta](https://github.com/jaimeiniesta)
  - [#76] Allow token expiration to be disabled [@mattgreen](https://github.com/mattgreen)
  - [#89] Configure the way client credentials are retrieved from request
  - [#b6470a] Add Client Credentials flow
- internals
  - [#2ece8d, #f93778] Introduce Client and ErrorResponse classes

## 0.3.4

- Fix attr_accessible for rails 3.2.x

## 0.3.3

- [#86] shrink gem package size

## 0.3.2

- enhancements
  - [#54] Ignore Authorization: headers that are not Bearer [@miyagawa](https://github.com/miyagawa)
  - [#58, #64] Add destroy action to applications endpoint [@jaimeiniesta](https://github.com/jaimeiniesta), [@davidfrey](https://github.com/davidfrey)
  - [#63] TokensController responds with `401 unauthorized` [@jaimeiniesta](https://github.com/jaimeiniesta)
  - [#67, #72] Fix for mass-assignment [@cicloid](https://github.com/cicloid)
- internals
  - [#49] Add Gemnasium status image to README [@laserlemon](https://github.com/laserlemon)
  - [#50] Fix typos [@tomekw](https://github.com/tomekw)
  - [#51] Updated the factory_girl_rails dependency, fix expires_in response which returned a float number instead of integer [@antekpiechnik](https://github.com/antekpiechnik)
  - [#62] Typos, .gitignore [@jaimeiniesta](https://github.com/jaimeiniesta)
  - [#65] Change _path redirections to _url redirections [@jaimeiniesta](https://github.com/jaimeiniesta)
  - [#75] Fix unknown method #authenticate_admin! [@mattgreen](https://github.com/mattgreen)
  - Remove application link in authorized app view

## 0.3.1

- enhancements
  - [#48] Add if, else options to doorkeeper_for
  - Add views generator
- internals
  - Namespace models

## 0.3.0

- enhancements
  - [#17, #31] Add support for client credentials in basic auth header [@GoldsteinTechPartners](https://github.com/GoldsteinTechPartners)
  - [#28] Add indices to migration [@GoldsteinTechPartners](https://github.com/GoldsteinTechPartners)
  - [#29] Allow doorkeeper to run with rails 3.2 [@john-griffin](https://github.com/john-griffin)
  - [#30] Improve client's redirect uri validation [@GoldsteinTechPartners](https://github.com/GoldsteinTechPartners)
  - [#32] Add token (implicit grant) flow [@GoldsteinTechPartners](https://github.com/GoldsteinTechPartners)
  - [#34] Add support for custom unathorized responses [@GoldsteinTechPartners](https://github.com/GoldsteinTechPartners)
  - [#36] Remove repetitions from the Authorised Applications view [@carvil](https://github.com/carvil)
  - When user revoke an application, all tokens for that application are revoked
  - Error messages now can be translated
  - Install generator copies the error messages localization file
- internals
  - Fix deprecation warnings in ActiveSupport::Base64
  - Remove deprecation in doorkeeper_for that handles hash arguments
  - Depends on railties instead of whole rails framework
  - CI now integrates with rails 3.1 and 3.2

## 0.2.0

- enhancements
  - [#4] Add authorized applications endpoint
  - [#5, #11] Add access token scopes
  - [#10] Add access token expiration by default
  - [#9, #12] Add refresh token flow
- internals
  - [#7] Improve configuration options with :default
  - Improve configuration options with :builder
  - Refactor config class
  - Improve coverage of authorization request integration
- bug fixes
  - [#6, #20] Fix access token response headers
  - Fix issue with state parameter
- deprecation
  - deprecate :only and :except options in doorkeeper_for

## 0.1.1

- enhancements
  - [#3] Authorization code must be short lived and single use
  - [#2] Improve views provided by doorkeeper
  - [#1] Skips authorization form if the client has been authorized by the resource owner
  - Improve readme
- bugfixes
  - Fix issue when creating the access token (wrong client id)

## 0.1.0

- Authorization Code flow
- OAuth applications endpoint
