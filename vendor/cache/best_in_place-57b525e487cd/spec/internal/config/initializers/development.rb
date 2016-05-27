if ENV['dev']
  Rails.application.configure do
    config.cache_classes = false
    config.eager_load = false
    config.assets.debug = true
  end
end
I18n.enforce_available_locales = true