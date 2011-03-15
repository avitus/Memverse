module Synthesis
  module Version
    MAJOR = 0
    MINOR = 4
    RELEASE = 0

    def self.dup
      "#{MAJOR}.#{MINOR}.#{RELEASE}"
    end
  end
end
