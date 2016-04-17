import asm
import disasm

class Interpreter
	# Parsed model
	var model: Pep8Model

	# Virtual Memory
	var memory: Array[Byte] = [for x in 65535.times do 0.to_b]

	# Registers
	var reg_file: Pep8RegisterFile

	var instr_decoder: Disassembler

	init(model: Pep8Model, reg_file: Pep8RegisterFile) do
		self.model = model
		self.reg_file = reg_file
		self.instr_decoder = new Disassembler(model)
		self.load_image
	end

	fun start do
		load_image
		self.reg_file.reset
		execute
	end

	# Returns:
	# 0 : Execution sucessfully terminated
	# -1 : Execution error
	fun execute: Int do

		loop
			var exec_result = execute_instr

			if exec_result != 1 then return exec_result
		end
	end

	# Returns :
	# 0 : STOP instruction
	# 1 : Successfull instruction execution (not STOP)
	# -1 : Error
	fun execute_instr: Int do
		var next_bytes = memory.sub(reg_file.pc.value, reg_file.pc.value + 3)
		var instr = self.instr_decoder.decode_next_instruction(next_bytes)

		# If could not disassemble an instruction, stop
		if instr == null then return -1

		if instr.op_str == "STOP" then
			return 0
		else if instr.op_str == "MOVSPA" then
			exec_movspa(instr)
		else if instr.op_str == "BR" then
			exec_br(instr)
		else if instr.op_str == "BREQ" then
			exec_breq(instr)
		else if instr.op_str == "BRNE" then
			exec_brne(instr)
		else if instr.op_str == "BRGE" then
			exec_brge(instr)
		else if instr.op_str == "CALL" then
			exec_call(instr)
		else if instr.op_str == "DECI" then
			exec_deci(instr)
		else if instr.op_str == "DECO" then
			exec_deco(instr)
		else if instr.op_str == "STRO" then
			exec_stro(instr)
		else if instr.op_str == "CHARI" then
			exec_chari(instr)
		else if instr.op_str == "CHARO" then
			exec_charo(instr)
		else if instr.op_str.substring(0, 3) == "RET" then
			exec_retn(instr)
		else if instr.op_str == "SUBSP" then
			exec_subsp(instr)
		else if instr.op_str == "ADD" then
			exec_add(instr)
		else if instr.op_str == "SUB" then
			exec_sub(instr)
		else if instr.op_str == "AND" then
			exec_and(instr)
		else if instr.op_str == "CP" then
			exec_cp(instr)
		else if instr.op_str == "LD" then
			exec_ld(instr)
		else if instr.op_str == "ST" then
			exec_st(instr)

		# Tough luck
		else
			print "{instr} - not yet implemented"
		end

		# Increment program counter
		update_pc(instr)

		return 1
	end

	# Assemble code and place it at the start of virtual memory
	private fun load_image do
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

	fun write_byte(addr, value: Int) do
		memory[addr] = (value & 0xff).to_b
	end

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

	fun exec_brne(instr: Instruction) do
		var addr = resolve_opernd_value(instr)

		# In not zero, set PC to addr
		if reg_file.z.value != 1 then reg_file.pc.value = addr
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
		var addr = resolve_addr(instr)

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
		var addr = resolve_addr(instr)

		var char = stdin.read_byte
		if char == null then char = 0.to_b
		var chari = char.to_i

		write_byte(addr, chari)
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

	fun exec_sub(instr: Instruction) do
		var op_val = resolve_opernd_value(instr)
		var reg: Register

		if instr.suffix == "A" then
			reg = reg_file.a
		else
			reg = reg_file.x
		end

		var result = reg_sub(reg.value, op_val)
		reg.value = result
	end

	fun exec_and(instr: Instruction) do
		var op_val = resolve_opernd_value(instr)
		var reg: Register

		if instr.suffix == "A" then
			reg = reg_file.a
		else
			reg = reg_file.x
		end

		op_val = op_val & 0xFFFF
		var result = op_val & reg.value
		reg_file.n.value = if result > 32768 then 1 else 0
		reg_file.z.value = if result == 0 then 1 else 0
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

		write_word(addr, reg.value)
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

	fun copy: Pep8RegisterFile do

		var reg_file = new Pep8RegisterFile

		reg_file.a.value = self.a.value
		reg_file.x.value = self.x.value
		reg_file.sp.value = self.sp.value
		reg_file.pc.value = self.pc.value
		reg_file.n.value = self.n.value
		reg_file.z.value = self.z.value
		reg_file.v.value = self.v.value
		reg_file.c.value = self.c.value

		return reg_file
	end

	fun update_state_regs(value: Int) do

		# zero flag
		z.value = if value == 0 then 1 else 0

		# negative flag
		n.value = if value >= 32767 then 1 else 0
	end

	fun reset do
		a = new Register
		x = new Register
		sp = new Register
		sp.value = 2 ** 15 - 1 #32767
		pc = new Register
		n = new RegisterBit
		z = new RegisterBit
		v = new RegisterBit
		c = new RegisterBit
	end

	redef fun to_s do return "A: {a.value }\nX : {x.value }\nSP : {sp.value }\nPC : {pc.value }\nN : {n.value }\nZ : {z.value }\nV : {v.value }\nC : {c.value}"

end


class InstructionDiff
	# var saved_reg_file: Pep8RegisterFile
	private var saved_reg_file_: Pep8RegisterFile

	init(reg_file: Pep8RegisterFile) do
		saved_reg_file = reg_file
	end

	# fun saved_reg_file: Pep8RegisterFile do return self.saved_reg_file
	fun saved_reg_file=(reg_file: Pep8RegisterFile) do
		saved_reg_file_ = reg_file.copy
	end

	fun saved_reg_file: Pep8RegisterFile do
		return saved_reg_file_.copy
	end end

	fun restore(interpreter: DebuggerInterpreter) do
		interpreter.history_index -= 1
		interpreter.reg_file = saved_reg_file
	end

	fun apply(interpreter: DebuggerInterpreter): Int do
		return interpreter.execute_instr
	end
end

class MemInstructionDiff
	super InstructionDiff
	var affected_address: Int
	var saved_bytes: Int
	var nb_bytes_written: Int

	init(reg_file: Pep8RegisterFile, addr, value, nb_bytes: Int) do
		affected_address = addr
		saved_bytes = value
		nb_bytes_written = nb_bytes
		super(reg_file)
	end

	redef fun restore(interpreter: DebuggerInterpreter) do
		if nb_bytes_written == 1 then
			interpreter.write_byte(affected_address, saved_bytes)
		else
			interpreter.write_word(affected_address, saved_bytes)
		end
		super(interpreter)
	end

	redef fun apply(interpreter: DebuggerInterpreter) do
		return interpreter.execute_instr
	end

end

class InputReadingInstructionDiff
	super MemInstructionDiff
	var new_value: Int
	var new_regs: Pep8RegisterFile

	init (old_reg_file, new_reg_file: Pep8RegisterFile, addr, value_before, value_after, nb_bytes: Int) do
		new_value = value_after
		new_regs = new_reg_file
		super(old_reg_file, addr, value_before, nb_bytes)
	end

	redef fun restore(interpreter: DebuggerInterpreter) do
		if nb_bytes_written == 1 then
			interpreter.write_byte(affected_address, new_value)
		else
			interpreter.write_word(affected_address, new_value)
		end
		super(interpreter)
	end

	redef fun apply(interpreter: DebuggerInterpreter): Int do
		interpreter.history_index += 1
		apply_input_trap_diff(interpreter)
		return 1
	end

	fun apply_input_trap_diff(interpreter: DebuggerInterpreter) do
		interpreter.reg_file = new_regs

		if nb_bytes_written == 1 then
			interpreter.write_byte(affected_address, new_value)
		else
			interpreter.write_word(affected_address, new_value)
		end
	end
end

class DebuggerInterpreter
	super Interpreter

	# Breakpoints list
	var breakpoints_ = new HashSet[Int]

	# The interpreter reached a breakpoint
	var is_trapped = false

	# Allows step by step execution
	var is_step_by_step = false

	var is_started = false

	var history = new Array[InstructionDiff]

	var in_history_mode = false

	var history_index: Int = -1

	fun memory_chunk(addr, length: Int): Array[Byte] do
		var result = new Array[Byte]

		if addr < 0 or addr + length > 2 ** 16 then return result

		for i in [addr..addr+length[ do result.add self.memory[i]

		return result
	end

	fun set_breakpoint(addr: Int) do
		breakpoints_.add addr
	end

	fun remove_breakpoint(addr: Int) do
		breakpoints_.remove addr
	end

	fun breakpoints: Array[Int] do return breakpoints_.to_a

	fun activate_step_by_step do
		self.is_step_by_step = true
	end

	fun deactivate_step_by_step do
		self.is_step_by_step = false
	end

	redef fun start do
		is_started = true
		is_trapped = false
		is_step_by_step = false
		in_history_mode = false

		history.clear
		history_index = -1

		load_image
		reg_file.reset

		execute
	end

	# Returns :
	# 0 : Execution sucessfully terminated
	# 1 : Reached a breakpoint
	# -1 : Execution error or not started
	redef fun execute: Int do
		if not self.is_started then return -1

		loop
			if self.breakpoints.has(reg_file.pc.value) then
				# Allows to resume execution after a trap
				if self.is_trapped then
					self.is_trapped = false
				else
					self.is_trapped = true
					return 1
				end
			end

			var exec_result

			if in_history_mode then
				exec_result = history_mode_exec
			else
				exec_result = execute_instr
			end

			if exec_result == 0 then
				self.is_started = false
				return exec_result
			else if exec_result != 1 then
				return exec_result
			end

			if is_step_by_step then
				is_trapped = true
				return 1
			end
		end
	end

	fun reverse_execute do
		if not self.is_started then return

		if not in_history_mode then
			history_index = history.length - 1
			in_history_mode = true
		end

		loop
			if reg_file.pc.value == 0 then break
			if breakpoints.has(reg_file.pc.value) then
				# Allows to resume execution after a trap
				if is_trapped then
					is_trapped = false
				else
					is_trapped = true
					break
				end
			end

			restore_diff

			if is_step_by_step then
				is_trapped = true
				break
			end

		end
	end

	fun restore_diff do
		if history_index < 0 then return

		var diff = history[history_index]
		diff.restore(self)

	end

	fun history_mode_exec: Int do
		assert history_index >= -1 and history_index < history.length - 1

		if history_index == history.length - 2 then in_history_mode = false

		var diff = history[history_index + 1]

		return diff.apply(self)
	end

	fun diff_with_modif(instr: Instruction, nb_bytes_written: Int): InstructionDiff do
		var addr = resolve_addr(instr)
		return new MemInstructionDiff(reg_file, addr, read_word(addr), nb_bytes_written)
	end

	fun diff_with_input_reading(instr: Instruction, value_after, nb_bytes_written: Int, old_reg_file: Pep8RegisterFile): InstructionDiff do
		var addr = resolve_addr(instr)
		return new InputReadingInstructionDiff(old_reg_file, reg_file, addr, read_word(addr), value_after, nb_bytes_written)
	end

	fun save_diff(diff: InstructionDiff) do
		history_index += 1
		if not in_history_mode then self.history.push(diff)
	end

	redef fun exec_movspa(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_br(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_breq(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_brne(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_brge(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_call(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_deci(instr) do
		var old_reg_file = reg_file

		super

		var addr = resolve_addr(instr)
		var new_value = read_word(addr)
		var nb_bytes_written = 2
		var diff = diff_with_input_reading(instr, new_value, nb_bytes_written, old_reg_file)

		save_diff(diff)
	end

	redef fun exec_chari(instr) do
		var old_reg_file = reg_file
		super

		var addr = resolve_addr(instr)
		var new_value = read_word(addr)
		var nb_bytes_written = 1
		var diff = diff_with_input_reading(instr, new_value, nb_bytes_written, old_reg_file)

		save_diff(diff)
	end

	redef fun exec_charo(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_retn(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_subsp(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_add(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_sub(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_and(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_cp(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_ld(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_st(instr) do
		var nb_bytes_written = 2
		var diff = diff_with_modif(instr, nb_bytes_written)
		save_diff(diff)
		super
	end

	redef fun exec_deco(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_stro(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

end

class Register
	var value: Int = 0
end

class RegisterBit
	var value = 0
end

var model = new Pep8Model("tests/test03.pep")
# var model = new Pep8Model("src/01-exemple.pep")
model.load_instruction_set("src/pep8.json")
model.read_instructions

var reg_file = new Pep8RegisterFile
var interpreter = new Interpreter(model, reg_file)

interpreter.execute
