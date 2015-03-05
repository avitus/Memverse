begin
  require 'fog'
rescue LoadError
  raise LoadError.new("Missing required 'fog'.  Please 'gem install fog' and require it in your application.")
end

module SitemapGenerator
  class S3Adapter

    def initialize(opts = {})
      @aws_access_key_id = opts[:aws_access_key_id] || ENV['AWS_ACCESS_KEY_ID']
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY']
      @fog_provider = opts[:fog_provider] || ENV['FOG_PROVIDER']
      @fog_directory = opts[:fog_directory] || ENV['FOG_DIRECTORY']
      @fog_region = opts[:fog_region] || ENV['FOG_REGION']
      @fog_path_style = opts[:fog_path_style] || ENV['FOG_PATH_STYLE']
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      credentials = {
        :aws_access_key_id     => @aws_access_key_id,
        :aws_secret_access_key => @aws_secret_access_key,
        :provider              => @fog_provider,
      }
      credentials[:region] = @fog_region if @fog_region
      credentials[:path_style] = @fog_path_style if @fog_path_style

      storage   = Fog::Storage.new(credentials)
      directory = storage.directories.new(:key => @fog_directory)
      directory.files.create(
        :key    => location.path_in_public,
        :body   => File.open(location.path),
        :public => true
      )
    end

  end
end
