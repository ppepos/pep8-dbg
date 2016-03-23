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
		loop
			# Disassemble next instr
			# exec instr
			#	Setup instr effect
			#	[capture instr effect]
			#	Update virtual memory
			# update pc
		end
	end
end

class Pep8RegisterFile

	# Accumulator
	var a: Register

	# Index Register
	var x: Register

	# Stack Pointer
	var sp: Register

	# Program Counter
	var pc: Register

	# Negative
	var n: Register

	# Zero
	var z: Register

	# Overflow
	var v: Register

	# Carry
	var c: Register
end

class Register
end
