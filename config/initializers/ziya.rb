# Pull in the ZiYa gem framework
gem 'derailed-ziya', '= 2.1.5'
require 'ziya'

# Initializes the ZiYa Framework
Ziya.initialize( 
  :logger     => RAILS_DEFAULT_LOGGER,
  :themes_dir => File.join( File.dirname(__FILE__), %w[.. .. public charts themes]) 
)
