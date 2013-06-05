require 'scanner'
require 'basic_data_types'
require 'symbol_table'
require 'syntax_tree'

class ParseError < StandardError
end

class Parser
  attr_accessor :symbol_table, :syntax_tree

  def initialize(tokenized_lines)
    @tokenized_lines = tokenized_lines
    @symbol_table = SymbolTable.new
  end

  def token_at(position)
    @tokenized_lines[@current_line][position]
  end

  def next_token
    @line_position += 1
  end

  def current_token
    @tokenized_lines[@current_line][@line_position]
  end

  def current_token_type
    @tokenized_lines[@current_line][@line_position].token_type
  end

  def next_token_type
    result = token_at(@line_position + 1) && token_at(@line_position + 1).token_type
  end

  def line_number
    @current_line + 1
  end

  def parse
    @current_line = 0
    instructs = instructions
    if @current_line < @tokenized_lines.size
      if Scanner.is_keyword? current_token_type
        raise ParseError.new "Misplaced keyword '#{current_token_type}' on line #{line_number}"
      else
        raise ParseError.new "Undefined symbol '#{current_token.data}' on line #{line_number}"
      end
    end
    @syntax_tree = SyntaxTree.new instructs
  end

  def instructions
    instructs = []
    while @current_line < @tokenized_lines.size
      @line_position = 0
      if not current_token
        @current_line += 1
        next
      end
      if instr = instruction
        instructs += Array(instr)
        @current_line += 1
      else
        break
      end
    end
    Instructions.new instructs, line_number
  end

  def instruction
    assign || value || print_statement || if_statement ||
    while_statement || puts_statement || func_def || gets_statement
  end

  def assign
    return false if not current_token
    line = line_number
    old_position = @line_position
    if left = left_values
      if current_token and current_token_type == :"="
        next_token
        right = [] if (right = right_values) == false
        assignments = []
        if left.size >= right.size
          (0...left.size).each do |x|
            if right[x]
              assignments << Assign.new(left[x], right[x], left[x].line_number)
            else
              const = Constant.new nil, NilSingleton.instance, line
              imme = Immediate.new const, const.line_number
              loca = Location.new imme, imme.line_number
              assignments << Assign.new(left[x], loca, left[x].line_number)
            end
          end
        else
          (0...right.size).each do |x|
            if left[x]
              assignments << Assign.new(left[x], right[x], left[x].line_number)
            end
          end
        end
        assignments
      else
        @line_position = old_position
        false
      end
    else
      false
    end
  end

  def print_statement
    return false if not token_at @line_position
    return false if current_token_type != :print
    line = line_number
    next_token
    values = right_values
    Print.new values, line
  end

  def puts_statement
    return false if not token_at @line_position
    return false if current_token_type != :puts
    line = line_number
    next_token
    values = right_values
    Puts.new values, line
  end

  def if_statement(name = :if)
    return false if not current_token
    return false if not current_token_type == name
    line = line_number
    next_token
    if not low_bool_expr = low_boolean_expression
      raise ParseError.new "The '#{name}' on line #{line} is not followed by a boolean expression"
    end
    @current_line += 1
    instructions_true = instructions
    elifs = []
    if name == :if
      while elif = if_statement(:elif)
        elifs << elif
      end
    end
    instructions_false = false
    if name == :if and current_token and current_token_type == :else
      next_token
      @current_line += 1
      instructions_false = instructions
    end
    if name == :if
      if not current_token or current_token_type != :end
        raise ParseError.new "The '#{name}' on line #{line} is not terminated by an 'end'"
      end
      next_token
    end
    If.new name, low_bool_expr, instructions_true, elifs,
           instructions_false, line
  end

  def while_statement
    return false if not current_token
    return false if not current_token_type == :while
    line = line_number
    next_token
    if not low_bool_expr = low_boolean_expression
      raise ParseError.new "The 'while' on line #{line} is not followed by a condition"
    end
    @current_line += 1
    instr = instructions
    if not current_token or current_token_type != :end
      raise ParseError.new "The 'while' on line #{line} is not terminated by an 'end'"
    end
    next_token
    While.new low_bool_expr, instr, line
  end

  def func_def
    return false if not current_token
    return false if not current_token_type == :def
    line = line_number
    next_token
    if not current_token
      raise ParseError.new "The 'def' on line #{line} is not followed by a function name"
    end
    name = current_token.data
    next_token
    @symbol_table.add_to_scope name
    @symbol_table.push_scope name
    if current_token and current_token_type == :"("
      next_token
      parameters = var_list
      parameters.map! { |p| p.name }
      next_token # Skips terminating ')'
    else
      parameters = false
    end
    @current_line += 1
    instr = instructions
    if not current_token or not current_token_type == :end
      raise ParseError.new "The 'def' on line #{line} is not followed by an end"
    end
    next_token
    scope = @symbol_table.pop_scope
    var = Var.new name, line
    loc = Location.new var, line
    func = Function.new name, parameters, instr, scope, line
    FunctionDefinition.new loc, func, line
  end

  def call
    return false if not current_token or not current_token_type == :identifier
    name = current_token.data
    line = line_number
    next_token
    parameters = []
    if current_token and current_token_type == :"("
      next_token
      parameters = value_list
      next_token # Skip the ')'
    end
    Call.new name, parameters, line
  end

  def gets_statement
    return false if not current_token
    return false if not current_token_type == :gets
    next_token
    Gets.new line_number
  end

  def left_values
    return false if not des = designator
    locations = [des]
    while current_token and current_token_type == :","
      next_token
      if not des = designator
        raise ParseError.new "The ',' in the left_values on line #{line_number} is not followed by a designator"
      end
      locations << des
    end
    locations
  end

  def right_values
    value_list || []
  end

  def value_list
    return false if not val = value
    values = [val]
    while current_token and current_token_type == :","
      next_token
      if not val = value
        raise ParseError.new "The ',' on line #{line_number} is not follwed by a value"
      end
      values << val
    end
    values
  end

  def var_list
    return false if not var = variable
    vars = [var]
    while current_token and current_token_type == :","
      next_token
      if not var = variable
        raise ParseError.new "The ',' on line #{line_number} is not followed by a variable"
      end
      vars << var
    end
    vars
  end

  def value
    val = low_boolean_expression || number_expression
    if not val and str = string || gets_statement
      val = Expression.new str, str.line_number
    end
    val
  end

  def low_boolean_expression
    return false if not current_token
    return false if not last_term = low_boolean_term
    while current_token and current_token_type == :or
      next_token
      if not term = low_boolean_term
        raise ParseError.new "The 'or' on line #{line_number} is not followed by a term"
      end
      binary = Binary.new last_term, :or, term, line_number
      last_term = Expression.new binary, binary.line_number
    end
    last_term
  end

  def low_boolean_term
    return false if not current_token
    return false if not last_factor = low_boolean_factor
    while current_token and current_token_type == :and
      next_token
      if not factor = low_boolean_factor
        raise ParseError.new "The 'and' on line #{line_number} is not followed by a factor"
      end
      binary = Binary.new last_factor, :and, factor, line_number
      last_factor = Expression.new binary, binary.line_number
    end
    last_factor
  end

  def low_boolean_factor
    old_position = @line_position
    negated = false
    if current_token and current_token_type == :not
      next_token
      negated = true
    end
    factor = condition || assign
    if not factor
      if not result = high_boolean_expression
        if negated
          raise ParseError.new "The 'not' on line #{line_number} is not followed by a factor"
        end
        @line_position = old_position
        result = false
      end
    else
      result = Expression.new factor, factor.line_number
    end
    if result and negated
      result = Not.new :Not, result, result.line_number
      result = Expression.new result, result.line_number
    end
    result
  end

  def high_boolean_expression
    return false if not current_token
    return false if not last_term = high_boolean_term
    while current_token and current_token_type == :"||"
      next_token
      if not term = high_boolean_term
        raise ParseError.new "The '||' on line #{line_number} is not followed by a term"
      end
      binary = Binary.new last_term, :"||", term, line_number
      last_term = Expression.new binary, binary.line_number
    end
    last_term
  end

  def high_boolean_term
    return false if not current_token
    return false if not last_factor = high_boolean_factor
    while current_token and current_token_type == :"&&"
      next_token
      if not factor = high_boolean_factor
        raise ParseError.new "The '&&' on line #{line_number} is not followed by a factor"
      end
      binary = Binary.new last_factor, :"&&", factor, line_number
      last_factor = Expression.new binary, binary.line_number
    end
    last_factor
  end

  def high_boolean_factor
    return false if not current_token
    return false if Scanner.number_operator? next_token_type
    old_position = @line_position
    negated = false
    if current_token_type == :"!"
      next_token
      negated = true
    end
    factor = boolean || nil_value || call
    if not factor and current_token
      if current_token_type == :"("
        next_token
        if not result = low_boolean_expression
            @line_position = old_position
            result = false
        else
          if not current_token or not current_token_type == :")"
            @line_position = old_position
            result = false
          else
            next_token
          end
        end
      else
        if negated
          raise ParseError.new "The 'not' on line #{line_number} is not followed by a factor"
        end
        @line_position = old_position
        result = false
      end
    else
      result = Expression.new factor, factor.line_number
    end
    if negated and result
      result = Not.new :"!", result, result.line_number
      result = Expression.new result, result.line_number
    end
    result
  end

  def number_expression
    return false if not current_token
    old_position = @line_position
    if current_token_type == :-
      next_token
      if not term = number_term
        raise ParseError.new "The '-' on line #{line_number} is not followed by a term"
      end
      const = Constant.new  0, IntegerSingleton.instance, line_number
      immed = Immediate.new const, const.line_number
      expr = Expression.new immed, immed.line_number
      binary = Binary.new expr, :"-", term, term.line_number
      last_term = Expression.new binary, binary.line_number
    else
      if not last_term = number_term
        @line_position = old_position
        return false
      end
    end
    while current_token and current_token_type == :+ || current_token_type == :-
      operator = current_token_type
      next_token
      if not term = number_term
        raise ParseError.new "The '#{operator.to_s}' on line #{line_number} is not followed by a term"
      end
      binary = Binary.new last_term, operator, term, term.line_number
      last_term = Expression.new binary, binary.line_number
    end
    last_term
  end

  def number_term
    return false if not last_factor = number_factor
    while current_token and current_token_type == :* || current_token_type == :** ||
          current_token_type == :/ || current_token_type == :%
      operator = current_token_type
      next_token
      if not factor = number_factor
        raise ParseError.new "The '#{token_at(@current_position - 1)}' is not followed by a factor in the expression on line #{line_number}"
      end
      binary = Binary.new last_factor, operator, factor, factor.line_number
      last_factor = Expression.new binary, binary.line_number
    end
    last_factor
  end

  def number_factor
    factor = number
    if not factor
      factor = call
      if not factor
        if current_token_type == :"("
          next_token
          factor = number_expression
          if not factor
            factor = assign
            if not factor
              raise ParseError.new "The '(' on line #{line_number} is not followed by an expression"
            else
              factor = Expression.new factor, factor.line_number
            end
          end
          if not current_token or not current_token_type == :")"
            raise ParseError.new "The '(' on line #{line_number} is not followed by a ')'"
          end
          next_token
        end
      else
        factor = Expression.new factor, factor.line_number
      end
    end
    factor
  end

  def condition
    value_condition || number_condition
  end

  def value_condition
    old_position = @line_position
    return false if not current_token
    return false if not left = condition_value
    if not current_token or
          (current_token_type != :is and current_token_type != :== and
           current_token_type != :"!=")
      @line_position = old_position
      return false
    end
    operator = current_token_type
    next_token
    if not right = condition_value
      raise ParseError.new "The '#{operator}' on line #{line_number} is not follwed by an expression"
    end
    Condition.new left, operator, right, line_number
  end

  def number_condition
    old_position = @line_position
    return false if not current_token
    return false if not left = number_expression
    if not current_token or
          (current_token_type != :> and current_token_type != :< and
           current_token_type != :>= and current_token_type != :<=)
      @line_position = old_position
      return false
    end
    operator = current_token_type
    next_token
    if not right = number_expression
      raise ParseError.new "The '#{operator}' on line #{line_number} is not follwed by a number expression"
    end
    Condition.new left, operator, right, line_number
  end

  def number
    return false if not num = integer || float
    Expression.new num, num.line_number
  end

  def designator
    return false if not var = variable
    Location.new var, var.line_number
  end

  def condition_value
    condition_value = number_expression || high_boolean_expression
    if not condition_value and str = string || gets_statement
      condition_value = Expression.new str, str.line_number
    end
    condition_value
  end

  def variable
    return false if not name = identifier
    if name.data[0] == ?$
      @symbol_table.add_to_global_scope name.data
    else
      @symbol_table.add_to_scope name.data
    end
    Var.new name.data, name.line_number
  end

  def string
    return false if not current_token
    return false if current_token_type != :string
    token = current_token
    next_token
    const = Constant.new token.data, StringSingleton.instance, token.line_number
    Immediate.new const, const.line_number
  end

  def float
    return false if not current_token
    return false if current_token_type != :float
    token = current_token
    next_token
    const = Constant.new token.data.to_f, FloatSingleton.instance, token.line_number
    Immediate.new const, const.line_number
  end

  def integer
    return false if not current_token
    return false if current_token_type != :integer
    token = current_token
    next_token
    const = Constant.new token.data.to_i, IntegerSingleton.instance, token.line_number
    Immediate.new const, const.line_number
  end

  def boolean
    return false if not current_token
    return false if current_token_type != :true and current_token_type != :false
    token = current_token
    value = current_token_type == :true
    next_token
    const = Constant.new value, BooleanSingleton.instance, token.line_number
    Immediate.new const, const.line_number
  end

  def nil_value
    return false if not current_token
    return false if current_token_type != :nil
    token = current_token
    next_token
    const = Constant.new nil, NilSingleton.instance, token.line_number
    Immediate.new const, const.line_number
  end

  def identifier
    return false if not current_token
    return false if current_token_type != :identifier
    next_token
    token_at(@line_position - 1)
  end
end

