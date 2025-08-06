# Ensure Dalli is loaded early for Rails 5.x compatibility with Dalli 3.x+
require 'dalli'
# Note: Rails 5.2 has built-in session store support, no need to require action_dispatch/middleware/session/dalli_store 