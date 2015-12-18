class SymbolTable

  def initialize
    @classTable = {}      # table of variables inside class definition
    @subroutineTable = {} # table of variables inside subroutine definition
    @varCount = {:STATIC => 0, :FIELD => 0, :ARG => 0, :VAR => 0}
  end

  def startSubroutine
    @subroutineTable = {}
    @varCount[:ARG] = 0
    @varCount[:VAR] = 0
  end

  def define(name, type, kind)
    case kind
    when :STATIC then
      @classTable[name] = {:type => type, :kind => kind, :index => @varCount[kind]}
    when :FIELD then
      @classTable[name] = {:type => type, :kind => kind, :index => @varCount[kind]}
    when :ARG then
      @subroutineTable[name] = {:type => type, :kind => kind, :index => @varCount[kind]}
    when :VAR then
      @subroutineTable[name] = {:type => type, :kind => kind, :index => @varCount[kind]}
    end
    @varCount[kind] += 1
  end

  def varCount(kind)
    return @varCount[kind]
  end

  def kindOf(name)
    (@classTable[name] || @subroutineTable[name] || {:kind => :NONE})[:kind]
  end

  def typeOf(name)
    (@classTable[name] || @subroutineTable[name])[:type]
  end

  def indexOf(name)
    (@classTable[name] || @subroutineTable[name])[:index]
  end
end
