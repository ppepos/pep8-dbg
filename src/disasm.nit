
class InstructionDef
	var instr: String
	var addr_mode: Array[String]
	var op_size: Int
	var mask: Byte
	var mask_size: Int
end

var instr_map = new HashMap[String, InstructionDef]

instr_map["STOP"] = new InstructionDef("STOP", new Array[String], 1, 0x00u8, 8)
instr_map["LDr"] = new InstructionDef("LDr", ["i", "x"], 3, 0xC0u8, 4)
