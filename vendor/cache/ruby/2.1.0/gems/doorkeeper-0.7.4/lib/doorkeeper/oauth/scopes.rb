module Doorkeeper
  module OAuth
    class Scopes
      include Enumerable
      include Comparable

      def self.from_string(string)
        string ||= ""
        new.tap do |scope|
          scope.add(*string.split)
        end
      end

      def self.from_array(array)
        new.tap do |scope|
          scope.add(*array)
        end
      end

      delegate :each, :to => :@scopes

      def initialize
        @scopes = []
      end

      def exists?(scope)
        @scopes.include? scope.to_s
      end

      def add(*scopes)
        @scopes.push(*scopes.map(&:to_s))
        @scopes.uniq!
      end

      def all
        @scopes
      end

      def to_s
        @scopes.join(" ")
      end

      def has_scopes?(scopes)
        scopes.all? { |s| exists?(s) }
      end

      def +(other)
        if other.is_a? Scopes
          self.class.from_array(self.all + other.all)
        else
          super(other)
        end
      end

      def <=>(other)
        self.map(&:to_s).sort <=> other.map(&:to_s).sort
      end
    end
  end
end
