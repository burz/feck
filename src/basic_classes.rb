class StringClass
  attr_accessor :string

  def initialize(string)
    @stirng = string
  end

  def char_at(x)
    @string[x, 1]
  end

  def substring(x, y)
    @string[x...y]
  end

  def size
    @string.size
  end

  def append(x)
    @string << x
  end

  def find(x)
    @string.index x
  end
end

class ArrayClass
  attr_accessor :values

  def initialize(values = false)
    @values = values || []
  end

  def element_at(x)
    @values[x]
  end

  def subarray_slice(x, y)
    @values[x...y]
  end

  def subarray_size(x, y)
    @values[x, y]    
  end

  def size
    @values.size
  end

  def append(x)
    @values << x
  end

  def remove(x)
    @values.delete_at @values.index(x)
  end

  def includes?(x)
    @values.includes? x
  end

  def push(x)
    @values << x
  end

  def pop
    @values.pop
  end
end

