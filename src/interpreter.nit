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

			else if instr.op_str == "LD" then
				print "{instr} executing"
				exec_ld(instr)

			else
				print "{instr} not yet implemented"
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

	fun exec_ld(instr: Instruction) do
		var value = 0
		var addr: Int

		if instr.addr_mode == "i" then
			var op = instr.operand
			assert op != null

			var op_val = op.value
			assert op_val != null

			value = op_val
		else
			addr = resolve_addr(instr)
			var word = memory.sub(addr, 2)
			value = word[0].to_i
			value = value << 8
			value += word[1].to_i
		end

		if instr.suffix == "A" then
			reg_file.a.value = value
		else if instr.suffix == "X" then
			reg_file.x.value = value
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

	# Negative
	var n = new RegisterBit

	# Zero
	var z = new RegisterBit

	# Overflow
	var v = new RegisterBit

	# Carry
	var c = new RegisterBit
end

class Register
	var value: Int = 0
end

class RegisterBit
	var value = 0
end

var model = new Pep8Model("tests/test01.pep")
model.load_instruction_set("src/pep8.json")
model.read_instructions

var reg_file = new Pep8RegisterFile
var interpreter = new Interpreter(model, reg_file)

interpreter.execute
