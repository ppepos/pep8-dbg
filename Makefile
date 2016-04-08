FLAGS = --debug

all: bin/tool bin/interpreter

bin/tool:
	mkdir -p bin/
	nitc $(FLAGS) src/tool.nit -o bin/tool

bin/interpreter:
	mkdir -p bin/
	nitc $(FLAGS) src/interpreter.nit -o bin/interpreter

bin/tests:
	mkdir -p bin/
	nitc src/tests.nit -o bin/tests

test: bin/tests
	bin/tests

clean:
	rm -rf bin/
