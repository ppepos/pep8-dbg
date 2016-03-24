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
			var instr = dis.disassemble_next_instruction(next_bytes, model)

			# If could not disassemble an instruction, stop
			if instr == null then return

			# Increment program counter
			update_pc(instr)

			if instr.op_str == "STOP" then
				print instr
				return

			else if instr.op_str == "ADD" then
				print "{instr} - executing"
				exec_ld(instr)
			else if instr.op_str == "CP" then
				print "{instr} - executing"
				exec_cp(instr)
			else if instr.op_str == "LD" then
				print "{instr} - executing"
				exec_ld(instr)

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
	end

	fun update_pc(last_instr: Instruction) do reg_file.pc.value += last_instr.len

	fun get_imm_value(instr: Instruction): Int do

		var op = instr.operand
		assert op != null

		var op_val = op.value
		assert op_val != null

		return op_val
	end

	fun get_memory_value(addr: Int): Int do

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
		else
			print "addressing mode not yet implemented"
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
			value = get_memory_value(addr)
		end

		return value
	end

	fun reg_add(x, y: Int): Int do
		var result = (x + y) & 0xffff

		var overflow = (x < 32768 and y < 32768 and result >= 32768) or (x >= 32678 and y >= 32768 and result < 32768)
		if overflow then reg_file.v.value = 1 else reg_file.v.value = 0

		var carry = ((x & 0xffff) + (y & 0xffff)) >> 16
		if carry == 1 then reg_file.c.value =  1 else reg_file.c.value = 0

		# set z and n
		reg_file.update_state_regs(result)

		return result
	end

	fun reg_sub(x, y: Int): Int do return reg_add(x, -y)

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

	fun exec_ld(instr: Instruction) do
		var value = 0

		value = resolve_opernd_value(instr)

		if instr.suffix == "A" then
			reg_file.a.value = value
		else if instr.suffix == "X" then
			reg_file.x.value = value
		end

		reg_file.update_state_regs(value)
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
		var v = value % 65536

		# zero flag
		if value == 0 then z.value = 1 else z.value = 0

		# negative flag
		if v < 0 or v > 32767 then n.value = 1 else n.value = 0
	end
end

class Register
	var value: Int = 0
end

class RegisterBit
	var value = 0
end

# var model = new Pep8Model("tests/test01.pep")
var model = new Pep8Model("src/01-exemple.pep")
model.load_instruction_set("src/pep8.json")
model.read_instructions

var reg_file = new Pep8RegisterFile
var interpreter = new Interpreter(model, reg_file)

interpreter.execute
