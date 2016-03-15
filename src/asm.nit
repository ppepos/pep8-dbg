import json::serialization

redef class Deserializer
	redef fun deserialize_class(name)
	do
		if name == "Array[InstructionDef]" then return new Array[InstructionDef].from_deserializer(self)
		return super
	end
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

	fun parse_instr(instr_str: String, address: Int): nullable AbsInstruction
	do
		var matches = instr_str.split_once_on(":")

		if matches.length == 2 then
			# print "manage_label"
			self.load_label(instr_str, address)
			instr_str = matches[1].trim
		end

		matches = instr_str.split_once_on("\\s+".to_re)
		var mnemonic = matches[0]
		var operands = new Array[String]
		var operand = null
		var reg = null

		# TODO: Implement DataInstruction
		# Data definition : ex. .WORD, .BLOC, .END, etc.
		if mnemonic.first.to_s == "." then return new DataInstruction(address)

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
			if inst isa Instruction and inst.operand != null and inst.operand.label_str != null then
				inst.operand.value = self.labels[inst.operand.label_str]
			end
		end
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
	fun len: Int is abstract
end

class Instruction
	super AbsInstruction
	var op_str: String
	var register: nullable String
	var addr_mode: nullable String
	var operand: nullable Operand
	var inst_def: nullable InstructionDef

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
end

class DataInstruction
	super AbsInstruction
	# TODO: Compute length
	redef fun len do return 0
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
