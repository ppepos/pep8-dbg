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

redef class String
	fun str_to_bytes: Array[Byte]
	do
		var bytes = new Array[Byte]
		var stripped_value = self.substring(1, self.length - 2)
		var i = 0

		loop
			if i >= stripped_value.length then break

			if stripped_value[i] == '\\' then
				if stripped_value.length > (i + 1) then
					if stripped_value[i+1] == '\\' then
						bytes.add '\\'.bytes[0]
					else if stripped_value[i+1] == 'n' then
						bytes.add '\n'.bytes[0]
					else if stripped_value[i+1] == 'r' then
						bytes.add '\r'.bytes[0]
					else if stripped_value[i+1] == 't' then
						bytes.add '\t'.bytes[0]
					else if stripped_value.length + 3 > (i + 3) and stripped_value[i+1] == 'x' then
						bytes.add "0x{stripped_value[i+2]}{stripped_value[i+3]}".to_i.to_b
						i += 2
					end
					i += 2
				end
			else
				# TODO: Convert to Extended ASCII char
				bytes.add stripped_value[i].bytes[0]
				i += 1
			end
		end

		return bytes
	end
end

class Pep8Model
	var filename: String
	var file: FileReader is noinit
	var lines = new Array[String]
	var instructions = new Array[AbsInstruction]
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
			var match = src_line.trim.search(comment_re)
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
		var matches = new Array[String]

		if instr_str.search("^[a-zA-Z0-9_]+:.*$".to_re) != null then
			matches = instr_str.split_once_on(":")
		else
			matches.add instr_str
		end

		var trimmed_instr_str = instr_str

		if matches.length == 2 then
			self.load_label(instr_str, address)
			trimmed_instr_str = matches[1].trim
		end

		matches = trimmed_instr_str.split_once_on("\\s+".to_re)
		var mnemonic = matches[0]
		var operands = new Array[String]
		var operand = null
		var addr_mode = null

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
			if operands.length > 1 then addr_mode = operands[1]
		end

		var mnemonic_suffix = split_mnemonic_and_suffix(mnemonic)
		var mnemonic_ = mnemonic_suffix[0]
		var suffix = mnemonic_suffix[1]

		var inst_def = get_matching_intruction_def(mnemonic_, suffix)
		assert inst_def != null

		return new Instruction(address, mnemonic_, suffix, addr_mode, operand, inst_def)
	end

	fun split_mnemonic_and_suffix(instr_spec_str: String): Array[String]
	do
		var result = new Array[String]

		if instr_spec_str != "MOVSPA" and instr_spec_str != "MOVFLGA" and
			(instr_spec_str.last.to_s == "X" or instr_spec_str.last.to_s == "A" or instr_spec_str.last.to_s.is_num) then
			result.push instr_spec_str.substring(0, instr_spec_str.length - 1)
			result.push instr_spec_str.last.to_s
		else
			result.push instr_spec_str
			result.push ""
		end

		return result
	end

	fun get_matching_intruction_def(mnemonic, suffix: String): nullable InstructionDef
	do
		for inst_def in self.instruction_set do
			if suffix.is_empty and inst_def.has_suffix then continue
			if inst_def.mnemonic.to_upper == mnemonic.to_upper then return inst_def
		end
		return null
	end

	fun load_label(inst_str: String, address: Int)
	do
		var label_decl_re = "^([a-zA-Z0-9_]+):.*$".to_re

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

	fun assemble: Bytes
	do
		var bytes = new Bytes.empty
		for inst in self.instructions do
			for byte in inst.assemble do
				bytes.add byte
			end
		end
		return bytes
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

	# If the mnemonic ends with a suffix ADDr->ADDA, RETn->RET4
	var has_suffix: Bool

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
	var suffix: nullable String
	var addr_mode: nullable String
	var operand: nullable Operand
	var inst_def: InstructionDef

	init (addr: Int, op_str: String, suffix, addr_mode: nullable String, operand: nullable Operand, inst_def: InstructionDef)
	do
		self.addr = addr
		self.op_str = op_str
		self.suffix = suffix
		self.addr_mode = addr_mode
		self.operand = operand
		self.inst_def = inst_def
	end

	redef fun to_s do
		var suffix = ""
		var suf_ = self.suffix
		if suf_ != null then suffix = suf_

		var operands = new Array[String]

		if self.operand != null and self.addr_mode != null then
			operands.add self.operand.to_s
			operands.add self.addr_mode.to_s
		end

		return [self.op_str + suffix, operands.join(",")].join(" ")
	end

	fun set_operand(operand: Operand) do self.operand = operand
	redef fun len do return inst_def.length
	redef fun has_label do return self.operand != null and self.operand.label_str != null
	redef fun resolve_label(labels: HashMap[String, Int]) do self.operand.value = labels[self.operand.label_str]

	redef fun assemble: Array[Byte]
	do
		var bytes = new Array[Byte]

		bytes.add(((self.inst_def.bitmask << self.inst_def.bitmask_shift) + self.encode_addressing_mode + encode_suffix).to_b)
		if not self.inst_def.addr_modes.is_empty then bytes.add_all self.operand.value.to_two_bytes
		return bytes
	end

	fun encode_suffix: Int do
		if not self.inst_def.has_suffix then return 0

		var bits
		if not self.suffix.is_empty and self.suffix.is_num then
			bits = self.suffix.to_i
		else if self.suffix == "X" then
			bits = 1 << (self.inst_def.bitmask_shift - 1)
		else
			bits = 0
		end

		return bits
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
			return self.value.str_to_bytes.length
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
			return self.value.str_to_bytes
		else if self.op_str == ".BLOCK" then
			return new Array[Byte].filled_with(0.to_b, self.value.to_i)
		else if self.op_str == ".BYTE" then
			var value = new Array[Byte]
			# TODO: Remove value.has when is_int function will be fixed
			if self.value.is_int and not self.value.has("'") then
				value.add self.value.to_i.to_b
			else
				var str = self.value.str_to_bytes
				if str.length == 1 then value.add str[0]
			end
			return value
		else if self.op_str == ".WORD" then
			var value = new Array[Byte]
			# TODO: Remove value.has when is_int function will be fixed
			if self.value.is_int and not self.value.has("'") then
				value = self.value.to_i.to_two_bytes
			else
				var str = self.value.str_to_bytes
				if str.length == 2 then
					value = str
				end
			end
			return value
		else
			return new Array[Byte]
		end
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
		else if operand_str.first == '\'' or operand_str.first == '"' then
			init(operand_str.str_to_bytes[0].to_i, null)
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
