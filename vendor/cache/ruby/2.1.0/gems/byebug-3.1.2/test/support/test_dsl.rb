module TestDsl

  class TestCase < MiniTest::Spec
    include TestDsl

    def setup
      Byebug.handler = Byebug::CommandProcessor.new(Byebug::TestInterface.new)
      Byebug.breakpoints.clear if Byebug.breakpoints
    end

    def self.temporary_change_hash hash, key, value
      before do
        @old_hashes ||= {}
        @old_hashes.merge!({ hash => { key => hash[key] } }) do |k, v1, v2|
          v1.merge(v2)
        end
        hash[key] = value
      end

      after do
        hash[key] = @old_hashes[hash][key]
      end
    end

    def self.temporary_change_const klass, const, value
      before do
        @old_consts ||= {}
        old_value = klass.const_defined?(const) ?
                    klass.const_get(const) : :__undefined__
        @old_consts.merge!({ klass => { const => old_value } }) do |k, v1, v2|
          v1.merge(v2)
        end
        klass.send :remove_const, const if klass.const_defined?(const)
        klass.const_set const, value unless value == :__undefined__
      end

      after do
        klass.send :remove_const, const if klass.const_defined?(const)
        klass.const_set const, @old_consts[klass][const] unless
          @old_consts[klass][const] == :__undefined__
      end
    end
  end

  #
  # Expand fullpath of a given example file
  #
  def fullpath(filename)
    (Pathname.new(__FILE__) + "../../examples/#{filename}.rb").cleanpath.to_s
  end

  #
  # Shorten a fullpath
  #
  def shortpath(fullpath)
    separator = File::ALT_SEPARATOR || File::SEPARATOR
    "...#{separator}" + fullpath.split(separator)[-3..-1].join(separator)
  end

  #
  # Adds commands to the input queue, so they will be later retrieved by
  # Processor, i.e., it emulates user's input.
  #
  # If a command is a Proc object, it will be executed before being retrieved by
  # Processor. May be handy when you need build a command depending on the
  # current context/state.
  #
  # Usage:
  #   enter 'b 12'
  #   enter 'b 12', 'cont'
  #   enter ['b 12', 'cont']
  #   enter 'b 12', ->{"disable #{breakpoint.id}"}, 'cont'
  #
  def enter(*messages)
    messages = messages.first.is_a?(Array) ? messages.first : messages
    interface.input_queue.concat(messages)
  end

  #
  # Runs the provided Proc.
  #
  # You also can specify a block, which will be executed when Processor extracts
  # all the commands from the input queue. You can use that for making asserts
  # on the current test. If you specified the block and it never was executed,
  # the test will fail.
  #
  # Usage:
  #   debug_proc -> { byebug; puts 'Hello' }
  #
  #   enter 'b 4', 'cont'
  #   code = -> do
  #     byebug
  #     puts 'hello'
  #   end
  #   debug_proc(code) { state.line.must_equal 4 }
  #
  def debug_proc(program, &block)
    Byebug.stubs(:run_init_script)
    interface.test_block = block
    begin
      program.call
    ensure
      interface.test_block.call if interface.test_block
    end
  end

  #
  # Checks the output of byebug.
  #
  # By default it checks output queue of the current interface, but you can
  # check again any queue by providing it as a second argument.
  #
  # Usage:
  #   enter 'break 4', 'cont'
  #   debug 'ex1'
  #   check_output "Breakpoint 1 at #{fullpath('ex1')}:4"
  #
  def check_output(check_method, *args)
    queue = args.last.is_a?(String) || args.last.is_a?(Regexp) ?
            interface.output_queue : args.pop
    queue_messages = queue.map(&:strip)
    messages = Array(args).map { |msg| msg.is_a?(String) ? msg.strip : msg }
    queue_messages.send(check_method, messages)
  end

  def check_error_includes(*args)
    check_output :must_include_in_order, *args, interface.error_queue
  end

  def check_output_includes(*args)
    check_output :must_include_in_order, *args
  end

  def check_output_doesnt_include(*args)
    check_output :wont_include_in_order, *args
  end

  def interface
    Byebug.handler.interface
  end

  def state
    Thread.current.thread_variable_get('state')
  end

  def context
    state.context
  end

  def force_set_const(klass, const, value)
    force_unset_const(klass, const)
    klass.const_set(const, value)
  end

  def force_unset_const(klass, const)
    klass.send(:remove_const, const) if klass.const_defined?(const)
  end

  def change_line_in_file(file, line, new_line_content)
    old_content = File.read(file)
    new_content = old_content.split("\n")
                             .tap { |c| c[line - 1] = new_line_content }
                             .join("\n") + "\n"
    File.open(file, 'w') { |f| f.write(new_content) }
  end
end
