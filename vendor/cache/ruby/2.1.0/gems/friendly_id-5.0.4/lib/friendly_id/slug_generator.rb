module FriendlyId
  # The default slug generator offers functionality to check slug strings for
  # uniqueness and, if necessary, appends a sequence to guarantee it.
  class SlugGenerator

    def initialize(scope)
      @scope = scope
    end

    def available?(slug)
      !@scope.exists_by_friendly_id?(slug)
    end

    def add(slug)
      slug
    end

    def generate(candidates)
      candidates.each {|c| return add c if available?(c)}
      nil
    end

  end
end
