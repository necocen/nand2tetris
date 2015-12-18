module Code
  extend self
  
  def dest(mnemonic)
    (mnemonic.include?("A") ? "1" : "0") +
    (mnemonic.include?("D") ? "1" : "0") +
    (mnemonic.include?("M") ? "1" : "0")
  end

  def jump(mnemonic)
    case mnemonic
    when "JGT" then "001"
    when "JEQ" then "010"
    when "JGE" then "011"
    when "JLT" then "100"
    when "JNE" then "101"
    when "JLE" then "110"
    when "JMP" then "111"
    else "000"
    end
  end

  def comp(mnemonic)
    case mnemonic
    when "0"   then "0101010"
    when "1"   then "0111111"
    when "-1"  then "0111010"
    when "D"   then "0001100"
    when "A"   then "0110000"
    when "M"   then "1110000"
    when "!D"  then "0001101"
    when "!A"  then "0110001"
    when "!M"  then "1110001"
    when "-D"  then "0001111"
    when "-A"  then "0110011"
    when "-M"  then "1110011"
    when "D+1" then "0011111"
    when "A+1" then "0110111"
    when "M+1" then "1110111"
    when "D-1" then "0001110"
    when "A-1" then "0110010"
    when "M-1" then "1110010"
    when "D+A" then "0000010"
    when "D+M" then "1000010"
    when "D-A" then "0010011"
    when "D-M" then "1010011"
    when "A-D" then "0000111"
    when "M-D" then "1000111"
    when "D&A" then "0000000"
    when "D&M" then "1000000"
    when "D|A" then "0010101"
    when "D|M" then "1010101"
    end
  end
end
