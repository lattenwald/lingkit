all: get-deps compile

ling-build-image compile get-deps:
	rebar $@

test:
	erl -pa ebin -s ssl -s inets -eval 'erlang:display(lingkit:compile_forms(lingkit:test_forms())).'
