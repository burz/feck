require 'basic_data_types'
require 'symbol_table'
require 'syntax_tree'
require 'environment'

class InterpreterError < StandardError
end

class Interpreter
  attr_accessor :last_expression

  def is_number?(class_object)
    class_object == FloatSingleton.instance or class_object == IntegerSingleton.instance
  end

  def is_boolean?(class_object)
    class_object == BooleanSingleton.instance or class_object == NilSingleton.instance
  end

  def run(symbol_table, syntax_tree)
    @symbol_table = symbol_table
    @syntax_tree = syntax_tree
    @last_expression = Value.new nil, NilSingleton.instance
    @global_environment = Environment.new @symbol_table.table[0]
    @current_environment = [Environment.new(@symbol_table.table[1])]
    do_instructions @syntax_tree.tree.instructions
  end

  def migrate_environment_and_run(symbol_table, syntax_tree)
    @symbol_table = symbol_table
    @syntax_tree = syntax_tree
    if @global_environment
      new_global_environment = Environment.new @symbol_table.table[0]
      new_current_environment = [Environment.new(@symbol_table.table[1])]
      @global_environment.values.each do |name, state|
        variable = new_global_environment.find(name)
        variable.value = state.value
        variable.type_object = state.type_object
      end
      @current_environment[0].values.each do |name, state|
        variable = new_current_environment[0].find(name)
        variable.value = state.value
        variable.type_object = state.type_object
      end
      @global_environment = new_global_environment
      @current_environment = new_current_environment
    else
      @last_expression = Value.new nil, NilSingleton.instance
      @global_environment = Environment.new @symbol_table.table[0]
      @current_environment = [Environment.new(@symbol_table.table[1])]
    end
    do_instructions @syntax_tree.tree.instructions
  end

  def do_instructions(instructions)
    instructions.each do |instruction|
      if instruction.class == Assign
        do_assign instruction
      elsif instruction.class == Print
        do_print instruction
      elsif instruction.class == If
        do_if instruction
      elsif instruction.class == While
        do_while instruction
      elsif instruction.class == Puts
        do_puts instruction
      elsif instruction.class == Expression
        evaluate_expression instruction
      elsif instruction.class == FunctionDefinition
        do_def instruction
      elsif instruction.class == Gets
        @last_expression = $stdin.gets
      else
        $stderr.puts "did not recognize instruction"
      end
    end
  end

  def do_assign(assign)
    destination = evaluate_location assign.location
    destination.value, destination.type_object = evaluate_expression assign.expression
  end

  def do_print(print)
    results = print.expressions.each.map do |expression|
      result = evaluate_expression(expression)[0]
      if evaluate_expression(expression)[0] == nil
        result = "nil"
      end
      result
    end
    print results.join(" ")
  end

  def do_if(if_stmnt)
    result = evaluate_expression(if_stmnt.condition)[0]
    if result
      if if_stmnt.instructions_true
        do_instructions if_stmnt.instructions_true.instructions
      end
      done = true
    else
      done = false
      if_stmnt.other_ifs.each do |elif|
        done = do_if elif
        break if done
      end
      if not done and if_stmnt.instructions_false
        do_instructions if_stmnt.instructions_false.instructions
        done = true
      end
    end
    done
  end

  def do_while(while_statement)
    while evaluate_expression(while_statement.condition)[0]
      if while_statement.instructions
        do_instructions while_statement.instructions.instructions
      end
    end
  end

  def do_puts(puts)
    if puts.expressions.size > 0
      results = puts.expressions.each.map do |expression|
        result = evaluate_expression(expression)[0]
        if evaluate_expression(expression)[0] == nil
          result = "nil"
        end
        result
      end
      puts results
    else
      print "\n"
    end
  end

  def do_def(func_def)
    destination = evaluate_location func_def.location
    destination.value = func_def.definition
    destination.type_object = FunctionSingleton.instance
  end

  def do_call(definition, parameters = false)
    @last_expression = nil, NilSingleton.instance
    @current_environment << Environment.new(definition.scope)
    if parameters
      parameters.each_with_index do |parameter, i|
        parameter = evaluate_expression parameter
        entry = @current_environment[-1].find definition.parameters[i]
        entry.value = parameter[0]
        entry.type_object = parameter[1]
      end
    end
    do_instructions definition.instructions.instructions
    @current_environment.pop
  end

  def evaluate_location(location)
    if location.child.class == Var
      if location.child.name[0] == ?$
        result = @global_environment.find location.child.name
      else
        result = @current_environment[-1].find location.child.name
      end
    else
      $stderr.puts "undefined location, #{location.child}"
      result = nil
    end
    result
  end

  def error_check_number_binary_op(right_class, left_class, op_name, line_number)
    if not is_number? left_class
      raise InterpreterError.new "The expression to the left of the '#{op_name}' at expression on line #{line_number} is not an integer"
    end
    if not is_number? right_class
      raise InterpreterError.new "The expression to the right of the '#{op_name}' at expression on line #{line_number} is not an integer"
    end
  end

  def error_check_boolean_binary_op(right_class, left_class, op_name, line_number)
    if not is_boolean? left_class
      raise InterpreterError.new "The expression to the left of the '#{op_name}' at expression on line #{line_number} is not a boolean value"
    end
    if not is_boolean? right_class
      raise InterpreterError.new "The expression to the right of the '#{op_name}' at expression on line #{line_number} is not a boolean value"
    end
  end

  def evaluate_condition(condition)
    left = evaluate_expression condition.left_expression
    right = evaluate_expression condition.right_expression
    case condition.operator
    when :"is", :"=="
      result = left[0] == right[0]
    when :"!="
      result = left[0] != right[0]
    when :">"
      error_check_number_binary_op left[1], right[1], :">", condition.line_number
      result = left[0] > right[0]
    when :"<"
      error_check_number_binary_op left[1], right[1], :"<", condition.line_number
      result = left[0] < right[0]
    when :">="
      error_check_number_binary_op left[1], right[1], :">=", condition.line_number
      result = left[0] >= right[0]
    when :"<="
      error_check_number_binary_op left[1], right[1], :"<=", condition.line_number
      result = left[0] <= right[0]
    end
    result
  end

  def evaluate_expression(expression)
    if expression.child.class == Immediate
      @last_expression = expression.child.table_entry.value, expression.child.table_entry.type_object
    elsif expression.child.class == Call
      if expression.child.name[0] == ?$
        variable = @global_environment.find expression.child.name
      else
        variable = @current_environment[-1].find expression.child.name
      end
      if variable.type_object == FunctionSingleton.instance
        do_call variable.value, expression.child.parameters
      else
        @last_expression = variable.value, variable.type_object
      end
    elsif expression.child.class == Location
      if expression.child.child.name[0] == ?$
        variable = @global_environment.find expression.child.child.name
      else
        variable = @current_environment[-1].find expression.child.child.name
      end
      if variable.type_object == FunctionSingleton.instance
        do_call variable.value
      else
        @last_expression = variable.value, variable.type_object
      end
    elsif expression.child.class == Binary
      @last_expression = evaluate_binary(expression.child)
    elsif expression.child.class == Not
      result = evaluate_expression(expression.child.expression)
      if not result[1] == BooleanSingleton.instance and not result[1] == NilSingleton.instance
        raise InterpreterError.new "The '#{expression.child.name}' on line #{expression.child.line_number} is not followed by an expression"
      end
      @last_expression = !result[0], result[1]
    elsif expression.child.class == Condition
      @last_expression = evaluate_condition(expression.child), BooleanSingleton.instance
    elsif expression.child.class == Gets
      @last_expression = $stdin.gets, StringSingleton.instance
    else
      $stderr.puts "undefined expression #{expression.child}"
      @last_expression = nil
    end
    @last_expression
  end

  def evaluate_binary(binary)
    left = evaluate_expression binary.left_expression
    right = evaluate_expression binary.right_expression
    case binary.operator
    when :"+"
      error_check_number_binary_op left[1], right[1], :"+", binary.line_number
      result = left[0] + right[0]
    when :"-"
      error_check_number_binary_op left[1], right[1], :"-", binary.line_number
      result = left[0] - right[0]
    when :"*"
      error_check_number_binary_op left[1], right[1], :"*", binary.line_number
      result = left[0] * right[0]
    when :"**"
      error_check_number_binary_op left[1], right[1], :"**", binary.line_number
      result = left[0] ** right[0]
    when :"/"
      error_check_number_binary_op left[1], right[1], :"/", binary.line_number
      result = left[0] / right[0]
    when :"%"
      error_check_number_binary_op left[1], right[1], :"%", binary.line_number
      result = left[0] % right[0]
    when :"or", :"||"
      error_check_boolean_binary_op left[1], right[1], binary.operator, binary.line_number
      result = left[0] || right[0]
    when :"and", :"&&"
      error_check_boolean_binary_op left[1], right[1], binary.operator, binary.line_number
      result = left[0] && right[0]
    end
    if result.class == Float
      if result % 1 != 0
        result = result, FloatSingleton.instance
      else
        result = result.to_i, IntegerSingleton.instance
      end
    elsif result.class == NilClass
      result = result, NilSingleton.instance
    elsif result.class == Fixnum or result.class == Bignum
      result = result, IntegerSingleton.instance
    else
      result = result, BooleanSingleton.instance
    end
    result
  end
end

