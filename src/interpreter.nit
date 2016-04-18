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

	var last_pc: Int = 0

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

		last_pc = reg_file.pc.value
		# Increment program counter
		update_pc(instr)

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
		else if instr.op_str == "BRLE" then
			exec_brle(instr)
		else if instr.op_str == "BRLT" then
			exec_brlt(instr)
		else if instr.op_str == "BRGT" then
			exec_brgt(instr)
		else if instr.op_str == "BRV" then
			exec_brv(instr)
		else if instr.op_str == "BRC" then
			exec_brc(instr)
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
		else if instr.op_str == "RET" then
			exec_ret(instr)
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
		else if instr.op_str == "LDBYTE" then
			exec_ldbyte(instr)
		else if instr.op_str == "ST" then
			exec_st(instr)
		else if instr.op_str == "STBYTE" then
			exec_stbyte(instr)
		else if instr.op_str == "NOP" then
			exec_nop(instr)
		else if instr.op_str == "MOVFLGA" then
			exec_movflga(instr)
		else if instr.op_str == "NOT" then
			exec_not(instr)
		else if instr.op_str == "NEG" then
			exec_neg(instr)
		else if instr.op_str == "ASL" then
			exec_asl(instr)
		else if instr.op_str == "ASR" then
			exec_asr(instr)
		else if instr.op_str == "ROL" then
			exec_rol(instr)
		else if instr.op_str == "ROR" then
			exec_ror(instr)
		else if instr.op_str == "ADDSP" then
			exec_addsp(instr)
		else if instr.op_str == "OR" then
			exec_or(instr)

		# Tough luck
		else
			print "{instr} - not yet implemented"
		end

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

	fun read_byte(addr: Int): Int do
		return memory[addr].to_i
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
			addr = (read_word((reg_file.sp.value + value) & 0xffff) + reg_file.x.value) & 0xffff
		else
			print "addressing mode not recognized"
		end

		return addr
	end

	fun resolve_opernd_value(instr: Instruction, nb_bytes: Int): Int do
		var value: Int
		var addr: Int

		if instr.addr_mode == "i" then
			if nb_bytes == 2 then
				value = get_imm_value(instr)
			else
				value = get_imm_value(instr) & 0xff
			end
		else
			addr = resolve_addr(instr)
			if nb_bytes == 2 then
				value = read_word(addr)
			else
				value = read_byte(addr)
			end
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
		var addr = resolve_opernd_value(instr, 2)
		reg_file.pc.value = addr
	end

	fun exec_brle(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)
		if reg_file.n.value == 1 or reg_file.z.value == 1 then reg_file.pc.value = addr
	end

	fun exec_brlt(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)
		if reg_file.n.value == 1 then reg_file.pc.value = addr
	end

	fun exec_brgt(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)
		if reg_file.n.value == 0 and reg_file.z.value == 0 then reg_file.pc.value = addr
	end

	fun exec_brv(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)
		if reg_file.v.value == 1 then reg_file.pc.value = addr
	end

	fun exec_brc(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)
		if reg_file.c.value == 1 then reg_file.pc.value = addr
	end

	fun exec_breq(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)

		# If Zero flag, set PC to addr
		if reg_file.z.value == 1 then reg_file.pc.value = addr
	end

	fun exec_brne(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)

		# In not zero, set PC to addr
		if reg_file.z.value != 1 then reg_file.pc.value = addr
	end

	fun exec_brge(instr: Instruction) do
		var addr = resolve_opernd_value(instr, 2)

		# If Neg flag unset, set PC to addr
		if reg_file.n.value == 0 then reg_file.pc.value = addr
	end

	fun exec_call(instr: Instruction) do
		var op_val = resolve_opernd_value(instr, 2)

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
		var value = resolve_opernd_value(instr, 1)

		printn value.to_b.ascii
	end

	fun exec_ret(instr: Instruction) do
		var n = instr.suffix.to_i
		var sp = reg_file.sp
		var pc = reg_file.pc

		sp.value = (sp.value + n) & 0xffff
		pc.value = read_word(sp.value)
		sp.value = (sp.value + 2) & 0xffff
	end

	fun exec_subsp(instr: Instruction) do
		var op_val = resolve_opernd_value(instr, 2)
		reg_file.sp.value = reg_sub(reg_file.sp.value, op_val)
	end

	fun exec_addsp(instr: Instruction) do
		var op_val = resolve_opernd_value(instr, 2)
		reg_file.sp.value = reg_add(reg_file.sp.value, op_val)
	end

	fun exec_add(instr: Instruction) do
		var op_val = resolve_opernd_value(instr, 2)
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
		var op_val = resolve_opernd_value(instr, 2)
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
		var op_val = resolve_opernd_value(instr, 2)
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

	fun exec_or(instr: Instruction) do
		var op_val = resolve_opernd_value(instr, 2)
		var reg: Register

		if instr.suffix == "A" then
			reg = reg_file.a
		else
			reg = reg_file.x
		end

		op_val = op_val & 0xFFFF
		var result = op_val | reg.value
		reg_file.n.value = if result > 32768 then 1 else 0
		reg_file.z.value = if result == 0 then 1 else 0
	end

	fun exec_cp(instr: Instruction) do

		var cmp_value: Int
		var cmp_reg = instr.suffix

		cmp_value = resolve_opernd_value(instr, 2)

		if cmp_reg == "A" then
			reg_sub(reg_file.a.value, cmp_value)
		else if cmp_reg == "X" then
			reg_sub(reg_file.x.value, cmp_value)
		end

		# print "nzvc: {reg_file.n.value} {reg_file.z.value} {reg_file.v.value} {reg_file.c.value}"
	end

	fun exec_ld(instr: Instruction) do

		var value = resolve_opernd_value(instr, 2)

		if instr.suffix == "A" then
			reg_file.a.value = value
		else if instr.suffix == "X" then
			reg_file.x.value = value
		end

		reg_file.update_state_regs(value)
	end

	fun exec_ldbyte(instr: Instruction) do
		var value = resolve_opernd_value(instr, 1)

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

	fun exec_stbyte(instr: Instruction) do
		# Store suffix in operand value address
		var addr = resolve_addr(instr)

		var reg: Register
		if instr.suffix == "A" then reg = reg_file.a else reg = reg_file.x

		write_byte(addr, reg.value)
	end

	fun exec_deco(instr: Instruction) do
		printn resolve_opernd_value(instr, 2)
	end

	fun exec_stro(instr: Instruction) do
		var ptr = resolve_addr(instr)

		while memory[ptr] != 0.to_b do
			printn memory[ptr].ascii
			ptr += 1
		end
	end

	fun exec_movflga(instr: Instruction) do
        var value = reg_file.c.value
		value += reg_file.v.value << 1
		value += reg_file.z.value << 2
		value += reg_file.n.value << 3

		reg_file.a.value = value
	end

	fun exec_not(instr: Instruction) do
        var value

		if instr.suffix == "A" then
			value = ~reg_file.a.value & 0xffff
			reg_file.a.value = value
		else
			value = ~reg_file.x.value & 0xffff
			reg_file.x.value = value
		end

		reg_file.update_state_regs(value)
	end

	fun exec_neg(instr: Instruction) do
        var value

		if instr.suffix == "A" then
			value = (~reg_file.a.value + 1) & 0xffff
			reg_file.a.value = value
		else
			value = (~reg_file.x.value + 1) & 0xffff
			reg_file.x.value = value
		end

		# overflow flag
		reg_file.v.value = if value == 32768 then 1 else 0

		reg_file.update_state_regs(value)
	end

	# Following Warford implementation, this is a signed multiplication, not a real bit shift
	fun exec_asl(instr: Instruction) do
        var value
		var old_val

		if instr.suffix == "A" then
			old_val= reg_file.a.value
			value = reg_file.a.value * 2
			reg_file.a.value = value & 0xffff
		else
			old_val= reg_file.x.value
			value = reg_file.x.value * 2
			reg_file.x.value = value & 0xffff
		end

		reg_file.c.value = 0
		if value >= 65536 then reg_file.c.value = 1

		reg_file.v.value = 0
		# Check overflow for both signed and unsigned value
		if (old_val >= 0x4000 and old_val < 0x8000) or (old_val >= 0x8000 and old_val < 0xC000) then
			reg_file.v.value = 1
		end

		reg_file.update_state_regs(value)
	end

	# Following Warford implementation, this is a signed multiplication, not a real bit shift
	fun exec_asr(instr: Instruction) do
        var value
		var old_val

		if instr.suffix == "A" then
			old_val= reg_file.a.value

			if old_val < 32768 then
				value = old_val / 2
			else
				value = old_val / 2 + 32768
			end

			reg_file.a.value = value
		else
			old_val= reg_file.x.value

			if old_val < 32768 then
				value = old_val / 2
			else
				value = old_val / 2 + 32768
			end

			reg_file.x.value = value
		end

		if (old_val % 2) == 1 then
			reg_file.c.value = 1
		else
			reg_file.c.value = 0
		end

		reg_file.update_state_regs(value)
	end

	fun exec_rol(instr: Instruction) do
		var carry
		if instr.suffix == "A" then
			carry = if reg_file.a.value >= 32768 then 1 else 0
			reg_file.a.value = (reg_file.a.value * 2) & 0xffff
			reg_file.a.value |= carry
		else
			carry = if reg_file.x.value >= 32768 then 1 else 0
			reg_file.x.value = (reg_file.x.value * 2) & 0xffff
			reg_file.x.value |= carry
		end

		reg_file.c.value = carry
	end

	fun exec_ror(instr: Instruction) do
		var carry
		if instr.suffix == "A" then
			carry = reg_file.a.value % 2 == 1
			reg_file.a.value = (reg_file.a.value / 2)
			reg_file.a.value |= if carry then 0x8000 else 0
		else
			carry = reg_file.x.value % 2 == 1
			reg_file.x.value = (reg_file.x.value / 2)
			reg_file.x.value |= if carry then 0x8000 else 0
		end

		reg_file.c.value = if carry then 1 else 0
	end

	fun exec_nop(instr: Instruction) do end

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
		n.value = if value >= 32768 then 1 else 0
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
	end

	fun restore(interpreter: DebuggerInterpreter) do
		interpreter.history_index -= 1
		interpreter.reg_file = saved_reg_file
	end

	fun apply(interpreter: DebuggerInterpreter): Int do
		return interpreter.execute_instr
	end

	fun modify_pc(new_pc: Int) do saved_reg_file_.pc.value = new_pc

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
	var force_continue = false

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

	redef fun start do
		is_started = true
		force_continue = false
		is_step_by_step = false
		in_history_mode = false

		history.clear
		history_index = -1

		load_image
		reg_file.reset

		execute
	end

	fun cont do
		force_continue = true
		execute
	end

	fun reverse_cont do
		force_continue = true
		reverse_execute
	end

	fun nexti do
		force_continue = true
		is_step_by_step = true
		execute
		is_step_by_step = false
	end

	fun reverse_nexti do
		force_continue = true
		is_step_by_step = true
		reverse_execute
		is_step_by_step = false
	end

	fun stepo do
		var len_call = 3
		var pc = reg_file.pc.value + len_call
		var keep_bp = false

		if breakpoints.has(pc) then
			keep_bp = true
		else
			set_breakpoint pc
		end

		force_continue = true
		execute

		# If the breakpoint was previously in the list don't remove it
		if not keep_bp then remove_breakpoint pc
	end

	# Returns :
	# 0 : Execution sucessfully terminated
	# 1 : Reached a breakpoint
	# -1 : Execution error or not started
	redef fun execute: Int do
		if not self.is_started then return -1

		loop
			if self.breakpoints.has(reg_file.pc.value) and not force_continue then return 1
			force_continue = false

			var exec_result

			if history_index == history.length - 1 then
				exec_result = execute_instr
			else
				exec_result = history_mode_exec
			end

			if exec_result == 0 then
				self.is_started = false
				return exec_result
			else if exec_result != 1 then
				return exec_result
			end

			if is_step_by_step then return 1
		end
	end

	fun reverse_execute do
		if not self.is_started then return

		loop
			if reg_file.pc.value == 0 then break

			if breakpoints.has(reg_file.pc.value) and not force_continue then break

			force_continue = false

			restore_diff

			if is_step_by_step then break
		end
	end

	fun restore_diff do
		if history_index < 0 then return

		var diff = history[history_index]
		diff.restore(self)
	end

	fun debug_print_history do
		print "====== HISTORY ======"
		for d in history do
			print d.saved_reg_file
			print " ============= "
		end
		print "====== END HISTORY ======"
	end

	fun history_mode_exec: Int do
		assert history_index >= -1 and history_index <= history.length - 1
		var diff = history[history_index+1]

		return diff.apply(self)
	end

	fun diff_with_modif(instr: Instruction, nb_bytes_written: Int): InstructionDiff do
		var addr = resolve_addr(instr)
		return new MemInstructionDiff(reg_file, addr, read_word(addr), nb_bytes_written)
	end

	fun diff_with_input_reading(instr: Instruction, addr, value_before, nb_bytes_written: Int, old_reg_file: Pep8RegisterFile): InstructionDiff do
		var new_value
		if nb_bytes_written == 2 then
			new_value = read_word(addr)
		else
			new_value = read_byte(addr)
		end

		return new InputReadingInstructionDiff(old_reg_file, reg_file, addr, value_before, new_value, nb_bytes_written)
	end

	fun save_diff(diff: InstructionDiff) do
		history_index += 1
		if history_index != history.length then return

		diff.modify_pc last_pc
		history.push(diff)
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

	redef fun exec_brle(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_brlt(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_brgt(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_brv(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_brc(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_call(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_deci(instr) do
		var old_reg_file = reg_file
		var addr = resolve_addr(instr)
		var old_value = read_word(addr)
		var nb_bytes_written = 2

		super

		var diff = diff_with_input_reading(instr, addr, old_value, nb_bytes_written, old_reg_file)
		save_diff(diff)
	end

	redef fun exec_chari(instr) do
		var old_reg_file = reg_file
		var addr = resolve_addr(instr)
		var old_value = read_byte(addr)
		var nb_bytes_written = 1

		super

		var diff = diff_with_input_reading(instr, addr, old_value, nb_bytes_written, old_reg_file)
		save_diff(diff)
	end

	redef fun exec_charo(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_ret(instr) do
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

	redef fun exec_ldbyte(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_st(instr) do
		var nb_bytes_written = 2
		var diff = diff_with_modif(instr, nb_bytes_written)
		save_diff(diff)
		super
	end

	redef fun exec_stbyte(instr) do
		var nb_bytes_written = 1
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

	redef fun exec_nop(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_movflga(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_not(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_neg(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_asl(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_asr(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_rol(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_ror(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_addsp(instr) do
		save_diff(new InstructionDiff(reg_file))
		super
	end

	redef fun exec_or(instr) do
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

if args.length != 1 then
	print "Usage: {program_name} <source_file.pep>"
	exit(1)
end

var source_file = args[0]
var model = new Pep8Model(source_file)
# var model = new Pep8Model("src/01-exemple.pep")
model.load_instruction_set("src/pep8.json")
model.read_instructions

var reg_file = new Pep8RegisterFile
var interpreter = new Interpreter(model, reg_file)

interpreter.start
