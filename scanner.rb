class Token
  attr_accessor :token_type, :data, :line_number

  def initialize(token_type, data, line_number)
    @token_type = token_type
    @data = data
    @line_number = line_number
  end

  def to_s
    if token_type == :identifier or token_type == :integer or
       token_type == :float or token_type == :string
      "#{@token_type}<#{@data}>@#{@line_number}"
    else
      "#{@data}@#{@line_number}"
    end
  end
end

class ScannerError < StandardError
end

class Scanner
  @@KEYWORDS = [:if, :print, :"=", :",", :true, :false, :nil,
                :-, :+, :*, :/, :%, :"(", :")",
                :"!", :"||", :"&&", :not, :or, :and,
                :if, :elif, :else, :end, :is, :==,
                :"!=", :>, :<, :>=, :<=, :while,
                :puts, :**]

  @@NUMBER_OPS = [:-, :+, :*, :**, :/, :%]

  @@LINE_CONCATENATORS = [:",", :-, :+, :*, :**, :/, :%, :"!", :"||",
                          :"&&", :not, :or, :and, :if, :elif,
                          :is, :==, :"!=", :>, :<, :>=, :<=,
                          :while, :**]

  attr_accessor :tokenized_lines, :new_tokens

  def initialize
    @tokenized_lines = []
  end

  def self.is_keyword?(symbol)
		@@KEYWORDS.find_index(symbol) != nil
  end

  def self.number_operator?(symbol)
    @@NUMBER_OPS.find_index(symbol) != nil
  end

  def self.line_concatenator?(symbol)
    @@LINE_CONCATENATORS.find_index(symbol) != nil
  end

  def current_line
    @lines[@current_line_number]
  end

  def next_line
    @current_line_number += 1
  end

  def current_char
    @lines[@current_line_number][@line_position]
  end

  def next_char
    @line_position += 1
  end

  def read_and_scan(file_name)
    @lines = File.readlines(file_name) 
    @current_line_number = 0
    string_buffer = ""
    line_overlap = false
    while @current_line_number < @lines.size
      @line_position = 0
      next if not current_char
      if not line_overlap
        string_buffer = ""
        strings = []
      else
        line_overlap = false
      end
      while @line_position < current_line.size
        if string_buffer.size > 0 
          if current_char =~ /\s/
            strings << string_buffer
            string_buffer = ""
          elsif new_token? string_buffer, current_char
            strings << string_buffer
            string_buffer = current_char
          end
        else
          string_buffer << current_char
        end
        next_char
      end
      if string_buffer.size > 0 and not line_overlap
        strings << string_buffer
        string_buffer = ""
      end
      tokens = to_tokens(strings, @current_line_number)
      if not line_overlap
        @tokenized_lines << tokens 
      else
        puts "poop"
      end
      next_line
    end
  end

  def scan_line(line, line_number)
    @new_tokens ||= []
    @unclosed_parentheses ||= 0
    @line_position = 0
    tokens = []
    string_buffer = ""
    while @line_position < line.size
      break if not line[@line_position]
      if line[@line_position, 1] =~ /\s/
        if string_buffer.size > 0
          @new_tokens << to_token(string_buffer, line_number)
          string_buffer = ""
        end
      elsif string_buffer.size > 0
        if line[@line_position] == ?(
          @unclosed_parentheses += 1
        elsif @unclosed_parentheses > 0 and line[@line_position] == ?)
          @unclosed_parentheses -= 1
          if @unclosed_parentheses < 0
            raise ScannerError.new "Unexpected close of parenthesis on line #{line_number}"
          end
        end
        if new_token? string_buffer, line[@line_position, 1]
          @new_tokens << to_token(string_buffer, line_number)
          string_buffer = line[@line_position, 1]
        else
          string_buffer << line[@line_position]
        end
      else
        string_buffer << line[@line_position]
      end
      next_char
    end
    if string_buffer.size > 0
      @new_tokens << to_token(string_buffer, line_number)
    end 
    if (not @unclosed_parenthesis or @unclosed_parenthesis == 0) and
        not Scanner.line_concatenator? @new_tokens[-1].token_type
      finished = true
    end
    finished
  end

  def new_token?(string_buffer, char)
    if (string_buffer =~ /^[$]?[A-Za-z0-9_]*$/ and char =~ /[A-Za-z0-9_]/) or
        (string_buffer =~ /^[0-9]+/ and char =~ /[0-9.]/) or
        (string_buffer =~ /^[0-9]+[.][0-9]*/ and char =~ /[0-9]/) or
        (string_buffer =~ /^[0-9]*$/ and char =~ /[0-9]/) or
        (string_buffer =~ /^[!><=]$/ and char == "=") or
        (string_buffer =~ /^["]([^"] | [\\]["])*/ and char != ?") or
        (string_buffer =~ /^["]([^"] | [\\]["])*/ and char == ?") or
        (string_buffer == "|" and char == ?|) or
        (string_buffer == "&" and char == ?&) or
        (string_buffer == "*" and char == ?*)
      result = false
    else
      result = true
    end
  end

  def to_tokens(strings, line_number)
    tokens = []
    strings.each do |string|
      tokens << to_token(string, line_number)
    end
    tokens
  end

  def to_token(string, line_number)
    if Scanner.is_keyword? string.to_sym
      token = Token.new(:"#{string}", string, line_number)
    elsif string =~ /^[0-9]+[.][0-9]+/
      token = Token.new(:float, string, line_number)
    elsif string =~ /^[0-9]*$/
      token = Token.new(:integer, string, line_number)
    elsif string =~ /^[$]?[A-Za-z][A-Za-z0-9_]*$/
      token = Token.new(:identifier, string, line_number)
    elsif string =~ /^["]([^"] | [\\]["])*["]$/
      token = Token.new(:string, string[1...(string.size - 1)], line_number)
    else
      raise ScannerError.new("Illegal symbol '#{string}' on line #{line_number}")
    end
    token
  end
end

