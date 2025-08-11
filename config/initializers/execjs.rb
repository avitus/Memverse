# Configure ExecJS to use Node.js runtime
# This fixes issues with autoprefixer-rails on production
require 'execjs'

# Force ExecJS to use Node runtime
ExecJS.runtime = ExecJS::Runtimes::Node