require File.dirname(__FILE__) + "/JackTokenizer"
require File.dirname(__FILE__) + "/SymbolTable"
require File.dirname(__FILE__) + "/VMWriter"

class CompilationEngine

  def initialize(inputfile, treefile, outputfile)
    @outputfile = treefile
    @tokenizer = JackTokenizer.new(inputfile)
    @symbols = SymbolTable.new()
    @vm = VMWriter.new(outputfile)
    @whileCount = 0
    @ifCount = 0
    @isInsideMethod = false
    @fieldCount = 0
  end

  def compileClass
    @tokenizer.advance
    @outputfile.puts "<class>"
    @outputfile.puts @tokenizer.currentTokenXML # 'class'
    @tokenizer.advance
    @className = @tokenizer.identifier
    @outputfile.puts @tokenizer.currentTokenXML # className
    @tokenizer.advance
    @outputfile.puts @tokenizer.currentTokenXML # {
    @tokenizer.advance

    # classVarDec
    while @tokenizer.tokenType == :KEYWORD && (@tokenizer.keyWord == "static" || @tokenizer.keyWord == "field")
      self.compileClassVarDec
    end

    # subroutineDec
    while @tokenizer.tokenType == :KEYWORD
      self.compileSubroutine
    end
    @outputfile.puts @tokenizer.currentTokenXML # }
    @outputfile.puts "</class>"
  end

  def compileClassVarDec
    @outputfile.puts "<classVarDec>"
    @outputfile.puts @tokenizer.currentTokenXML # 'static' | 'field'
    kind = (@tokenizer.keyWord == "static" ? :STATIC : :FIELD)
    @tokenizer.advance
    @outputfile.puts @tokenizer.currentTokenXML # type
    type = @tokenizer.identifier
    @tokenizer.advance
    varName = @tokenizer.identifier
    @outputfile.puts "<identifier category=\"defined\" type=\"#{type}\" kind=\"#{kind}\" index=\"#{@symbols.varCount(kind)}\">#{varName}</identifier>" # varName
    @symbols.define varName, type, kind
    @fieldCount += 1 if kind == :FIELD
    @tokenizer.advance
    while @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ","
      @outputfile.puts @tokenizer.currentTokenXML # ,
      @tokenizer.advance
      varName = @tokenizer.identifier
      @outputfile.puts "<identifier category=\"defined\" type=\"#{type}\" kind=\"#{kind}\" index=\"#{@symbols.varCount(kind)}\">#{varName}</identifier>" # varName
      @symbols.define varName, type, kind
      @fieldCount += 1 if kind == :FIELD
      @tokenizer.advance
    end
    @outputfile.puts @tokenizer.currentTokenXML # semicolon
    @tokenizer.advance
    @outputfile.puts "</classVarDec>"
  end

  def compileSubroutine
    @symbols.startSubroutine # clear subroutine symbol table
    @outputfile.puts "<subroutineDec>"
    kind = @tokenizer.keyWord
    @isInsideMethod = (kind == "method")
    @outputfile.puts @tokenizer.currentTokenXML # 'constructor' | 'function' | 'method'
    @tokenizer.advance
    returnType = @tokenizer.identifier
    @outputfile.puts @tokenizer.currentTokenXML # 'void' | type
    @tokenizer.advance
    subroutineName = @tokenizer.identifier
    @outputfile.puts "<identifier category=\"defined\" returnType=\"#{returnType}\" kind=\"#{kind}\">#{subroutineName}</identifier>" # subroutineName
    @tokenizer.advance
    @outputfile.puts @tokenizer.currentTokenXML # '('
    @tokenizer.advance
    self.compileParameterList                   # parameterList
    @outputfile.puts @tokenizer.currentTokenXML # ')'
    @tokenizer.advance
    @outputfile.puts "<subroutineBody>"
    @outputfile.puts @tokenizer.currentTokenXML # '{'
    @tokenizer.advance
    numLocals = 0
    while @tokenizer.tokenType == :KEYWORD && @tokenizer.keyWord == "var"
      numLocals += self.compileVarDec                        # varDec*
    end
    @vm.writeComment "Function: #{@className}.#{subroutineName} with #{numLocals} local variables"
    @vm.writeFunction "#{@className}.#{subroutineName}", numLocals
    if kind == "constructor"
      @vm.writeComment "Allocating memory for constructor: #{@fieldCount}"
      @vm.writePush "constant", @fieldCount # size of the class
      @vm.writeCall "Memory.alloc", 1
      @vm.writePop "pointer", 0
    elsif kind == "method"
      @vm.writePush "argument", 0
      @vm.writePop "pointer", 0
    end
    self.compileStatements                      # statements
    @outputfile.puts @tokenizer.currentTokenXML # '}'
    @tokenizer.advance
    @outputfile.puts "</subroutineBody>"
    @outputfile.puts "</subroutineDec>"
    @isInsideMethod = false
  end

  def compileParameterList
    @outputfile.puts "<parameterList>"
    if @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ")" # empty list
      @outputfile.puts "</parameterList>"
      return
    end
    @outputfile.puts @tokenizer.currentTokenXML # type
    type = @tokenizer.identifier
    @tokenizer.advance
    varName = @tokenizer.identifier
    @outputfile.puts "<identifier category=\"defined\" type=\"#{type}\" kind=\"ARG\" index=\"#{@symbols.varCount(:ARG)}\">#{varName}</identifier>" # varName
    @symbols.define varName, type, :ARG
    @tokenizer.advance
    while @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ","
      @outputfile.puts @tokenizer.currentTokenXML # ,
      @tokenizer.advance
      @outputfile.puts @tokenizer.currentTokenXML # type
      @tokenizer.advance
      varName = @tokenizer.identifier
      @outputfile.puts "<identifier category=\"defined\" type=\"#{type}\" kind=\"ARG\" index=\"#{@symbols.varCount(:ARG)}\">#{varName}</identifier>" # varName
      @symbols.define varName, type, :ARG
      @tokenizer.advance
    end
    @outputfile.puts "</parameterList>"
  end

  def compileVarDec
    @outputfile.puts "<varDec>"
    @outputfile.puts @tokenizer.currentTokenXML # 'var'
    @tokenizer.advance
    type = @tokenizer.identifier
    @outputfile.puts @tokenizer.currentTokenXML # type
    @tokenizer.advance
    varName = @tokenizer.identifier
    @outputfile.puts "<identifier category=\"defined\" type=\"#{type}\" kind=\"VAR\" index=\"#{@symbols.varCount(:VAR)}\">#{varName}</identifier>" # varName
    @symbols.define varName, type, :VAR
    varCount = 1
    @tokenizer.advance
    while @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ","
      @outputfile.puts @tokenizer.currentTokenXML # ,
      @tokenizer.advance
      varName = @tokenizer.identifier
      @outputfile.puts "<identifier category=\"defined\" type=\"#{type}\" kind=\"VAR\" index=\"#{@symbols.varCount(:VAR)}\">#{varName}</identifier>" # varName
      @symbols.define varName, type, :VAR
      varCount += 1
      @tokenizer.advance
    end
    @outputfile.puts @tokenizer.currentTokenXML # semicolon
    @tokenizer.advance
    @outputfile.puts "</varDec>"
    return varCount
  end

  def compileStatements
    @outputfile.puts "<statements>"
    while @tokenizer.tokenType == :KEYWORD
      case @tokenizer.keyWord
      when "let" then self.compileLet
      when "if" then self.compileIf
      when "while" then self.compileWhile
      when "do" then self.compileDo
      when "return" then self.compileReturn
      else
        @outputfile.puts "</statements>"
        return
      end
    end
    @outputfile.puts "</statements>"
  end

  def compileDo
    @outputfile.puts "<doStatement>"
    @outputfile.puts @tokenizer.currentTokenXML # 'do'
    @tokenizer.advance
    self.compileSubroutineCall
    @vm.writePop "temp", 0 # cleanup subroutine dummy retVal
    @outputfile.puts @tokenizer.currentTokenXML # ';'
    @tokenizer.advance
    @outputfile.puts "</doStatement>"
  end

  def compileLet
    @outputfile.puts "<letStatement>"
    @outputfile.puts @tokenizer.currentTokenXML # 'let'
    @tokenizer.advance
    varName = @tokenizer.identifier
    type = @symbols.typeOf varName
    kind = @symbols.kindOf varName
    index = @symbols.indexOf varName
    @outputfile.puts "<identifier category=\"used\" type=\"#{type}\" kind=\"#{kind}\" index=\"#{index}\">#{varName}</identifier>" # varName
    @tokenizer.advance
    isArray = false
    if @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == "["
      isArray = true
      @outputfile.puts @tokenizer.currentTokenXML # '['
      @tokenizer.advance
      self.compileExpression                      # expression
      @vm.writePop "temp", 1                      # store array index
      @outputfile.puts @tokenizer.currentTokenXML # ']'
      @tokenizer.advance
      @vm.writeComment "let #{varName}[]"
    else
      @vm.writeComment "let #{varName}"
    end
    @outputfile.puts @tokenizer.currentTokenXML # '='
    @tokenizer.advance
    self.compileExpression                      # expression
    @outputfile.puts @tokenizer.currentTokenXML # ';'
    @tokenizer.advance
    if isArray
      self.pushVar varName
      @vm.writePush "temp", 1
      @vm.writeArithmetic "add"
      @vm.writePop "pointer", 1
      @vm.writePop "that", 0
    else
      self.popVar varName
    end
    @outputfile.puts "</letStatement>"
  end

  def compileWhile
    @outputfile.puts "<whileStatement>"
    label = "while_#{@whileCount}"
    @vm.writeComment "While loop #{@whileCount}"
    @whileCount += 1
    @vm.writeLabel label
    @outputfile.puts @tokenizer.currentTokenXML # 'while'
    @tokenizer.advance
    @outputfile.puts @tokenizer.currentTokenXML # '('
    @tokenizer.advance
    self.compileExpression                      # expression
    @outputfile.puts @tokenizer.currentTokenXML # ')'
    @tokenizer.advance
    @vm.writeArithmetic "not"
    @vm.writeIf "#{label}_end"
    @outputfile.puts @tokenizer.currentTokenXML # '{'
    @tokenizer.advance
    self.compileStatements                      # statements
    @outputfile.puts @tokenizer.currentTokenXML # '}'
    @tokenizer.advance
    @vm.writeGoto "#{label}"
    @vm.writeLabel "#{label}_end"
    @outputfile.puts "</whileStatement>"
  end

  def compileReturn
    @vm.writeComment "return"
    @outputfile.puts "<returnStatement>"
    @outputfile.puts @tokenizer.currentTokenXML # 'return'
    @tokenizer.advance

    # return if there's no return value
    if @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ";"
      @outputfile.puts @tokenizer.currentTokenXML # ';'
      @tokenizer.advance
      @outputfile.puts "</returnStatement>"
      @vm.writePush "constant", 0
      @vm.writeReturn
      return
    end

    self.compileExpression
    @vm.writeReturn
    @outputfile.puts @tokenizer.currentTokenXML # ';'
    @tokenizer.advance
    @outputfile.puts "</returnStatement>"
  end

  def compileIf
    @outputfile.puts "<ifStatement>"
    @vm.writeComment "If statement #{@ifCount}"
    label = "if_#{@ifCount}"
    @ifCount += 1
    @outputfile.puts @tokenizer.currentTokenXML # 'if'
    @tokenizer.advance
    @outputfile.puts @tokenizer.currentTokenXML # '('
    @tokenizer.advance
    self.compileExpression                      # expression
    @vm.writeArithmetic "not"
    @outputfile.puts @tokenizer.currentTokenXML # ')'
    @tokenizer.advance
    @vm.writeIf "#{label}_else"
    @outputfile.puts @tokenizer.currentTokenXML # '{'
    @tokenizer.advance
    self.compileStatements                      # statements
    @outputfile.puts @tokenizer.currentTokenXML # '}'
    @tokenizer.advance
    @vm.writeGoto "#{label}_end"

    if @tokenizer.tokenType != :KEYWORD || @tokenizer.keyWord != "else"
      @outputfile.puts "</ifStatement>"
      @vm.writeLabel "#{label}_else"
      @vm.writeLabel "#{label}_end"
      return
    end

    # else clause
    @outputfile.puts @tokenizer.currentTokenXML # 'else'
    @tokenizer.advance
    @vm.writeLabel "#{label}_else"
    @outputfile.puts @tokenizer.currentTokenXML # '{'
    @tokenizer.advance
    self.compileStatements                      # statements
    @outputfile.puts @tokenizer.currentTokenXML # '}'
    @tokenizer.advance
    @outputfile.puts "</ifStatement>"
    @vm.writeLabel "#{label}_end"
  end

  def compileExpression
    @outputfile.puts "<expression>"
    self.compileTerm
    while @tokenizer.tokenType == :SYMBOL && ("+-*/&|<>=".split(//).include?(@tokenizer.symbol))
      op = @tokenizer.symbol
      @outputfile.puts @tokenizer.currentTokenXML # op
      @tokenizer.advance
      self.compileTerm
      case op
      when "+" then @vm.writeArithmetic "add"
      when "-" then @vm.writeArithmetic "sub"
      when "&" then @vm.writeArithmetic "and"
      when "|" then @vm.writeArithmetic "or"
      when "<" then @vm.writeArithmetic "lt"
      when ">" then @vm.writeArithmetic "gt"
      when "=" then @vm.writeArithmetic "eq"
      when "*" then @vm.writeCall "Math.multiply", 2
      when "/" then @vm.writeCall "Math.divide", 2
      end
    end
    @outputfile.puts "</expression>"
  end

  def compileTerm
    @outputfile.puts "<term>"
    case @tokenizer.tokenType
    when :INT_CONST then
      @outputfile.puts @tokenizer.currentTokenXML
      @vm.writeComment "Integer literal: #{@tokenizer.intVal}"
      if @tokenizer.intVal >= 0
        @vm.writePush "constant", @tokenizer.intVal
      else
        @vm.writePush "constant", -(@tokenizer.intVal)
        @vm.writeArithmetic "neg"
      end
      @tokenizer.advance
    when :STRING_CONST then
      @outputfile.puts @tokenizer.currentTokenXML
      string = @tokenizer.stringVal
      @vm.writeComment "String literal: \"#{string}\""
      @vm.writePush "constant", string.length
      @vm.writeCall "String.new", 1
      string.codepoints.each do |cp|
        @vm.writePush "constant", cp
        @vm.writeCall "String.appendChar", 2
      end
      @tokenizer.advance
    when :KEYWORD then
      @outputfile.puts @tokenizer.currentTokenXML    # keywordConstant
      @vm.writeComment "Keyword constant: #{@tokenizer.keyWord}"
      case @tokenizer.keyWord
      when "null" then @vm.writePush "constant", 0
      when "false" then @vm.writePush "constant", 0
      when "true" then
        @vm.writePush "constant", 1
        @vm.writeArithmetic "neg"
      when "this" then
        @vm.writePush "pointer", 0
      end
      @tokenizer.advance
    when :SYMBOL then
      if @tokenizer.symbol == "(" # (expression)
        @outputfile.puts @tokenizer.currentTokenXML # '('
        @tokenizer.advance
        self.compileExpression                      # expression
        @outputfile.puts @tokenizer.currentTokenXML # ')'
        @tokenizer.advance
      else
        uop = @tokenizer.symbol
        @outputfile.puts @tokenizer.currentTokenXML # unaryOp
        @tokenizer.advance
        self.compileTerm
        case uop
        when "~" then @vm.writeArithmetic "not"
        when "-" then @vm.writeArithmetic "neg"
        end
      end
      when :IDENTIFIER then
       identifier = @tokenizer.identifier # varName | subroutineName | className
       @tokenizer.advance
       if @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == "[" # varName[expression]
         type = @symbols.typeOf identifier
         kind = @symbols.kindOf identifier
         index = @symbols.indexOf identifier
         @outputfile.puts "<identifier category=\"used\" type=\"#{type}\" kind=\"#{kind}\" index=\"#{index}\">#{identifier}</identifier>" # varName
         @outputfile.puts @tokenizer.currentTokenXML # '['
         @tokenizer.advance
         self.compileExpression                      # expression
         @outputfile.puts @tokenizer.currentTokenXML # ']'
         @tokenizer.advance
         pushVar identifier
         @vm.writeArithmetic "add" # add identifier + index
         @vm.writePop "pointer", 1
         @vm.writePush "that", 0
       elsif @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == "(" # subroutineName(expression)
         self.compileSubroutineCall identifier
       elsif @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == "." # (varName | className).subroutineName(expression)
         self.compileSubroutineCall identifier
       else
         type = @symbols.typeOf identifier
         kind = @symbols.kindOf identifier
         index = @symbols.indexOf identifier
         @outputfile.puts "<identifier category=\"used\" type=\"#{type}\" kind=\"#{kind}\" index=\"#{index}\">#{identifier}</identifier>" # varName
         @vm.writeComment "Variable: #{identifier}"
         pushVar identifier
       end
    end
    @outputfile.puts "</term>"
  end

  def compileExpressionList
    count = 0
    @outputfile.puts "<expressionList>"
    if @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ")" # empty list
      @outputfile.puts "</expressionList>"
      return count
    end
    count += 1
    self.compileExpression
    while @tokenizer.tokenType == :SYMBOL && @tokenizer.symbol == ","
      @outputfile.puts @tokenizer.currentTokenXML # ','
      @tokenizer.advance
      count += 1
      self.compileExpression
    end
    @outputfile.puts "</expressionList>"
    return count
  end

  def compileSubroutineCall(prevToken = nil)
    if prevToken != nil
      subroutineName = prevToken # subroutineName | className | varName
    else
      subroutineName = @tokenizer.identifier # subroutineName | className | varName
      @tokenizer.advance
    end
    prefix = ""
    needsThis = false
    varName = nil
    if @tokenizer.symbol == "." # (className|varName).subroutineName
      @tokenizer.advance
      if @symbols.kindOf(subroutineName) == :NONE
        # undefined varName is considered as className
        className = subroutineName
        @outputfile.puts "<identifier category=\"used\" kind=\"class\">#{className}</identifier>" # className
        prefix = className
      else
        varName = subroutineName
        type = @symbols.typeOf(varName)
        kind = @symbols.kindOf(varName)
        index = @symbols.indexOf(varName)
        @outputfile.puts "<identifier category=\"used\" type=\"#{type}\" kind=\"#{kind}\" index=\"#{index}\">#{varName}</identifier>" # varName
        prefix = type
        needsThis = true
      end
      @outputfile.puts "<symbol>.</symbol>"
      subroutineName = @tokenizer.identifier
      @outputfile.puts "<identifier category=\"used\" kind=\"subroutine\">#{subroutineName}</identifier>" # subroutineName
      @tokenizer.advance
    else
      @outputfile.puts "<identifier category=\"used\" kind=\"subroutine\">#{subroutineName}</identifier>" # subroutineName only
      prefix = @className
      needsThis = true
      varName = nil
    end

    @vm.writeComment "Call #{prefix}.#{subroutineName}"
    if needsThis
      if varName == nil
        @vm.writePush "pointer", 0 # this
      else
        pushVar varName
      end
    end
    @outputfile.puts @tokenizer.currentTokenXML # '('
    @tokenizer.advance
    argc = self.compileExpressionList                  # expressionList
    @outputfile.puts @tokenizer.currentTokenXML # ')'

    if needsThis
      @vm.writeCall "#{prefix}.#{subroutineName}", (argc + 1)
    else
      @vm.writeCall "#{prefix}.#{subroutineName}", argc
    end

    @tokenizer.advance
  end

  def pushVar(varName)
    index = @symbols.indexOf(varName)
    case @symbols.kindOf(varName)
    when :STATIC then @vm.writePush "static", index
    when :FIELD then @vm.writePush "this", index
    when :ARG then
      if @isInsideMethod
        @vm.writePush "argument", (index + 1) # 0th is 'this' or null
      else
        @vm.writePush "argument", index
      end
    when :VAR then @vm.writePush "local", index
    end
  end

  def popVar(varName)
    index = @symbols.indexOf(varName)
    case @symbols.kindOf(varName)
    when :STATIC then @vm.writePop "static", index
    when :FIELD then @vm.writePop "this", index
    when :ARG then
      if @isInsideMethod
        @vm.writePop "argument", (index + 1) # 0th is 'this' or null
      else
        @vm.writePop "argument", index
      end
    when :VAR then @vm.writePop "local", index
    end
  end

end
