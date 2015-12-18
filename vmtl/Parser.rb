class Parser
  def initialize(file)
    @file = file
  end

  def hasMoreCommands
    while @next_line == nil
      line = @file.gets
      return false if line == nil
      line = line.split("//")[0].strip
      @next_line = line if line.length > 0
    end
    return true
  end

  def advance
    @current_line = @next_line
    @next_line = nil
  end

  def commandType
    command = @current_line.split(/\s+/)[0]
    case command
    when "push" then return :C_PUSH
    when "pop" then return :C_POP
    when "label" then return :C_LABEL
    when "goto" then return :C_GOTO
    when "if-goto" then return :C_IF
    when "function" then return :C_FUNCTION
    when "return" then return :C_RETURN
    when "call" then return :C_CALL
    when "add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not" then return :C_ARITHMETIC
    end
  end

  def arg1
    if self.commandType == :C_ARITHMETIC
      @current_line.split(/\s+/)[0]
    else
      @current_line.split(/\s+/)[1]
    end
  end

  def arg2
    @current_line.split(/\s+/)[2].to_i
  end

end
