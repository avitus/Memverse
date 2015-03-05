module Localeapp
  module CLI
    class Pull < Command
      include ::Localeapp::ApiCall

      def execute
        @output.puts "Localeapp Pull"
        @output.puts ""

        @output.puts "Fetching translations:"
        api_call :export,
          :success => :update_backend,
          :failure => :report_failure,
          :max_connection_attempts => 3
      end

      def update_backend(response)
        @output.puts "Success!"
        @output.puts "Updating backend:"
        Localeapp.updater.dump(Localeapp.load_yaml(response))
        @output.puts "Success!"
        Localeapp.poller.write_synchronization_data!(Time.now.to_i, Time.now.to_i)
      end

      def report_failure(response)
        @output.puts "Failed!"
      end
    end
  end
end
