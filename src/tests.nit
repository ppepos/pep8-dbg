import asm

var test_file_prefixes = ["test01", "test02", "test03", "test04"]
var test_path = "tests/"
var failure = false

print "## Starting tests ##"

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

if not failure then
	print "[X] All tests where successful"
else
	print "[-] Some tests failed"
	exit 1
end

