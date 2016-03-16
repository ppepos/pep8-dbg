# This is an ongoing Reverse-Debugging project for PEP/8 educational assembly language

## Compiling

```bash
$ make
```

## Usage

```bash
Usage: bin/tool [OPTIONS...] filename
Options:
-a           Assemble
-d           Disassemble
-n           Number of bytes to disassemble
-h, --help   Show this help message
```

To assemble a file
```bash
bin/tool -a filename.pep
```

To disassemble a file
```bash
bin/tool -d filename.pepo -n [number of bytes]
```


