class SyntaxTreeError < StandardError
end

class SyntaxTreeNode
  attr_accessor :line_number

  @@number = 0

  def new_node
    @@number += 1
    "node#{@@number - 1}"
  end
end

class Instructions < SyntaxTreeNode
  attr_accessor :instructions

  def initialize(instructions, line_number)
    @instructions = instructions
    @line_number = line_number
  end

  def graphical
    last = nil
    first = nil
    @instructions.each do |instruction|
      if not last
        last = instruction.graphical
        first = last
      else
        node = instruction.graphical
        puts "{rank=same;#{last}->#{node} [label=\"next\"];}"
        last = node
      end
    end
    first
  end
end

class Assign < SyntaxTreeNode
  attr_accessor :location, :expression

  def initialize(location, expression, line_number)
    @location = location
    @expression = expression
    @line_number = line_number
  end

  def graphical
    node = new_node
    puts "#{node} [label=\"=\",shape=rectangle]"
    left_node = location.graphical
    puts "#{node} -> #{left_node} [label=\"lvalues\"]"
    right_node = expression.graphical
    puts "#{node} -> #{right_node} [label=\"rvalues\"]"
    node
  end
end

class Print < SyntaxTreeNode
  attr_accessor :expressions

  def initialize(expressions, line_number)
    @expressions = expressions
    @line_number = line_number
  end

  def graphical
    node = new_node
    @expressions.each do |expression|
      expr_node = expression.graphical
      puts "#{node} [label=\"Print\",shape=rectangle]"
      puts "#{node} -> #{expr_node}"
    end
    node
  end
end

class ParentNode < SyntaxTreeNode
  attr_accessor :child

  def initialize(child, line_number)
    @child = child
    @line_number = line_number
  end

  def graphical
    begin
      puts @child.data
    rescue NoMethodError
    end
    @child.graphical
  end
end

class Expression < ParentNode
end

class Location < ParentNode
end

class Var < SyntaxTreeNode
  attr_accessor :name

  def initialize(name, line_number)
    @name = name
    @line_number = line_number
  end

  def graphical
    var_node = new_node
    puts "#{var_node} [label=\"#{@name}\",shape=circle]"
    node = new_node
    puts "#{node} [label=\"Variable\",shape=rectangle]"
    puts "#{node} -> #{var_node} [label=\"ST\"]"
    node
  end
end

class Immediate < SyntaxTreeNode
  attr_accessor :table_entry

  def initialize(table_entry, line_number)
    @table_entry = table_entry
    @line_number = line_number
  end

  def graphical
    var_node = new_node
    puts "#{var_node} [label=\"#{table_entry.immediate_representation}\",shape=diamond]"
    node = new_node
    puts "#{node} [label=\"Immediate\",shape=rectangle]"
    puts "#{node} -> #{var_node} [label=\"ST\"]"
    node
  end
end

class Binary < SyntaxTreeNode
  attr_accessor :left_expression, :operator, :right_expression

  def initialize(left_expression, operator, right_expression, line_number)
    @left_expression = left_expression
    @operator = operator
    @right_expression = right_expression
    @line_number = line_number
  end

  def graphical
    left = @left_expression.graphical
    right = @right_expression.graphical
    node = new_node
    puts "#{node} [label=\"#{operator}\",shape=rectangle]"
    puts "#{node} -> #{left} [label=\"left\"]"
    puts "#{node} -> #{right} [label=\"right\"]"
    node
  end
end

class Not < SyntaxTreeNode
  attr_accessor :name, :expression

  def initialize(name, expression, line_number)
    @name = name
    @expression = expression
    @line_number = line_number
  end  

  def graphical
    expr_node = @expression.graphical
    node = new_node
    puts "#{node} [label=\"#{@name}\",shape=rectangle]"
    puts "#{node} -> #{expr_node}"
    node
  end
end

class Condition < SyntaxTreeNode
  attr_accessor :left_expression, :operator, :right_expression

  def initialize(left_expression, operator, right_expression, line_number)
    @left_expression = left_expression
    @operator = operator
    @right_expression = right_expression
    @line_number = line_number
  end

  def graphical
    left = @left_expression.graphical
    right = @right_expression.graphical
    node = new_node
    puts "#{node} [label=\"#{@operator}\",shape=rectangle]"
    puts "#{node} -> #{left}"
    puts "#{node} -> #{right}"
    node
  end
end

class If < SyntaxTreeNode
  attr_accessor :condition, :instructions_true, :other_ifs, :instructions_false

  def initialize(name, condition, instructions_true, other_ifs, instructions_false, line_number)
    @name = name
    @condition = condition
    @instructions_true = instructions_true
    @other_ifs = other_ifs
    @instructions_false = instructions_false
    @line_number = line_number
  end

  def graphical
    cond_node = @condition.graphical
    inst_tr_node = @instructions_true.graphical
    node = new_node
    puts "#{node} [label=\"#{@name}\",shape=rectangle]"
    puts "#{node} -> #{cond_node} [label=\"condition\"]"
    puts "#{node} -> #{inst_tr_node} [label=\"true\"]"
    @other_ifs.each do |elif|
      elif_node = elif.graphical
      puts "#{node} -> #{elif_node} [label=\"elif\"]"
    end
    if @instructions_false
      inst_fa_node = @instructions_false.graphical
      puts "#{node} -> #{inst_fa_node} [label=\"false\"]"
    end
    node
  end
end

class While < SyntaxTreeNode
  attr_accessor :condition, :instructions

  def initialize(condition, instructions, line_number)
    @condition = condition
    @instructions = instructions
    @line_number = line_number
  end

  def graphical
    cond_node = @condition.graphical
    instr_node = @instructions.graphical
    node = new_node
    puts "#{node} [label=\"While\",shape=rectangle]"
    puts "#{node} -> #{cond_node} [label=\"condition\"]"
    puts "#{node} -> #{instr_node} [label=\"instructions\"]"
    node
  end
end

class Puts < SyntaxTreeNode
  attr_accessor :expressions

  def initialize(expressions, line_number)
    @expressions = expressions
    @line_number = line_number
  end

  def graphical
    node = new_node
    @expressions.each do |expression|
      expr_node = expression.graphical
      puts "#{node} [label=\"Puts\",shape=rectangle]"
      puts "#{node} -> #{expr_node}"
    end
    node
  end
end

class SyntaxTree
  attr_accessor :tree

  def initialize(instructions)
    @tree = instructions
  end

  def graphical
    puts "strict digraph X {"
    @tree.graphical
    puts "}"
  end
end

