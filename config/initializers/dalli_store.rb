# Ensure Dalli is loaded early for Rails 5.x compatibility with Dalli 3.x+
require 'dalli'
require 'action_dispatch/middleware/session/dalli_store' if defined?(ActionDispatch) 