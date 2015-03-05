module Localeapp
  module CLI
    class Remove < Command
      include ::Localeapp::ApiCall

      def execute(key, *rest)
        @output.puts "Localeapp rm"
        @output.puts ""
        @output.puts "Remove key: #{key}"
        api_call :remove,
          :url_options => { :key => key },
          :success => :report_success,
          :failure => :report_failure,
          :max_connection_attempts => 3
      end

      def report_success(response)
        @output.puts "Success!"
      end

      def report_failure(response)
        @output.puts "Failed!"
      end
    end
  end
end
