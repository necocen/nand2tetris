class Parser
  def initialize(program)
    @lines = program.split("\n").map { |line| line.split("//")[0].gsub(/\s/, '') }.select { |line| line.length > 0 }
  end

  def hasMoreCommands
    @lines.count > 0
  end

  def advance
    @current = @lines.shift
  end

  def commandType
    case @current[0]
    when "@" then
      :A_COMMAND
    when "(" then
      :L_COMMAND
    else
      :C_COMMAND
    end
  end

  def symbol
    case @current[0]
    when "@" then
      @current.match(/^@([a-zA-Z0-9_.$:]+)$/)[1]
    when "(" then
      @current.match(/^\(([a-zA-Z0-9_.$:]+)\)$/)[1]
    end
  end

  def dest
    @current.match(/^(([ADM]+)=)?([01ADM!+&|-]+)(;([A-Z]+))?$/)[2] || "null"
  end

  def comp
    @current.match(/^(([ADM]+)=)?([01ADM!+&|-]+)(;([A-Z]+))?$/)[3]
  end

  def jump
    @current.match(/^(([ADM]+)=)?([01ADM!+&|-]+)(;([A-Z]+))?$/)[5] || "null"
  end
end
