# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require 'new_relic/agent/database/obfuscation_helpers'

module NewRelic
  module Agent
    module Database
      class Obfuscator
        include Singleton
        include ObfuscationHelpers

        attr_reader :obfuscator

        def initialize
          reset
        end

        def reset
          @obfuscator = method(:default_sql_obfuscator)
        end

        # Sets the sql obfuscator used to clean up sql when sending it
        # to the server. Possible types are:
        #
        # :before => sets the block to run before the existing
        # obfuscators
        #
        # :after => sets the block to run after the existing
        # obfuscator(s)
        #
        # :replace => removes the current obfuscator and replaces it
        # with the provided block
        def set_sql_obfuscator(type, &block)
          if type == :before
            @obfuscator = NewRelic::ChainedCall.new(block, @obfuscator)
          elsif type == :after
            @obfuscator = NewRelic::ChainedCall.new(@obfuscator, block)
          elsif type == :replace
            @obfuscator = block
          else
            fail "unknown sql_obfuscator type #{type}"
          end
        end

        def default_sql_obfuscator(sql)
          if sql[-3,3] == '...'
            return "Query too large (over 16k characters) to safely obfuscate"
          end

          stmt = sql.kind_of?(Statement) ? sql : Statement.new(sql)
          adapter = stmt.adapter
          obfuscated = remove_escaped_quotes(stmt)
          obfuscated = obfuscate_single_quote_literals(obfuscated)
          if !(adapter.to_s =~ /postgres/ || adapter.to_s =~ /sqlite/)
            obfuscated = obfuscate_double_quote_literals(obfuscated)
          end
          obfuscated = obfuscate_numeric_literals(obfuscated)
          obfuscated.to_s # return back to a regular String
        end
      end
    end
  end
end
