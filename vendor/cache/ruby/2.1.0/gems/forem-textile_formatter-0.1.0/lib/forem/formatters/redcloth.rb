require 'RedCloth'

module Forem
  module Formatters
    class RedCloth
      def self.format(text)
        ::RedCloth.new(ERB::Util.h(text)).to_html.html_safe
      end
    end
  end
end
