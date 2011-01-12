# Pull in the ZiYa gem framework
require 'ziya'

# Initializes the ZiYa Framework
Ziya.initialize(
  :logger     => Rails.logger,
  :themes_dir => File.join( File.dirname(__FILE__), %w[.. .. public charts themes])
)
