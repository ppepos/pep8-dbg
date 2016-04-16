import interpreter
import disasm

class DebuggerController
	var interpreter: DebuggerInterpreter
	var disasm: Disassembler

	init with_model(model: Pep8Model) do
		var reg_file = new Pep8RegisterFile
		disasm = new Disassembler(model)

		interpreter = new DebuggerInterpreter(model, reg_file)

		init(interpreter, disasm)
	end

	fun cont do
		interpreter.execute
	end

	fun reverse_cont do
		interpreter.reverse_execute
	end

	fun nexti do
		interpreter.activate_step_by_step
		cont
		interpreter.deactivate_step_by_step
	end

	fun reverse_nexti do
		interpreter.activate_step_by_step
		reverse_cont
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
	fun breakpoints: Array[Int] do return interpreter.breakpoints
	fun memory(addr, length: Int): Array[Byte] do return interpreter.memory_chunk(addr, length)
	fun reg_file: Pep8RegisterFile do return interpreter.reg_file
	fun disassemble(addr, length: Int): String do
		var mem = memory(addr, length)
		return self.disasm.disassemble_stream(mem, length, true)
	end
	fun run do self.interpreter.start
end

class DebuggerCLI
	var ctrl: DebuggerController

	init with_model(model: Pep8Model) do
		var ctrl = new DebuggerController.with_model(model)
		init(ctrl)
	end

	fun parse_command(input: String) do
		var tokens = input.split(" ")

		if tokens.is_empty then return

		var cmd = tokens[0]

		if ["b", "break", "breakpoint"].has(cmd) then
			if tokens.length != 2 or not tokens[1].is_int then
				print "Usage : {cmd} address"
			else
				ctrl.set_breakpoint tokens[1].to_i
			end
		else if ["r", "remove"].has(cmd) then
			if tokens.length != 2 or not tokens[1].is_int then
				print "Usage : {cmd} address"
			else
				ctrl.remove_breakpoint tokens[1].to_i
			end
		else if ["ni", "nexti"].has(cmd) then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				ctrl.nexti
			end
		else if ["rev-ni", "rev-nexti"].has(cmd) then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				ctrl.reverse_nexti
			end
		else if ["c", "continue"].has(cmd) then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				ctrl.cont
			end
		else if ["rev-c", "rev-continue"].has(cmd) then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				ctrl.reverse_cont
			end
		else if ["so", "stepo", "stepover"].has(cmd) then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				ctrl.stepo
			end
		else if ["reg", "registers"].has(cmd) then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				print_reg
			end
		else if ["dump"].has(cmd) then
			if tokens.length != 3 or not tokens[1].is_int or not tokens[2].is_int then
				print "Usage : {cmd} address length"
			else
				dump_mem(tokens[1].to_i, tokens[2].to_i)
			end
		else if ["d", "disass", "disassemble"].has(cmd) then
			if tokens.length != 3 or not tokens[1].is_int or not tokens[2].is_int then
				print "Usage : {cmd} address length"
			else
				disass(tokens[1].to_i, tokens[2].to_i)
			end
		else if cmd == "run" then
			if tokens.length > 1 then
				print "Usage : {cmd}"
			else
				ctrl.run
			end
		else if ["d", "disass", "disassemble"].has(cmd) then
			if tokens.length != 3 or not tokens[1].is_int or not tokens[2].is_int then
				print "Usage : {cmd} address length"
			else
				disass(tokens[1].to_i, tokens[2].to_i)
			end
		else if ["h", "help", "?"].has(cmd) then
			if tokens.length != 1 then
				print "Usage : {cmd}"
			else
				print_help
			end
		else if ["listbp", "list"].has(cmd) then
			if tokens.length != 1 then
				print "Usage : {cmd}"
			else
				print "Breakpoints : "
				print ctrl.breakpoints
			end
		else if ["q", "quit"].has(cmd) then
			if tokens.length != 1 then
				print "Usage: {cmd}"
			else
				exit(0)
			end
		else
			print "Unknown command: {cmd}"
		end
	end

	fun print_reg do
		var regs = ctrl.reg_file
		print "=========================="
		print "A : {regs.a.value}"
		print "X : {regs.x.value}"
		print "PC : {regs.pc.value}"
		print "SP : {regs.sp.value}"
		print "N : {regs.n.value} Z: {regs.z.value} V: {regs.v.value} C: {regs.c.value}"
		print "=========================="
	end

	fun print_help do
		print "====================================================="
		print "                    COMMAND LIST"
		print "====================================================="
		print "break address         : Add a breakpoint"
		print "remove address        : Removes a breakpoint"
		print "list                  : List all breakpoints"
		print "nexti                 : Break to next instruction"
		print "rev-nexti             : Break to previous instruction"
		print "continue              : Resume execution"
		print "rev-continue          : Resume reverse execution"
		print "stepo                 : Step over function calls"
		print "reg                   : Print the registers"
		print "dump address length   : Dump memory"
		print "disass address length : Disassemble instructions"
		print "run                   : Run the program"
		print "help                  : Print this menu"
		print "quit                  : Exit the debugger"
		print "====================================================="
	end

	fun dump_mem(addr, len: Int) do
		var mem = ctrl.memory(addr, len)

		for byte in mem, i in [0..len[ do
			if i % 16 == 0 then print ""
			printn "{byte} "
		end
		print ""
	end

	fun disass(addr, len: Int) do
		print ctrl.disassemble(addr, len)
	end

	fun command_loop do
		var input = ""

		loop
			printn "PEPdb> "
			input = stdin.read_line
			parse_command input
			#if stdin.eof then exit(0)
		end
	end
end

if args.length != 1 then
	print "Usage: {program_name} <source_file.pep>"
	exit(1)
end

var source_file = args[0]
var model = new Pep8Model(source_file)
model.load_instruction_set("src/pep8.json")
model.read_instructions

var debugger = new DebuggerCLI.with_model(model)
debugger.command_loop
