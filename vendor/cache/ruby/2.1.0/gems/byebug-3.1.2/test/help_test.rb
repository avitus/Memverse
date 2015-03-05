module HelpTest
  class HelpTestCase < TestDsl::TestCase
    include Columnize

    before do
      @example = -> do
        byebug
      end
    end

    let(:available_cmds) do
      Byebug::Command.commands.map(&:names).flatten.uniq.sort
    end

    describe 'when typed alone' do
      temporary_change_hash Byebug::Setting, :width, 50

      it 'must show self help when typed alone' do
        enter 'help'
        debug_proc(@example)
        check_output_includes \
          'Type "help <command-name>" for help on a specific command',
          'Available commands:', columnize(available_cmds, 50)
      end

      it 'must work when shortcut used' do
        enter 'h'
        debug_proc(@example)
        check_output_includes \
          'Type "help <command-name>" for help on a specific command'
      end
    end

    describe 'when typed with a command'  do
      it 'must show an error if an undefined command is specified' do
        enter 'help foobar'
        debug_proc(@example)
        check_error_includes 'Undefined command: "foobar". Try "help".'
      end

      it "must show a command's help" do
        enter 'help break'
        debug_proc(@example)
        check_output_includes \
          "b[reak] file:line [if expr]\n" \
          "b[reak] class(.|#)method [if expr]\n\n" \
          "Set breakpoint to some position, (optionally) if expr == true\n"
      end
    end

    describe 'when typed with command and subcommand' do
      it "must show subcommand's help" do
        enter 'help info breakpoints'
        debug_proc(@example)
        check_output_includes "Status of user-settable breakpoints.\n"
      end
    end
  end
end
