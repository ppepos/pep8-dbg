import asm
import disasm

class Interpreter
	# Parsed model
	var model: Pep8Model

	# Virtual Memory
	var memory: Array[Byte] = [for x in 65535.times do 0.to_b]

	# Registers
	var reg_file: Pep8RegisterFile

	fun execute do

		init_memory

		var dis = new Disassembler

		loop
			var next_bytes = memory.sub(reg_file.pc.value, reg_file.pc.value + 3)
			var instr = dis.decode_next_instruction(next_bytes, model)

			# If could not disassemble an instruction, stop
			if instr == null then return

			# Increment program counter
			update_pc(instr)

			if instr.op_str == "STOP" then
				# print "{instr} - executing"
				return

			else if instr.op_str == "MOVSPA" then
				# print "{instr} - executing"
				exec_movspa(instr)
			else if instr.op_str == "BR" then
				# print "{instr} - executing"
				exec_br(instr)
			else if instr.op_str == "BREQ" then
				# print "{instr} - executing"
				exec_breq(instr)
			else if instr.op_str == "BRGE" then
				# print "{instr} - executing"
				exec_brge(instr)
			else if instr.op_str == "CALL" then
				# print "{instr} - executing"
				exec_call(instr)
			else if instr.op_str == "DECI" then
				# print "{instr} - executing"
				exec_deci(instr)
			else if instr.op_str == "DECO" then
				# print "{instr} - executing"
				exec_deco(instr)
			else if instr.op_str == "STRO" then
				# print "{instr} - executing"
				exec_stro(instr)
			else if instr.op_str == "CHARI" then
				# print "{instr} - executing"
				exec_chari(instr)
			else if instr.op_str == "CHARO" then
				# print "{instr} - executing"
				exec_charo(instr)
			else if instr.op_str.substring(0, 3) == "RET" then
				# print "{instr} - executing"
				exec_retn(instr)
			else if instr.op_str == "SUBSP" then
				# print "{instr} - executing"
				exec_subsp(instr)
			else if instr.op_str == "ADD" then
				# print "{instr} - executing"
				exec_add(instr)
			else if instr.op_str == "CP" then
				# print "{instr} - executing"
				exec_cp(instr)
			else if instr.op_str == "LD" then
				# print "{instr} - executing"
				exec_ld(instr)
			else if instr.op_str == "ST" then
				# print "{instr} - executing"
				exec_st(instr)

			# Tough luck
			else
				print "{instr} - not yet implemented"
			end

		end
	end

	# Assemble code and place it at the start of virtual memory
	fun init_memory do
		var program_mem = model.assemble
		for b in program_mem.length.times do
			memory[b] = program_mem[b]
		end

		reg_file.sp.value = 2 ** 15 - 1 #32767
	end

	fun update_pc(last_instr: Instruction) do reg_file.pc.value += last_instr.len

	fun get_imm_value(instr: Instruction): Int do

		var op = instr.operand
		assert op != null

		var op_val = op.value
		assert op_val != null

		return op_val
	end

	fun read_word(addr: Int): Int do

		var value: Int

		var word = memory.sub(addr, 2)
		value = word[0].to_i
		value = value << 8
		value += word[1].to_i

		return value
	end

	fun resolve_addr(instr: Instruction): Int do
		var op = instr.operand
		assert op != null

		var op_val = op.value
		assert op_val != null

		var value = op_val
		var addr = 0

		if instr.addr_mode == "d" then
			addr = value
		else if instr.addr_mode == "n" then
			addr = read_word(value)
		else if instr.addr_mode == "s" then
			addr = (reg_file.sp.value + value) & 0xffff
		else if instr.addr_mode == "sf" then
			addr = read_word((reg_file.sp.value + value) & 0xffff)
		else if instr.addr_mode == "x" then
			addr = (reg_file.x.value + value) & 0xffff
		else if instr.addr_mode == "sx" then
			addr = (reg_file.sp.value + value + reg_file.x.value) & 0xffff
		else if instr.addr_mode == "sxf" then
			addr = read_word((reg_file.sp.value + value + reg_file.x.value) & 0xffff)
		else
			print "addressing mode not recognized"
		end

		return addr
	end

	fun resolve_opernd_value(instr: Instruction): Int do
		var value: Int
		var addr: Int

		if instr.addr_mode == "i" then
			value = get_imm_value(instr)
		else
			addr = resolve_addr(instr)
			value = read_word(addr)
		end

		return value
	end

	fun reg_add(x, y: Int): Int do
		var result = (x & 0xffff) + (y & 0xffff)

		if result >= 65536 then
			reg_file.c.value = 1
			result = result & 0xffff
		else
			reg_file.c.value = 0
		end

		var overflow = (x < 32768 and y < 32768 and result >= 32768) or (x >= 32768 and y >= 32768 and result < 32768)
		if overflow then reg_file.v.value = 1 else reg_file.v.value = 0

		# set z and n
		reg_file.update_state_regs(result)

		return result
	end

	fun reg_sub(x, y: Int): Int do return reg_add(x & 0xffff, ((~y) + 1) & 0xffff)

	fun write_word(addr, value: Int) do
		memory[addr + 1] = (value & 0xff).to_b
		memory[addr] = ((value >> 8) & 0xff).to_b
	end

	fun exec_movspa(instr: Instruction) do
		reg_file.a.value = reg_file.sp.value
	end

	fun exec_br(instr: Instruction) do
		var addr = resolve_opernd_value(instr)
		reg_file.pc.value = addr
	end

	fun exec_breq(instr: Instruction) do
		var addr = resolve_opernd_value(instr)

		# If Zero flag, set PC to addr
		if reg_file.z.value == 1 then reg_file.pc.value = addr
	end

	fun exec_brge(instr: Instruction) do
		var addr = resolve_opernd_value(instr)

		# If Neg flag unset, set PC to addr
		if reg_file.n.value == 0 then reg_file.pc.value = addr
	end

	fun exec_call(instr: Instruction) do
		var op_val = resolve_opernd_value(instr)

		reg_file.sp.value -= 2
		write_word(reg_file.sp.value, reg_file.pc.value)
		reg_file.pc.value = op_val & 0xffff
	end

	fun exec_deci(instr: Instruction) do
		var addr = resolve_opernd_value(instr)

		var str = ""
		var char: nullable Char
		var sign_symbol = false

		loop
			char = stdin.read_char
			if char == null then break
			if char == '+' or char == '-' then

				if sign_symbol == true then break
				str += char.to_s
				sign_symbol = true
			else if char >= '0' and char <= '9' then
				str += char.to_s
			else
				break
			end
		end

		var dec = str.to_i

		write_word(addr, dec)
	end

	fun exec_chari(instr: Instruction) do
		var addr = resolve_opernd_value(instr)

		var char = stdin.read_byte
		if char == null then char = 0.to_b
		var chari = char.to_i

		memory[addr] = (chari & 0xff).to_b
	end

	fun exec_charo(instr: Instruction) do
		var op_val = resolve_opernd_value(instr)
		printn op_val.code_point
	end

	fun exec_retn(instr: Instruction) do
		var n = instr.op_str[instr.op_str.length - 1].to_i
		var sp = reg_file.sp
		var pc = reg_file.pc

		sp.value = (sp.value + n) & 0xffff
		pc.value = read_word(sp.value)
		sp.value = (sp.value + 2) & 0xffff
	end

	fun exec_subsp(instr: Instruction) do
		var op_val = resolve_opernd_value(instr)
		reg_file.sp.value = reg_sub(reg_file.sp.value, op_val)
	end

	fun exec_add(instr: Instruction) do
		var op_val = resolve_opernd_value(instr)
		var reg: Register

		if instr.suffix == "A" then
			reg = reg_file.a
		else
			reg = reg_file.x
		end

		var result = reg_add(reg.value, op_val)
		reg.value = result

	end

	fun exec_cp(instr: Instruction) do

		var cmp_value: Int
		var cmp_reg = instr.suffix

		cmp_value = resolve_opernd_value(instr)

		if cmp_reg == "A" then
			reg_sub(reg_file.a.value, cmp_value)
		else if cmp_reg == "X" then
			reg_sub(reg_file.x.value, cmp_value)
		end

		# print "nzvc: {reg_file.n.value} {reg_file.z.value} {reg_file.v.value} {reg_file.c.value}"
	end

	fun exec_ld(instr: Instruction) do

		var value = resolve_opernd_value(instr)

		if instr.suffix == "A" then
			reg_file.a.value = value
		else if instr.suffix == "X" then
			reg_file.x.value = value
		end

		reg_file.update_state_regs(value)
	end

	fun exec_st(instr: Instruction) do
		# Store suffix in operand value address
		var addr = resolve_addr(instr)

		var reg: Register
		if instr.suffix == "A" then reg = reg_file.a else reg = reg_file.x

		memory[addr + 1] = (reg.value & 0xff).to_b
		memory[addr] = ((reg.value >> 8) & 0xff).to_b
	end

	fun exec_deco(instr: Instruction) do
		printn resolve_opernd_value(instr)
	end

	fun exec_stro(instr: Instruction) do
		var ptr = resolve_addr(instr)

		while memory[ptr] != 0.to_b do
			printn memory[ptr].ascii
			ptr += 1
		end
	end
end

class Pep8RegisterFile

	# Accumulator
	var a = new Register

	# Index Register
	var x = new Register

	# Stack Pointer
	var sp = new Register

	# Program Counter
	var pc = new Register

	# State registers

	# Negative
	var n = new RegisterBit

	# Zero
	var z = new RegisterBit

	# Overflow
	var v = new RegisterBit

	# Carry
	var c = new RegisterBit

	fun update_state_regs(value: Int) do

		# zero flag
		z.value = if value == 0 then 1 else 0

		# negative flag
		n.value = if value >= 32767 then 1 else 0
	end

	redef fun to_s do return "A: {a.value }\nX : {x.value }\nSP : {sp.value }\nPC : {pc.value }\nN : {n.value }\nZ : {z.value }\nV : {v.value }\nC : {c.value}"

end

class Register
	var value: Int = 0
end

class RegisterBit
	var value = 0
end

var model = new Pep8Model("tests/test02.pep")
# var model = new Pep8Model("src/01-exemple.pep")
model.load_instruction_set("src/pep8.json")
model.read_instructions

var reg_file = new Pep8RegisterFile
var interpreter = new Interpreter(model, reg_file)

interpreter.execute
