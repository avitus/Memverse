if defined? Rails && Rails.application.config.try(:assets).try(:compile)
  require 'fancybox2/rails'
end
