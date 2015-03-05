module Sidetiq
  # Public: Sidetiq logging interface.
  module Logging
    %w(fatal error warn info debug).each do |level|
      level = level.to_sym

      define_method(level) do |msg|
        Sidetiq.logger.__send__(level, "[Sidetiq] #{msg}")
      end
    end
  end
end
