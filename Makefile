build:
	dune build

watch:
	dune build -w

test:
	dune build @runtest

promote:
	dune build @runtest --auto-promote
