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
  KEYWORDS = [:if, :print, :"=", :",", :true, :false, :nil,
              :"-", :"+", :"*", :"/", :"%", :"(", :")",
              :"!", :"||", :"&&", :"not", :"or", :"and",
              :"if", :"elif", :"else", :"end", :"is", :"==",
              :"!=", :">", :"<", :">=", :"<=", :"while",
              :"puts", :"**"]

  NUMBER_OPS = [:"-", :"+", :"*", :"**", :"/", :"%"]

  attr_accessor :tokenized_lines

  def initialize
    @tokenized_lines = []
  end

  def self.is_keyword?(keyword)
		KEYWORDS.find_index(keyword) != nil
  end

  def self.number_operator?(operator)
    NUMBER_OPS.find_index(operator) != nil
  end

  def read_and_scan(file_name)
    scan File.readlines(file_name) 
  end

  def scan(lines)
		lines.each_with_index do |line, i|
      tokens = scan_line line, i
      if tokens.size > 0
        @tokenized_lines << tokens
      end
    end
  end

  def scan_line(line, line_number)
    tokens = []
    line.split.each do |word|
      break if word[0] == ?#
      strings = []
      current_string = ""
      word.each_char do |c|
        if current_string.size > 0
          if current_string =~ /^[$]?[A-Za-z0-9_]*$/ and c =~ /[A-Za-z0-9_]/
            current_string << c
          elsif current_string =~ /^[0-9]+$/ and c =~ /[0-9.]/
            current_string << c
          elsif current_string =~ /^[0-9]+[.][0-9]*/ and c =~ /[0-9]/
            current_string << c
          elsif current_string =~ /^[0-9]*$/ and c =~ /[0-9]/
            current_string << c
          elsif current_string =~ /^[!><=]$/ and c == "="
            current_string << c
          elsif current_string =~ /^["]([^"] | [\\]["])*/ and c != "\""
            current_string << c
          elsif current_string =~ /^["]([^"] | [\\]["])*/ and c == "\""
            strings << current_string + "\""
            current_string = ""
          elsif current_string == "|" and c == "|"
            strings << "||"
            current_string = ""
          elsif current_string == "&" and c == "&"
            strings << "&&"
            current_string = ""
          elsif current_string == "*" and c == "*"
            strings << "**"
            current_string = ""
          else
            strings << current_string
            current_string = c
          end
        else
          current_string << c
        end
      end
      if current_string.size > 0
        strings << current_string
      end
      strings.each do |string|
        if Scanner.is_keyword? string.to_sym
          tokens << Token.new(:"#{string}", string, line_number + 1)
        elsif string =~ /^[0-9]+[.][0-9]+/
          tokens << Token.new(:float, string, line_number + 1)
        elsif string =~ /^[0-9]*$/
          tokens << Token.new(:integer, string, line_number + 1)
        elsif string =~ /^[$]?[A-Za-z][A-Za-z0-9_]*$/
          tokens << Token.new(:identifier, string, line_number + 1)
        elsif string =~ /^["]([^"] | [\\]["])*["]$/
          tokens << Token.new(:string, string[1...(string.size - 1)], line_number + 1)
        else
          raise ScannerError.new "Illegal symbol '#{string}' in on line #{line_number + 1}"
        end
      end
    end
    tokens
  end
end

