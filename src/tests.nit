import asm
import disasm

var test_file_prefixes = ["test01", "test02", "test03", "test04"]
var test_disasm_len = [40, 44, 33, 118]
var test_path = "tests/"
var failure = false


print "## Starting tests ##"

print "Assembler tests"
for f_prefix in test_file_prefixes do
	var f = new FileReader.open(test_path + f_prefix + ".out")

	printn "{f_prefix}... "

	var model = new Pep8Model(test_path + f_prefix + ".pep")
	model.load_instruction_set("src/pep8.json")
	model.read_instructions

	if model.assemble != f.read_bytes(4096) then
		print "FAIL"
		failure = true
	else
		print "OK"
	end
end

var model = new Pep8Model("")
model.load_instruction_set("src/pep8.json")
model.read_instructions
var disasm = new Disassembler(model)

print ""
print "Disassembler tests"

for i in [0..test_file_prefixes.length[ do
	var fout = new FileReader.open(test_path + test_file_prefixes[i] + ".dis")
	var fin = new FileReader.open(test_path + test_file_prefixes[i] + ".out")
	var byte_stream = new Array[Byte]

	for byte in fin.read_bytes(4096) do byte_stream.add byte

	printn "{test_file_prefixes[i]}... "

	var result = disasm.disassemble_stream(byte_stream, test_disasm_len[i], false).to_bytes
	var expected = fout.read_bytes(4096)

	if result != expected then
		print "FAIL"
		failure = true
	else
		print "OK"
	end
end

if not failure then
	print "[X] All tests where successful"
else
	print "[-] Some tests failed"
	exit 1
end

