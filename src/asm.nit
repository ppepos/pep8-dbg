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

		for src_line in file.read_lines do
			var match = src_line.search(comment_re)
			if match != null then
				var instr_match = match[0]
				if instr_match != null then
					var instr_str = instr_match.to_s.trim
					lines.push instr_str

					var instr = parse_instr(instr_str)
					instructions.push(instr)
				end
			end
		end

		file.close
	end

	fun parse_instr(instr_str: String): nullable AbsInstruction
	do

		var matches = instr_str.split_once_on(":")

		if matches.length == 2 then
			# print "manage_label"
			instr_str = matches[1].trim
		end

		matches = instr_str.split_once_on("\\s+".to_re)
		var mnemonic = matches[0]
		var operandes = new Array[String]

		if matches.length > 1 then
			operandes = matches[1].split_once_on("\\s*,\\s*".to_re)
		end

		print "{mnemonic}\t{operandes}"

			

		return new Instruction(0, "ADDr")
	end

	fun load_labels
	do
		var label_decl_re = "^\\s*([^;:\\s]+)\\s*:.*$".to_re
		var current_addr = 0

		for line in lines do
			var match = line.search(label_decl_re)
			if match != null then
				var tag_match = match.subs[0]
				if tag_match != null then
					var tag = tag_match.to_s
					self.labels[tag] = current_addr
				end
			end

			var instr_size = get_instr_size(line)
			current_addr += instr_size

		end
	end

	fun get_instr_size(instr_str: String): Int
	do
		return 0
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
	var addr_modes: Array[String]

	var length_mode: Int

	redef fun to_s do return mnemonic
end

abstract class AbsInstruction
end

class Instruction
	super AbsInstruction
	var addr: Int
	var op_str: String
	var operandes_str = new Array[String]
	var operandes = new Array[Operande]

	redef fun to_s do return [self.op_str, operandes_str.join(",")].join(" ")
end

class Declaration
end

class Operande
end

class SourceLine
	var line_number: Int
	var instr_str: String
end

var fname = "01-exemple.pep"
var model = new Pep8Model(fname)

model.load_instruction_set("pep8.json")
model.read_instructions
model.load_labels
