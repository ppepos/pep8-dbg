
all: tools

tools:
	mkdir -p bin/
	nitc src/tool.nit -o bin/tool
