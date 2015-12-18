class CodeWriter
  def initialize(filename)
    @file = File.open(filename, "w")
    @eq = 0
    @lt = 0
    @gt = 0
    @function_name = ""
    @vm_filename = ""
    @call = 0
    @next_comment = ""
  end

  def setFileName(filename)
    @vm_filename = filename
  end

  def writeInit
    comment "set initial stack pointer to 0x100"
    emit ["@256", "D=A", "@SP", "M=D"]
    writeCall "Sys.init", 0
  end

  def writeLabel(label)
    comment "label #{label}"
    emit ["(l.#{@function_name}$#{label})"]
  end

  def writeGoto(label)
    comment "goto #{label}"
    emit ["@l.#{@function_name}$#{label}", "0;JMP"]
  end

  def writeIf(label)
    comment "if-goto #{label}"
    emit ["@SP", "AM=M-1", "D=M", "@l.#{@function_name}$#{label}", "D;JNE"]
  end

  def writeCall(function_name, num_args)
    comment "call #{function_name}"
    emit ["@f.#{function_name}", "D=A", "@R13", "M=D"] # store function address to R13
    emit ["@#{num_args+5}", "D=A", "@R14", "M=D"] # store num_args + 5 to R14
    emit ["@CALL#{@call}_#{function_name}.RET", "D=A"] # store return address to D
    emit ["@FUNCTION_CALL", "0;JMP"] # goto FUNCTION_CALL
    emit ["(CALL#{@call}_#{function_name}.RET)"] # set return address
    @call = @call + 1
  end

  def writeReturn
    comment "return #{@function_name}"
    emit ["@FUNCTION_RETURN", "0;JMP"]
  end

  def writeFunction(function_name, num_locals)
    @function_name = function_name
    comment "function #{function_name}"
    emit ["(f.#{function_name})"]
    return if num_locals == 0

    emit ["@SP", "A=M"]
    (num_locals - 1).times { emit ["M=0", "A=A+1"] }
    emit ["M=0"]
    case num_locals
    when 1 then emit ["@SP", "M=M+1"]
    when 2 then emit ["@SP", "M=M+1", "M=M+1"]
    else emit ["@#{num_locals}", "D=A", "@SP", "M=D+M"]
    end
  end

  def writeArithmetic(command)
    comment "#{command}"
    case command
    when "add" then emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "M=D+M", "@SP", "M=M+1"]
    when "sub" then emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "M=M-D", "@SP", "M=M+1"]
    when "neg" then emit ["@SP", "AM=M-1", "M=-M", "@SP", "M=M+1"]
    when "and" then emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "M=D&M", "@SP", "M=M+1"]
    when "or"  then emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "M=D|M", "@SP", "M=M+1"]
    when "not" then emit ["@SP", "AM=M-1", "M=!M", "@SP", "M=M+1"]
    when "eq"  then
      emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "D=M-D", "@EQ#{@eq}.TRUE", "D;JEQ", "D=-1", "(EQ#{@eq}.TRUE)", "D=!D", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      @eq = @eq + 1
    when "lt" then
      emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "D=M-D", "@LT#{@lt}.TRUE", "D;JLT", "D=0", "@LT#{@lt}.FIN", "0;JMP", "(LT#{@lt}.TRUE)", "D=-1", "(LT#{@lt}.FIN)", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      @lt = @lt + 1
    when "gt" then
      emit ["@SP", "AM=M-1", "D=M", "@SP", "AM=M-1", "D=M-D", "@GT#{@gt}.TRUE", "D;JGT", "D=0", "@GT#{@gt}.FIN", "0;JMP", "(GT#{@gt}.TRUE)", "D=-1", "(GT#{@gt}.FIN)", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      @gt = @gt + 1
    end
  end

  def writePushPop(command, segment, index)
    comment "#{command} #{segment} #{index}"
    case segment
    when "constant" then # no pop for constant segment
      if index == 0 || index == 1
        emit ["@SP", "A=M", "M=#{index}", "@SP", "M=M+1"]
      elsif index == 2
        emit ["@SP", "A=M", "M=1", "M=M+1", "@SP", "M=M+1"]
      else
        emit ["@#{index}", "D=A", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      end
      return
    when "static" then
      if command == :C_PUSH
        emit ["@v.#{@vm_filename}.#{index}", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      else
        emit ["@SP", "AM=M-1", "D=M", "@v.#{@vm_filename}.#{index}", "M=D"]
      end
      return
    when "pointer" then
      if command == :C_PUSH
        emit ["@#{3+index}", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      else
        emit ["@SP", "AM=M-1", "D=M", "@#{3+index}", "M=D"]
      end
      return
    when "temp" then
      if command == :C_PUSH
        emit ["@#{5+index}", "D=M", "@SP", "A=M", "M=D", "@SP", "M=M+1"]
      else
        emit ["@SP", "AM=M-1", "D=M", "@#{5+index}", "M=D"]
      end
      return
    when "local"    then label = "LCL"
    when "argument" then label = "ARG"
    when "this"     then label = "THIS"
    when "that"     then label = "THAT"
    end

    if command == :C_PUSH
      case index
      when 0 then emit ["@#{label}", "A=M", "D=M"]
      when 1 then emit ["@#{label}", "A=M+1", "D=M"]
      when 2 then emit ["@#{label}", "A=M+1", "A=A+1", "D=M"]
      else emit ["@#{label}", "D=M", "@#{index}", "A=D+A", "D=M"]
      end
      emit_pushD
    else
      case index
      when 0 then emit ["@SP", "AM=M-1", "D=M", "@#{label}", "A=M", "M=D"]
      when 1 then emit ["@SP", "AM=M-1", "D=M", "@#{label}", "A=M+1", "M=D"]
      when 2..6 then
      emit ["@SP", "AM=M-1", "D=M", "@#{label}", "A=M+1"]
      (index - 1).times { emit ["A=A+1"] }
      emit ["M=D"]
      else emit ["@#{label}", "D=M", "@#{index}", "D=D+A", "@R15", "M=D", "@SP", "AM=M-1", "D=M", "@R15", "A=M", "M=D"]
      end
    end
  end

  def close
    comment "End of the program"
    emit ["(END_LOOP)", "@END_LOOP", "0;JMP"]

    # support for function call (D is return address, R13 is function address, R14 is num_args+5)
    comment "Common routine for function call"
    emit ["(FUNCTION_CALL)"]
    emit_pushD  # push return address
    emit ["@LCL", "D=M"]
    emit_pushD  # push old LCL
    emit ["@ARG", "D=M"]
    emit_pushD  # push old ARG
    emit ["@THIS", "D=M"]
    emit_pushD  # push old THIS
    emit ["@THAT", "D=M"]
    emit_pushD  # push old THAT
    emit ["@SP", "D=M", "@R14", "D=D-M", "@ARG", "M=D"] # ARG = SP - n - 5
    emit ["@SP", "D=M", "@LCL", "M=D"] # LCL = SP
    emit ["@R13", "A=M", "0;JMP"] # goto function

    comment "Common routine for function return"
    emit ["(FUNCTION_RETURN)"]
    emit ["@5", "D=A", "@LCL", "D=M-D", "@R15", "M=D"] # FRAME = LCL - 5
    emit ["A=D", "D=M", "@R14", "M=D"] # RET = *FRAME
    emit ["@SP", "AM=M-1", "D=M", "@ARG", "A=M", "M=D"] # *ARG = pop()
    emit ["@ARG", "D=M", "@SP", "M=D+1"] # SP = ARG + 1
    emit ["@R15", "MD=M+1"] # FRAME = FRAME + 1
    emit ["A=D", "D=M", "@LCL", "M=D"] # LCL = *FRAME
    emit ["@R15", "MD=M+1"] # FRAME = FRAME + 1
    emit ["A=D", "D=M", "@ARG", "M=D"] # ARG = *FRAME
    emit ["@R15", "MD=M+1"] # FRAME = FRAME + 1
    emit ["A=D", "D=M", "@THIS", "M=D"] # THIS = *FRAME
    emit ["@R15", "MD=M+1"] # FRAME = FRAME + 1
    emit ["A=D", "D=M", "@THAT", "M=D"] # THAT = *FRAME
    emit ["@R14", "A=M", "0;JMP"] # goto RET

    @file.close
  end

  def emit(asms)
    asms.each do |asm|
      comment = (@next_comment != "") ? " // #{@next_comment}" : ""
      @next_comment = ""
      if asm.start_with?("(") || asm.start_with?("//")
        @file.puts (asm + comment)
      else
        @file.puts ("  " + asm + comment)
      end
    end
  end

  def comment(comment)
    @next_comment = comment
  end

  def emit_pushD
    emit ["@SP", "A=M", "M=D", "@SP", "M=M+1"]
  end
end
