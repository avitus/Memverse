namespace :localeapp do
  desc 'Imports the en.yml file to the LocaleServer'
  task :import => :environment do
    require 'flatten'
    include I18n::Backend::Flatten
    yml = Locale.load_yaml_file(ENV['LOCALE_FILE'])

    yml.each do |locale, translations|
      flatten_translations(
        locale,
        translations,
        I18n::Backend::Flatten::SEPARATOR_ESCAPE_CHAR,
        nil
      ).each do |key, value|
        puts "#{key} => #{value}"
        Localeapp.sender.post_translation(locale, key, {}, value)
      end
    end
  end
end
