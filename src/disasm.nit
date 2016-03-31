import asm

class Disassembler
	fun disassemble_stream(byte_stream: Bytes, nb_bytes: Int, model: Pep8Model): String
	do
		var out = new Array[String]
		var stream_offset = 0
		while stream_offset < nb_bytes and stream_offset < byte_stream.length do
			var stream = byte_stream.subarray(stream_offset, byte_stream.length - stream_offset)
			var inst = decode_next_instruction(stream, model)

			if inst == null then return out.join("\n")

			out.add inst.to_s

			if inst.operand != null then
				stream_offset += 3
			else
				stream_offset += 1
			end
		end

		return out.join("\n")
	end

	fun decode_next_instruction(byte_stream: Array[Byte], model: Pep8Model): nullable Instruction
	do
		if byte_stream.is_empty then return null

		var inst = decode_opcode(byte_stream[0], model.instruction_set)

		if not inst.inst_def.addr_modes.is_empty then
			if byte_stream.length < 3 then return null
			var value = (byte_stream[1].to_i << 8) + byte_stream[2].to_i
			inst.set_operand new Operand(value)
		end

		return inst
	end

	fun decode_opcode(opcode: Byte, instruction_set: Array[InstructionDef]): nullable Instruction
	do
		var inst_def = null
		var suffix = null
		var addressing_mode = null
		var op_str

		# Find the instruction definition
		for instruction in instruction_set do
			if is_opcode(opcode, instruction.bitmask, instruction.bitmask_shift) then
				inst_def = instruction
			end
		end

		if inst_def == null then return null

		# Find the suffix
		if inst_def.has_suffix then
			suffix = decode_reg(opcode, inst_def.bitmask_shift)
		end

		# Find the addressing mode
		if not inst_def.addr_modes.is_empty then
			addressing_mode = decode_addressing_mode(opcode, inst_def.length_mode)
		end

		return new Instruction(0, inst_def.mnemonic, suffix, addressing_mode, null, inst_def)
	end

	fun is_opcode(opcode: Byte, bitmask, bitmask_shift: Int): Bool
	do
		var real_bitmask = (bitmask << bitmask_shift)
		if opcode.to_i & real_bitmask == real_bitmask then return true
		return false
	end

	fun decode_reg(opcode: Byte, bitmask_shift: Int): String
	do

		var mask = (2 ** bitmask_shift) - 1

		if (bitmask_shift == 2 and opcode.to_i >> bitmask_shift == 9) or # NOPn
		   (bitmask_shift == 3 and opcode.to_i >> bitmask_shift == 11) then # RETn
			return (opcode.to_i & mask).to_s
		else if opcode.to_i >> (bitmask_shift - 1) & 1 == 0 then
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
			mask = 0x7
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
end
