all: gen

build_gen:
	v . -o bin/vgtklibgen

gen: build_gen
	vgtklibgen
