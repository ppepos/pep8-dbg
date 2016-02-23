import json

class Pep8Model
	var filename: String
	var file: FileReader is noinit
	var lines = new Array[String]
	var instructions = new Array[nullable AbsInstruction]
	var labels = new HashMap[String, Int]
	var instruction_set: Array[InstructionDef] is noinit

	fun load_instruction_set(path: String): Bool
	do
		var fd = new FileReader.open(path)
		var instr_json_objects = fd.read_all.parse_json

		self.instruction_set = new Array[InstructionDef]

		if not instr_json_objects isa JsonArray then return false
		for instr_obj in instr_json_objects do
			if not instr_obj isa JsonObject then return false
			var mnemonic_obj = instr_obj.get_or_null("mnemonic")
			if mnemonic_obj == null then return false
			var mnemonic = mnemonic_obj.to_s

			var bitmask = instr_obj.get_or_null("bitmask")

			var bitmask_shift = instr_obj.get_or_null("bitmaskShift")
			var has_reg = instr_obj.get_or_null("hasReg")
			var length = instr_obj.get_or_null("length")
			var addr_modes_json = instr_obj.get_or_null("addrModes")
			var length_mode = instr_obj.get_or_null("lengthMode")

			if bitmask == null or bitmask_shift == null or length == null or has_reg == null or
				length_mode == null or not addr_modes_json isa JsonArray then return false

            var addr_modes = new Array[String]
			for addr_mode in addr_modes_json do
				if addr_mode == null then return false
				var am = addr_mode.to_s
				addr_modes.push am
			end

			# Comparison using "has" because for some reasons "abcd" == "abcd" returns false ...
			self.instruction_set.add(
				new InstructionDef(mnemonic, bitmask.to_s.to_i, bitmask_shift.to_s.to_i, has_reg.to_s.has("true"), length.to_s.to_i, addr_modes, length_mode.to_s.to_i)
			)

		end
		return true
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
		var op_re = "(\\w+\\s?:)?(\\.?\\w+)\\s".to_re
		var op: String

		var operandes = new Array[String]
		var match = instr_str.search(op_re)
		if match != null then
			op = match.to_s
		else
			return null
		end

		return new Instruction(0, "dkghaskdhas")
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
	var mnemonic: String
	var bitmask: Int
	var bitmask_shift: Int
	var has_reg: Bool
	var length: Int
	var addr_modes: Array[String]
	var length_mode: Int
end

abstract class AbsInstruction
end

class Instruction
	super AbsInstruction
	var addr: Int
	var op_str: String
	var operandes_str = new Array[String]
	var operandes = new Array[Operande]
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
