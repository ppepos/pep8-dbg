import interpreter

class DebuggerController
	var interpreter: DebuggerInterpreter

	init(model: Pep8Model) do
		var reg_file = new Pep8RegisterFile
		var interpreter = new DebuggerInterpreter(model, reg_file)
	end

	fun cont do interpreter.execute

	fun nexti do
		interpreter.activate_step_by_step
		cont
		interpreter.deactivate_step_by_step
	end

	fun stepo do
		var len_call = 3
		var pc = interpreter.reg_file.pc.value + len_call
		var keep_bp = false

		if interpreter.breakpoints.has(pc) then
			keep_bp = true
		else
			interpreter.set_breakpoint pc
		end

		interpreter.execute

		# If the breakpoint was previously in the list don't remove it
		if not keep_bp then interpreter.remove_breakpoint pc
	end

	fun set_breakpoint(addr: Int) do interpreter.set_breakpoint addr
	fun remove_breakpoint(addr: Int) do interpreter.remove_breakpoint addr
	fun dump_memory(addr, length: Int): Array[Byte] do return interpreter.memory_chunk(addr, length)
	fun dump_reg: Pep8RegisterFile do return interpreter.reg_file
end

class DebuggerCLI
	fun parse_command do return
	fun command_loop do return
end
