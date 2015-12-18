class VMWriter
  def initialize(file)
    @file = file
  end

  def writePush(segment, index)
    @file.puts "push #{segment} #{index}"
  end

  def writePop(segment, index)
    @file.puts "pop #{segment} #{index}"
  end

  def writeArithmetic(command)
    @file.puts "#{command}"
  end

  def writeLabel(label)
    @file.puts "label #{label}"
  end

  def writeGoto(label)
    @file.puts "goto #{label}"
  end

  def writeIf(label)
    @file.puts "if-goto #{label}"
  end

  def writeCall(name, nArgs)
    @file.puts "call #{name} #{nArgs}"
  end

  def writeFunction(name, nLocals)
    @file.puts "function #{name} #{nLocals}"
  end

  def writeReturn
    @file.puts "return"
  end

  def writeComment(comment)
    @file.puts "// #{comment}"
  end

end
