module MapByMethod
  MAP_BY_METHOD_FORMAT = /^(map|collect|select|each|reject|sort_by|group_by|index_by)(?:_by)?_(\w+[?!]?)$/ unless defined?(MAP_BY_METHOD_FORMAT)
  
  module InstanceMethods
    alias_method :respond_to_before_map_by_method?, :respond_to?
    
    # Support for include_priv due to ActiveRecord's AssociationProxy expecting it;
    # Support degrades to normal single argument respond_to?
    def respond_to?(method, include_priv = false)
      respond_to = (include_priv ?
        respond_to_before_map_by_method?(method, include_priv) :
        respond_to_before_map_by_method?(method))
      unless respond_to
        matches = method.to_s.match(MAP_BY_METHOD_FORMAT)
        if (respond_to = !!(matches)) && self.size > 0
          iterator, callmethod = matches[1..2]
          respond_to = self.first.respond_to?(callmethod)
        end
      end
      respond_to
    end

    protected
    
    alias_method :method_missing_before_map_by_method, :method_missing
    
    def method_missing(method, *args, &block)
      if !respond_to_before_map_by_method?(method) and
          (matches = method.to_s.match(MAP_BY_METHOD_FORMAT))
        iterator, callmethod = matches[1..2]
        # map by multiple stuff
        result = callmethod.split('_and_').collect do |method|
          # self.send(iterator) { |item| item.send method }
          self.send(iterator) { |item| item.send(method, *args, &block) }
        end
        
        return result.length > 1 ? result.transpose : result.first
      else
        method_missing_before_map_by_method(method, *args, &block)
      end
    end
  end
  
  def self.included(base)
    super
    base.send :include, InstanceMethods
  end
end

Array.send :include, MapByMethod unless Array.ancestors.include?(MapByMethod)