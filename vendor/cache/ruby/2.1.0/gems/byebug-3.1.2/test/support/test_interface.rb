require 'byebug/history'

module Byebug
  class TestInterface < Interface
    attr_reader :input_queue, :output_queue, :error_queue, :confirm_queue, :history

    attr_accessor :test_block

    def initialize
      @input_queue, @output_queue, @error_queue = [], [], []
      @confirm_queue, @command_queue, @history = [], [], Byebug::History.new
    end

    def errmsg(*args)
      @error_queue << format(*args)
    end

    def read_command(*args)
      if @input_queue.empty?
        if test_block
          test_block.call
          self.test_block = nil
        end
      else
        result = @input_queue.shift
        result.is_a?(Proc) ? result.call : result
      end
    end

    def print(*args)
      @output_queue << format(*args)
    end

    def confirm(message)
      @confirm_queue << message
      read_command message
    end

    def close
    end

    def inspect
      [
        "input_queue: #{input_queue.inspect}",
        "output_queue: #{output_queue.inspect}",
        "error_queue: #{error_queue.inspect}",
        "confirm_queue: #{confirm_queue.inspect}"
      ].join("\n")
    end
  end
end
