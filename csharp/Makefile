INPUTFILE = ../../input.ini
OUTPUTFILE = ../output.ini

BUILD_DIR = ./build
OBJ_DIR = ./obj
BIN_DIR = ./bin # published programs are somewhere under here

.PHONY: build publish run clean cleanall

build:
	dotnet build -o ${BUILD_DIR}/

run: build
	${BUILD_DIR}/parizer.exe ${INPUTFILE} ${OUTPUTFILE}
	
publish:
	dotnet publish -p:PublishSingleFile=true --self-contained false

clean:
	rm -rf ${OBJ_DIR}/
	rm -f ${BUILD_DIR}/parizer
	rm -f ${BUILD_DIR}/parizer.dll
	rm -f ${BUILD_DIR}/parizer.pdb
	rm -f ${BUILD_DIR}/parizer.deps.json
	rm -f ${BUILD_DIR}/parizer.runtimeconfig.json

cleanall: clean
	rm -rf ${OBJ_DIR}
	rm -rf ${BUILD_DIR}
	rm -rf ${BIN_DIR}
