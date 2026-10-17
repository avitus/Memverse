# frozen_string_literal: true

# Ahoy treats a request with no User-Agent as a bot and records nothing for it.
# Request specs that exercise analytics or crawler handling include this module so
# their requests look like a real browser unless a test overrides the header.
module BrowserUserAgent
  CHROME = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  %i[get head post put patch delete].each do |verb|
    define_method(verb) do |path, **args|
      super(path, **args, headers: { "User-Agent" => CHROME }.merge(args[:headers] || {}))
    end
  end
end
