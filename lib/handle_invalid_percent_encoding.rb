# To address problems with EasouSpider submitting invalid UTF-8 byte sequences
# ACW added July 2014
# http://stackoverflow.com/questions/24648206#24727310

require 'rack'
require 'logger'
class HandleInvalidPercentEncoding
  DEFAULT_CONTENT_TYPE = 'text/html'
  DEFAULT_CHARSET      = 'utf-8'

  attr_reader :logger
  def initialize(app, stdout=STDOUT)
    @app = app
    @logger = defined?(Rails.logger) ? Rails.logger : Logger.new(stdout)
  end

  def call(env)
    begin
      # calling env.dup here prevents bad things from happening
      request = Rack::Request.new(env.dup)
      # calling request.params is sufficient to trigger the error
      # see https://github.com/rack/rack/issues/337#issuecomment-46453404
      request.params
      @app.call(env)
    rescue ArgumentError => e
      raise unless e.message =~ /invalid %-encoding/
      message = "BAD REQUEST: Returning 400 due to #{e.message} from request with env #{request.inspect}"
      logger.info message
      content_type = env['HTTP_ACCEPT'] || DEFAULT_CONTENT_TYPE
      status = 400
      body   = "Bad Request"
      return [
        status,
        {
           'Content-Type' => "#{content_type}; charset=#{DEFAULT_CHARSET}",
           'Content-Length' => body.bytesize.to_s
        },
        [body]
      ]
    end
  end

end
