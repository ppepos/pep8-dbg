FLAGS = --debug

all: bin/tool bin/interpreter bin/debugger

bin/tool:
	mkdir -p bin/
	nitc $(FLAGS) src/tool.nit -o bin/tool

bin/interpreter:
	mkdir -p bin/
	nitc $(FLAGS) src/interpreter.nit -o bin/interpreter

bin/tests:
	mkdir -p bin/
	nitc $(FLAGS) src/tests.nit -o bin/tests

bin/debugger:
	mkdir -p bin/
	nitc $(FLAGS) src/debugger.nit -o bin/debugger

test: bin/tests
	bin/tests

clean:
	rm -rf bin/
