class SymbolTableError < StandardError
end

class Entry
  attr_accessor :line_number

  @@node_number = 0
  @@anchor_number = 0
  @@cluster_number = 0

  def new_node
    @@node_number += 1
    "node#{@@node_number - 1}"
  end

  def new_anchor
    @@anchor_number += 1
    "anchor#{@@anchor_number - 1}"
  end

  def new_cluster
    @@cluster_number += 1
    "cluster#{@@cluster_number - 1}"
  end
end

class Constant < Entry
  attr_accessor :value, :type_object

  def initialize(value, type_object, line_number)
    @value = value
    @type_object = type_object
    @line_number = line_number
  end

  def immediate_representation
    if value == nil
      result = "nil"
    else
      result = value
    end
    result
  end

  def graphical
    typ_obj = @type_object.graphical
    node = new_node
    puts "#{node} [label=\"#{immediate_representation}\",shape=diamond]"
    puts "#{node} -> #{typ_obj}"
    node
  end
end

class Variable < Entry
  def initialize(line_number)
    @line_number = line_number
  end

  def graphical
    node = new_node
    puts "#{node} [label=\"\",shape=circle]"
    node
  end
end

class Function < Entry
  attr_accessor :name, :parameters, :instructions, :scope

  def initialize(name, parameters, instructions, scope, line_number)
    @name = name
    @parameters = parameters
    @instructions = instructions
    @scope = scope
    @line_number = line_number
  end

  def graphical
    node = name
    puts "#{node}"
    last_node = false
    if parameters
      parameters.each do |parameter|
        param_node = new_node
        puts "#{param_node} [label=\"#{parameter}\",shape=rectangle]"
        if not last_node
          puts "#{node} -> #{param_node} [label=\"parameters\"]"
        else
          puts  "{rank=same;#{last_node}->#{param_node} [label=\"next\"];}"
        end
        last_node = param_node
      end
    end
    if instructions
      instr_node = instructions.graphical
      puts "#{node} -> #{instr_node} [label=\"instructions\"]"
    end
    node
  end
end

class Scope < Entry
  attr_accessor :scope_name, :names

  def initialize(scope_name, parent = nil)
    @scope_name = scope_name
    @parent = parent
    @names = []
  end

  def add_to_scope(name)
      if not @names.include? name
        @names << name
      end
  end

  def find(name)
    @names.include? name
  end

  def graphical
    cluster = new_cluster
    puts "subgraph #{cluster} {"
    anchor = new_anchor
    puts "#{anchor} [label=\"\",style=invis]"
    @names.each do |name|
      node = new_node
      puts "#{node} [label=\"#{name}\",shape=box,color=white,fontcolor=black]"
    end
    puts "}"
    anchor
  end
end

class SymbolTable
  attr_accessor :table

  def initialize
    @table = [Scope.new("Global"), Scope.new("Program")]
  end

  def push_scope(name)
    @table << Scope.new(name, @table[-1])
  end

  def pop_scope
    @table.pop
  end

  def add_to_scope(name)
    @table[-1].add_to_scope(name)
  end

  def add_to_global_scope(name)
    @table[0].add_to_scope(name)
  end

  def graphical
    puts "strict digraph X {"
    global_scope = @table[0].graphical
    global = "__global"
    puts "#{global} [label=\"Global\",shape=circle]"
    puts "#{global} -> #{global_scope}"
    program_scope = @table[1].graphical
    program = "__program"
    puts "#{program} [label=\"Program\",shape=circle]"
    puts "#{program} -> #{program_scope}"
    puts "}"
  end
end

