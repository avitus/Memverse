module Synthesis
  autoload :AssetPackage, 'synthesis/asset_package'
  autoload :AssetPackageHelper, 'synthesis/asset_package_helper'
end

require 'synthesis/railtie' if defined?(Rails)