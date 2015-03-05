module DebuggerAliasTest
  class DebuggerAliasSpec < MiniTest::Spec
    it 'aliases "debugger" to "byebug"' do
      Kernel.method(:debugger).must_equal(Kernel.method(:byebug))
    end
  end
end
