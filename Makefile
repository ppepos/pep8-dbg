all: tools

tools:
	mkdir -p bin/
	nitc src/tool.nit -o bin/tool

debug:
	mkdir -p bin/
	nitc --debug src/tool.nit -o bin/tool

test:
	mkdir -p bin/
	nitc src/tests.nit -o bin/tests
	bin/tests

test_int:
	mkdir -p bin/
	nit src/tests.nit
	bin/tests

clean:
	rm -rf bin/
