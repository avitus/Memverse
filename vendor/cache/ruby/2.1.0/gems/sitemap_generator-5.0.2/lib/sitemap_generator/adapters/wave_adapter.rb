begin
  require 'carrierwave'
rescue LoadError
  raise LoadError.new("Missing required 'carrierwave'.  Please 'gem install carrierwave' and require it in your application.")
end

module SitemapGenerator
  class WaveAdapter < ::CarrierWave::Uploader::Base
    attr_accessor :store_dir

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)
      directory = File.dirname(location.path_in_public)
      if directory != '.'
        self.store_dir = directory
      end
      store!(open(location.path, 'rb'))
    end
  end
end
