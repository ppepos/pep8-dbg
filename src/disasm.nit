import asm

fun disassemble_stream(byte_stream: Array[Byte], nb_instructions: Int, model: Pep8Model): String
do
	var out = new Array[String]
	var nb_inst = 0
	var stream_offset = 0
	while nb_inst < nb_instructions do
		var stream = byte_stream.subarray(stream_offset, byte_stream.length - stream_offset)
		var inst = disassemble_next_instruction(stream, model, "")

		if inst == null then return "Disassembly error"

		out.add inst.to_s

		if not inst.operandes_str.is_empty then
			stream_offset += 3
		else
			stream_offset += 1
		end
		nb_inst += 1
	end

	return out.join("\n")
end

fun disassemble_next_instruction(byte_stream: Array[Byte], model: Pep8Model, operande_representation: String): nullable Instruction
do
	var inst = disassemble_opcode(byte_stream[0], model.instruction_set)

	if not inst.operandes_str.is_empty then
		var value = (byte_stream[1].to_i << 8) + byte_stream[2].to_i

		if operande_representation == "hex" then
			inst.operandes_str[0] = value.to_hex
		else if operande_representation == "bin" then
			inst.operandes_str[0] = value.to_base(2, false)
		else
			inst.operandes_str[0] = value.to_s
		end
	end

	return inst
end

fun disassemble_opcode(opcode: Byte, instruction_set: Array[InstructionDef]): nullable Instruction
do
	var inst_def = null
	var register = null
	var addressing_mode = null
	var op_str

	# Find the instruction definition
	for instruction in instruction_set do
		if is_opcode(opcode, instruction.bitmask, instruction.bitmask_shift) then
			inst_def = instruction
		end
	end

	if inst_def == null then return null

	# Find the register
	if inst_def.has_reg then
		register = decode_reg(opcode, inst_def.bitmask_shift)
	end

	# Find the addressing mode
	if not inst_def.addr_modes.is_empty then
		addressing_mode = decode_addressing_mode(opcode, inst_def.length_mode)

	end

	# Find the first operand
	if inst_def.has_reg then
		op_str = inst_def.mnemonic.replace('r', register.to_s)
	else
		op_str = inst_def.mnemonic
	end

	var inst = new Instruction(0, op_str)

	if not inst_def.addr_modes.is_empty then
		# Stub to put the first operand later
		inst.operandes_str.add ""
		inst.operandes_str.add addressing_mode.to_s
	end

	return inst
end

fun is_opcode(opcode: Byte, bitmask, bitmask_shift: Int): Bool
do
	var real_bitmask = (bitmask << bitmask_shift)
	if opcode.to_i & real_bitmask == real_bitmask then return true
	return false
end

fun decode_reg(opcode: Byte, bitmask_shift: Int): String
do
	if opcode.to_i & (1 << (bitmask_shift - 1)) == 0 then
		return "A"
	else
		return "X"
	end
end


fun decode_addressing_mode(opcode: Byte, length_mode: Int): String
do
	var mask
	if length_mode == 1 then
		mask = 0x1
	else
		mask = 0x3
	end

	if opcode.to_i & mask == 0 then
		return "i"
	else if opcode.to_i & mask == 1 then
		return "d"
	else if opcode.to_i & mask == 2 then
		return "n"
	else if opcode.to_i & mask == 3 then
		return "s"
	else if opcode.to_i & mask == 4 then
		return "sf"
	else if opcode.to_i & mask == 5 then
		return "x"
	else if opcode.to_i & mask == 6 then
		return "sx"
	else if opcode.to_i & mask == 7 then
		return "sxf"
	else
		return ""
	end
end

var fname = "01-exemple.pep"
var model = new Pep8Model(fname)

model.load_instruction_set("pep8.json")
model.read_instructions
model.load_labels

var input = new Array[Byte]

input.add 0xC1.to_b
input.add 0x00.to_b
input.add 0x0A.to_b
input.add 0x71.to_b
input.add 0x00.to_b
input.add 0x0C.to_b
input.add 0xE1.to_b
input.add 0x00.to_b
input.add 0x0E.to_b
input.add 0x00.to_b

print disassemble_stream(input, 4, model)
