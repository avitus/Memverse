module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)["response"]
    end
  end
end