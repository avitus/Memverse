# ApplicationSettings
# ========================
# Handles getting and setting our main application wide config hash.

module ApplicationSettings

  # Returns our config hash, or if empty, returns an empty hash
  def config
    @@config ||= {}
  end

  # Sets our config class variable, which we expect to be a hash
  def config=(hash)
    @@config = hash
  end

  # Awesome. Allows us to use instance methods on a Module.
  #     eg. ApplicationSettings.config
  module_function :config=, :config

end