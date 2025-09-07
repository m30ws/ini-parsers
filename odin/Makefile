INPUT = ../input.ini
OUTPUT = ./output.ini

# WINVARS = "C:/Program Files/Microsoft Visual Studio/2017/Community/VC/Auxiliary/Build/vcvarsall.bat"
# MSVCVARS = (...)/init64.bat

.PHONY: all debug

all:
	 odin run ./src -- ${INPUT} ${OUTPUT}

debug:
	 odin run ./src -debug -keep-executable -sanitize:address -- ${INPUT} ${OUTPUT}
