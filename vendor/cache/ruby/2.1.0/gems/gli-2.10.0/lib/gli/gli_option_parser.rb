module GLI
  # Parses the command-line options using an actual +OptionParser+
  class GLIOptionParser
    def initialize(commands,flags,switches,accepts,default_command = nil,subcommand_option_handling_strategy=:legacy)
       command_finder       = CommandFinder.new(commands,default_command || "help")
      @global_option_parser = GlobalOptionParser.new(OptionParserFactory.new(flags,switches,accepts),command_finder,flags)
      @accepts              = accepts
      @subcommand_option_handling_strategy = subcommand_option_handling_strategy
    end

    # Given the command-line argument array, returns an OptionParsingResult
    def parse_options(args) # :nodoc:
      option_parser_class = self.class.const_get("#{@subcommand_option_handling_strategy.to_s.capitalize}CommandOptionParser")
      OptionParsingResult.new.tap { |parsing_result|
        parsing_result.arguments = args
        parsing_result = @global_option_parser.parse!(parsing_result)
        option_parser_class.new(@accepts).parse!(parsing_result)
      }
    end

  private

    class GlobalOptionParser
      def initialize(option_parser_factory,command_finder,flags)
        @option_parser_factory = option_parser_factory
        @command_finder        = command_finder
        @flags                 = flags
      end

      def parse!(parsing_result)
        parsing_result.arguments      = GLIOptionBlockParser.new(@option_parser_factory,UnknownGlobalArgument).parse!(parsing_result.arguments)
        parsing_result.global_options = @option_parser_factory.options_hash_with_defaults_set!
        command_name = if parsing_result.global_options[:help]
                         "help"
                       else
                         parsing_result.arguments.shift
                       end
        parsing_result.command        = @command_finder.find_command(command_name)
        unless command_name == 'help'
          verify_required_options!(@flags,parsing_result.global_options)
        end
        parsing_result
      end

    protected

      def verify_required_options!(flags,options)
        missing_required_options = flags.values.
          select(&:required?).
          reject { |option|
            options[option.name] != nil
        }
        unless missing_required_options.empty?
          raise BadCommandLine, missing_required_options.map { |option|
            "#{option.name} is required"
          }.join(' ')
        end
      end
    end

    class NormalCommandOptionParser < GlobalOptionParser
      def initialize(accepts)
        @accepts = accepts
      end

      def error_handler
        lambda { |message,extra_error_context| 
          raise UnknownCommandArgument.new(message,extra_error_context)
        }
      end

      def parse!(parsing_result)
        parsed_command_options = {}
        command = parsing_result.command
        arguments = nil

        loop do
          option_parser_factory       = OptionParserFactory.for_command(command,@accepts)
          option_block_parser         = CommandOptionBlockParser.new(option_parser_factory, self.error_handler)
          option_block_parser.command = command
          arguments                   = parsing_result.arguments

          arguments = option_block_parser.parse!(arguments)

          parsed_command_options[command] = option_parser_factory.options_hash_with_defaults_set!
          command_finder                  = CommandFinder.new(command.commands,command.get_default_command)
          next_command_name               = arguments.shift

          verify_required_options!(command.flags,parsed_command_options[command])

          begin
            command = command_finder.find_command(next_command_name)
          rescue AmbiguousCommand
            arguments.unshift(next_command_name)
            break
          rescue UnknownCommand
            arguments.unshift(next_command_name)
            # Although command finder could certainy know if it should use
            # the default command, it has no way to put the "unknown command"
            # back into the argument stack.  UGH.
            unless command.get_default_command.nil?
              command = command_finder.find_command(command.get_default_command)
            end
            break
          end
        end
        parsed_command_options[command] ||= {}
        command_options = parsed_command_options[command]

        this_command          = command.parent
        child_command_options = command_options

        while this_command.kind_of?(command.class)
          this_command_options = parsed_command_options[this_command] || {}
          child_command_options[GLI::Command::PARENT] = this_command_options
          this_command = this_command.parent
          child_command_options = this_command_options
        end

        parsing_result.command_options = command_options
        parsing_result.command = command
        parsing_result.arguments = Array(arguments.compact)
        parsing_result
      end

    end

    class LegacyCommandOptionParser < NormalCommandOptionParser
      def parse!(parsing_result)
        command                     = parsing_result.command
        option_parser_factory       = OptionParserFactory.for_command(command,@accepts)
        option_block_parser         = LegacyCommandOptionBlockParser.new(option_parser_factory, self.error_handler)
        option_block_parser.command = command

        parsing_result.arguments       = option_block_parser.parse!(parsing_result.arguments)
        parsing_result.command_options = option_parser_factory.options_hash_with_defaults_set!

        subcommand,args                = find_subcommand(command,parsing_result.arguments)
        parsing_result.command         = subcommand
        parsing_result.arguments       = args
        verify_required_options!(command.flags,parsing_result.command_options)
      end

    private

      def find_subcommand(command,arguments)
        arguments = Array(arguments)
        command_name = if arguments.empty?
                         nil
                       else
                         arguments.first
                       end

        default_command = command.get_default_command
        finder = CommandFinder.new(command.commands,default_command.to_s)

        begin
          results = [finder.find_command(command_name),arguments[1..-1]]
          find_subcommand(results[0],results[1])
        rescue UnknownCommand, AmbiguousCommand
          begin
            results = [finder.find_command(default_command.to_s),arguments]
            find_subcommand(results[0],results[1])
          rescue UnknownCommand, AmbiguousCommand
            [command,arguments]
          end
        end
      end
    end
  end
end
