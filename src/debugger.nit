import interpreter
import disasm
import readline

class DebuggerController
	var interpreter: DebuggerInterpreter
	var disasm: Disassembler

	init with_model(model: Pep8Model) do
		var reg_file = new Pep8RegisterFile
		disasm = new Disassembler(model)

		interpreter = new DebuggerInterpreter(model, reg_file)

		init(interpreter, disasm)
	end

	fun cont do interpreter.cont
	fun reverse_cont do interpreter.reverse_cont
	fun nexti do interpreter.nexti
	fun reverse_nexti do interpreter.reverse_nexti
	fun stepo do interpreter.stepo
	fun set_breakpoint(addr: Int) do interpreter.set_breakpoint addr
	fun remove_breakpoint(addr: Int) do interpreter.remove_breakpoint addr
	fun breakpoints: Array[Int] do return interpreter.breakpoints
	fun memory(addr, length: Int): Array[Byte] do return interpreter.memory_chunk(addr, length)
	fun reg_file: Pep8RegisterFile do return interpreter.reg_file
	fun disassemble(addr, length: Int): String do
		var mem = memory(addr, length)
		return self.disasm.disassemble_stream(mem, length, true, reg_file.pc.value)
	end
	fun run do self.interpreter.start
	fun source: String do
		var nb_lines = 5
		var current_pc = reg_file.pc.value

		var src_instr = interpreter.source_instr(current_pc)
		var src_line = interpreter.source_line(current_pc)

		var current_instr = disasm.decode_next_instruction(memory(current_pc, 3))

		# Current memory differs from the source, so we use the disassembler instead
		if src_instr == null or src_instr != current_instr then return disassemble(reg_file.pc.value, 3 * nb_lines)

		var out = ""
		# Get the next lines from the source file
		for i in [0..nb_lines[ do
			var out_template = "{current_pc.to_hex.justify(4, 1.0, '0')} "
			if src_line == null then return out
			out += out_template + src_line + "\n"
			current_pc += src_instr.len
			src_line = interpreter.source_line(current_pc)
			src_instr = interpreter.source_instr(current_pc)
		end

		return out
	end

end

class DebuggerCLI
	var ctrl: DebuggerController
	var rl = new Readline.with_mode(0)

	init with_model(model: Pep8Model) do
		var ctrl = new DebuggerController.with_model(model)
		init(ctrl)
	end

	fun preprocess_command(input: String): String do
		for sub in input.split(" ") do
			if sub.has_prefix("$") then sub = preprocess_replace_register(sub)
		end
		print input
		return input
	end

	fun preprocess_replace_register(reg_name: String): String do
		reg_name = reg_name.substring_from(1)
		reg_name = reg_name.to_lower
		if reg_name == "a" then return ctrl.reg_file.a.value.to_s
		if reg_name == "x" then return ctrl.reg_file.x.value.to_s
		if reg_name == "pc" then return ctrl.reg_file.pc.value.to_s
		if reg_name == "sp" then return ctrl.reg_file.sp.value.to_s
		if reg_name == "n" then return ctrl.reg_file.n.value.to_s
		if reg_name == "z" then return ctrl.reg_file.z.value.to_s
		if reg_name == "v" then return ctrl.reg_file.v.value.to_s
		if reg_name == "c" then return ctrl.reg_file.c.value.to_s
		return "Cannot recognize register" + reg_name
	end

	fun parse_command(input: String) do
		var parsed_input = preprocess_command(input)

		var tokens = parsed_input.split(" ")

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
		var input
		var with_history = true
		var last_command = ""

		loop
			print_reg
			print ctrl.source
			print ""
			input = rl.readline("PEPdb> ", with_history)

			# EOF
			if input == null then return

			# Sending an empty line replays the last command
			if input == "" then
				parse_command last_command
			else
				parse_command input
				last_command = input
			end
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
