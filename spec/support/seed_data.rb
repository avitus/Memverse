# TODO: Skip loading seeds in tests and use FactoryBot/factories for test data instead.
unless Rails.env.test?
  require Rails.root.join('db','seeds')
end