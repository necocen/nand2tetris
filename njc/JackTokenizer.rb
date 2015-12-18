require "cgi"

class JackTokenizer
  def initialize(file)
    @file = file
    @current_line = nil
    @next_ = nil
    @next_type = nil
    @next_token = nil
    @current_token = nil
    @current_type = nil
  end

  def hasMoreTokens
    while true
      if @current_line == nil || @current_line.length == 0
        @current_line = @file.gets
      end
      return false if @current_line == nil

      @current_line.lstrip!
      next if @current_line.length == 0

      # remove block comment and goto first
      if @current_line.start_with? "/*"
        # read lines until encounter "*/"
        index = nil
        loop do
          index = @current_line.index("*/")
          break if index != nil
          @current_line = @file.gets
          return false if @current_line == nil # EOF
        end
        @current_line = @current_line[(index+2)..-1]
        next
      end

      # remove line comment and goto first
      if @current_line.start_with? "//"
        @current_line = nil
        next
      end

      # find symbol and return true
      symbols = "{}()[].,;+-*/&|<>=~".split(//)
      symbols.each do |symbol|
        if @current_line.start_with? symbol
          @next_token = symbol
          @next_type = :SYMBOL
          @current_line = @current_line[1..-1]
          return true
        end
      end

      # find string literal and return true
      if @current_line.start_with? "\""
        @current_line = @current_line[1..-1]
        index = @current_line.index("\"")
        return false if index == nil # string literal must not contain linebreaks
        @next_token = @current_line[0...index]
        @next_type = :STRING_CONST
        @current_line = @current_line[(index+1)..-1]
        return true
      end

      # find integer literal
      if @current_line =~ /^(\d+)/
        @next_token = $1
        @next_type = :INT_CONST
        @current_line = @current_line[(@next_token.length)..-1]
        return true
      end

      # find identifier and keywords

      keywords = ["class", "constructor", "function", "method", "field", "static", "var", "int", "char", "boolean", "void", "true", "false", "null", "this", "let", "do", "if", "else", "while", "return"]

      if @current_line =~ /^([a-zA-Z0-9_]+)/
        @next_token = $1
        @next_type = (keywords.include? $1) ? :KEYWORD : :IDENTIFIER
        @current_line = @current_line[(@next_token.length)..-1]
        return true
      end

      return false
    end
  end

  def advance
    if self.hasMoreTokens
      @current_token = @next_token
      @current_type = @next_type
    else
      @current_token = nil
      @current_type = nil
    end
    @next_token = nil
    @next_type = nil
  end

  def tokenType
    @current_type
  end

  def keyWord
    @current_token
  end

  def symbol
    @current_token
  end

  def stringVal
    @current_token
  end

  def intVal
    @current_token.to_i
  end

  def identifier
    @current_token
  end

  def currentTokenXML
    case @current_type
    when :KEYWORD then return "<keyword>#{@current_token}</keyword>"
    when :SYMBOL then return "<symbol>#{CGI.escapeHTML(@current_token)}</symbol>"
    when :IDENTIFIER then return "<identifier>#{@current_token}</identifier>"
    when :INT_CONST then return "<integerConstant>#{@current_token.to_i}</integerConstant>"
    when :STRING_CONST then return "<stringConstant>#{@current_token}</stringConstant>"
    end
  end

end
