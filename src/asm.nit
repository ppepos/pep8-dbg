import json::serialization

redef class Deserializer
	redef fun deserialize_class(name)
	do
		if name == "Array[InstructionDef]" then return new Array[InstructionDef].from_deserializer(self)
		return super
	end
end

redef class Int
	fun to_two_bytes: Array[Byte] do return [(self >> 8).to_b, (self << 24 >> 24).to_b]
end

class Pep8Model
	var filename: String
	var file: FileReader is noinit
	var lines = new Array[String]
	var instructions = new Array[nullable AbsInstruction]
	var labels = new HashMap[String, Int]
	var instruction_set: Array[InstructionDef] is noinit

	fun load_instruction_set(path: String)
	do
		var fd = new FileReader.open(path)
		var instr_set_json = fd.read_all

		var deserializer = new JsonDeserializer(instr_set_json)
		var instr_set = deserializer.deserialize
		assert instr_set isa Array[InstructionDef]

		instruction_set = instr_set
	end

	fun read_instructions
	do
		file = new FileReader.open(filename)

		var comment_re = "^\\s*([^;]+)".to_re
		var address = 0

		for src_line in file.read_lines do
			var match = src_line.search(comment_re)
			if match != null then
				var instr_match = match[0]
				if instr_match != null then
					var instr_str = instr_match.to_s.trim
					lines.push instr_str

					var instr = parse_instr(instr_str, address)
					instructions.push(instr)
					address += instr.len
				end
			end
		end

		self.resolve_labels

		file.close
	end

	fun parse_instr(instr_str: String, address: Int): AbsInstruction
	do
		var matches = instr_str.split_once_on(":")
		var trimmed_instr_str = instr_str

		if matches.length == 2 then
			self.load_label(instr_str, address)
			trimmed_instr_str = matches[1].trim
		end

		matches = trimmed_instr_str.split_once_on("\\s+".to_re)
		var mnemonic = matches[0]
		var operands = new Array[String]
		var operand = null
		var reg = null

		# For dot operations as .WORD, .BYTE, etc.
		if mnemonic.first.to_s == "." then
			var value = ""
			if matches.length > 1 then value = matches[1]
			if mnemonic.to_upper == ".EQUATE" then load_label(instr_str, value.to_i)
			return new PseudoInstruction(address, mnemonic, value)
		end

		if matches.length > 1 then
			operands = matches[1].split_once_on("\\s*,\\s*".to_re)
			operand = new Operand.from_str(operands[0])
			reg = operands[1]
		end

		var mnemonic_reg = split_mnemonic_and_reg(mnemonic)
		var inst_def = get_matching_intruction_def(mnemonic_reg[0])

		return new Instruction(address, mnemonic_reg[0], mnemonic_reg[1], reg, operand, inst_def)
	end

	fun split_mnemonic_and_reg(instr_spec_str: String): Array[String]
	do
		var result = ["", ""]

		if instr_spec_str != "MOVSPA" and instr_spec_str != "MOVFLGA" and
			(instr_spec_str.last.to_s == "X" or instr_spec_str.last.to_s == "A") then
			result[1] = instr_spec_str.last.to_s
			result[0] = instr_spec_str.substring(0, instr_spec_str.length - 1)
		else
			result[0] = instr_spec_str
		end

		return result
	end

	fun get_matching_intruction_def(mnemonic: String): nullable InstructionDef
	do
		for inst_def in self.instruction_set do
			if inst_def.mnemonic == mnemonic then return inst_def
		end
		return null
	end

	fun load_label(inst_str: String, address: Int)
	do
		var label_decl_re = "^\\s*([^;:\\s]+)\\s*:.*$".to_re

		var match = inst_str.search(label_decl_re)
		if match != null then
			var tag_match = match.subs[0]
			if tag_match != null then
				var tag = tag_match.to_s
				self.labels[tag] = address
			end
		end
	end

	fun resolve_labels
	do
		for inst in self.instructions do
			if inst.has_label then inst.resolve_label(self.labels)
		end
	end

	fun debug_str: String
	do
		var out = new Array[String]
		for inst in self.instructions do out.add "{inst.to_s} {inst.assemble.to_s}"
		return out.join("\n")
	end

end

class InstructionDef
	serialize

	# Mnemonic representation of instruction ex: "ADDr"
	var mnemonic: String

	# Unique bitmask for instruction
	var bitmask: Int

	# Number of bits to shift when identifying instr with bitmask
	var bitmask_shift: Int

	# If the mnemonic ends with a register ADDr -> ADDA or ADDX
	var has_reg: Bool

	# Length in bytes of the instruction.
	var length: Int

	# Allowed addressing modes
	var addr_modes = new Array[String]

	var length_mode: Int

	redef fun to_s do return mnemonic
end

abstract class AbsInstruction
	var addr: Int
	var op_str: String
	fun len: Int is abstract
	fun has_label: Bool is abstract
	fun resolve_label(labels: HashMap[String, Int]) is abstract
	fun assemble: Array[Byte] is abstract

	init (addr: Int, op_str: String)
	do
		self.addr = addr
		self.op_str = op_str
	end
end

class Instruction
	super AbsInstruction
	var register: nullable String
	var addr_mode: nullable String
	var operand: nullable Operand
	var inst_def: nullable InstructionDef

	init (addr: Int, op_str: String, register, addr_mode: nullable String, operand: nullable Operand, inst_def: nullable InstructionDef)
	do
		self.addr = addr
		self.op_str = op_str
		self.register = register
		self.addr_mode = addr_mode
		self.operand = operand
		self.inst_def = inst_def
	end

	redef fun to_s do
		var reg = ""
		if self.register != null then reg = register.to_s

		var operands = new Array[String]

		if self.operand != null and self.addr_mode != null then
			operands.add self.operand.to_s
			operands.add self.addr_mode.to_s
		end

		return [self.op_str + reg, operands.join(",")].join(" ")
	end

	fun set_operand(operand: Operand) do self.operand = operand

	redef fun len do return inst_def.length
	redef fun has_label do return self.operand != null and self.operand.label_str != null
	redef fun resolve_label(labels: HashMap[String, Int]) do self.operand.value = labels[self.operand.label_str]
	redef fun assemble: Array[Byte]
	do
		var bytes = new Array[Byte]
		bytes.add(((self.inst_def.bitmask << self.inst_def.bitmask_shift) + self.encode_addressing_mode + encode_reg).to_b)
		if not self.inst_def.addr_modes.is_empty then bytes.add_all self.operand.value.to_two_bytes
		return bytes
	end

	fun encode_reg: Int do
		if not self.inst_def.has_reg then return 0

		var bit
		if self.register == "X" then
			bit = 1
		else
			bit = 0
		end

		return bit << (self.inst_def.bitmask_shift - 1)
	end

	fun encode_addressing_mode: Int
	do
		if self.inst_def.addr_modes.is_empty then return 0

		if self.addr_mode == "i" then
			return 0
		else if self.addr_mode == "d" then
			return 1
		else if self.addr_mode == "n" then
			return 2
		else if self.addr_mode == "s" then
			return 3
		else if self.addr_mode == "sf" then
			return 4
		else if self.addr_mode == "x" then
			return 5
		else if self.addr_mode == "sx" then
			return 6
		else if self.addr_mode == "sxf" then
			return 7
		end
		return 0
	end
end

class PseudoInstruction
	super AbsInstruction
	var value: String
	var label_dst = 0

	init (addr: Int, op_str: String, value: String)
	do
		self.addr = addr
		self.op_str = op_str.to_upper
		self.value = value
	end

	redef fun len do
		if self.op_str == ".ADDRSS" then
			return 2
		else if self.op_str == ".ASCII" then
			return str_to_bytes.length
		else if self.op_str == ".BLOCK" then
			return value.to_i
		else if self.op_str == ".BYTE" then
			return 1
		else if self.op_str == ".WORD" then
			return 2
		else
			return 0
		end
	end

	redef fun assemble: Array[Byte]
	do
		if self.op_str == ".ADDRSS" then
			return self.label_dst.to_i.to_two_bytes
		else if self.op_str == ".ASCII" then
			return str_to_bytes
		else if self.op_str == ".BLOCK" then
			return new Array[Byte].filled_with(0.to_b, self.value.to_i)
		else if self.op_str == ".BYTE" then
			return [self.value.to_i.to_b]
		else if self.op_str == ".WORD" then
			return self.value.to_i.to_two_bytes
		else
			return new Array[Byte]
		end
	end

	fun str_to_bytes: Array[Byte]
	do
		var bytes = new Array[Byte]
		var stripped_value = self.value.substring(1, self.value.length - 2)
		var i = 0

		loop
			if i >= stripped_value.length then break

			if stripped_value[i] == '\\' then
				if stripped_value.length > (i + 1) and stripped_value[i+1] == '\\' then
					bytes.add '\\'.bytes[0]
					i += 2
				else if stripped_value.length + 3 > (i + 3) and stripped_value[i+1] == 'x' then
					bytes.add "0x{stripped_value[i+2]}{stripped_value[i+3]}".to_i.to_b
					i += 4
				end
			else
				bytes.add stripped_value[i].bytes[0]
				i += 1
			end
		end

		return bytes
	end

	redef fun to_s do return [self.op_str, self.value].join(" ")
	redef fun has_label do return self.op_str == ".ADDRSS"
	redef fun resolve_label(labels: HashMap[String, Int]) do self.label_dst = labels[self.value]
end

class Declaration
end

class Operand
	var value: nullable Int
	var label_str: nullable String

	init from_str(operand_str: String)
	do
		if operand_str.first.is_letter then
			init(null, operand_str)
		else
			init(operand_str.to_i, null)
		end
	end

	redef fun to_s do
		if label_str != null then
			return label_str.to_s
		else
			return value.to_s
		end
	end
end

class SourceLine
	var line_number: Int
	var instr_str: String
end

var fname = "01-exemple.pep"
var model = new Pep8Model(fname)

model.load_instruction_set("pep8.json")
model.read_instructions
print model.debug_str
