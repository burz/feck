class Value
  attr_accessor :value, :type_object

  def initialize(value, type_object)
    @value = value
    @type_object = type_object
  end
end

class Environment
  def initialize(scope)
    @values = {}
    scope.names.each do |x|
      @values[x] = Value.new nil, NilSingleton.instance
    end
  end

  def find(name)
    @values[name]
  end
end

