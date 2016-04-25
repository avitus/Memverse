Kaminari.configure do |config|
  config.default_per_page = 15  # This is set so low to support only 15 blog posts per page
  config.window = 2
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.param_name = :page
end
