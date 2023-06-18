all: gen

build_gen:
	v src/gen/gen.v -o bin/vgtklibgen

gen: build_gen
	vgtklibgen
