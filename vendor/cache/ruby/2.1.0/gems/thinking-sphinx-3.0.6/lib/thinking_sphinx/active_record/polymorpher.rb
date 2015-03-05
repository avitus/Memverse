class ThinkingSphinx::ActiveRecord::Polymorpher
  def initialize(source, column, class_names)
    @source, @column, @class_names = source, column, class_names
  end

  def morph!
    append_reflections
    morph_properties
  end

  private

  attr_reader :source, :column, :class_names

  def append_reflections
    mappings.each do |class_name, name|
      klass.reflections[name] ||= clone_with name, class_name
    end
  end

  def clone_with(name, class_name)
    ThinkingSphinx::ActiveRecord::FilteredReflection.clone_with_filter(
      reflection, name, class_name
    )
  end

  def mappings
    @mappings ||= class_names.inject({}) do |hash, class_name|
      hash[class_name] = "#{column.__name}_#{class_name.downcase}".to_sym
      hash
    end
  end

  def morphed_stacks
    @morphed_stacks ||= mappings.values.collect { |key|
      column.__stack + [key]
    }
  end

  def morph_properties
    (source.fields + source.attributes).each do |property|
      property.rebase column.__path, :to => morphed_stacks
    end
  end

  def reflection
    @reflection ||= klass.reflections[column.__name]
  end

  def klass
    @klass ||= column.__stack.inject(source.model) { |parent, key|
      parent.reflections[key].klass
    }
  end
end
