EC=erlc
EFLAGS=-o $(BUILD)
SRC=src
BUILD=build
BEAM=build/lex.beam build/parse.beam build/sew.beam

all: $(BEAM)
#	$(EC) $(EFLAGS) $(SRC)/*.erl

build/lex.beam: src/lex.erl
	$(EC) $(EFLAGS) src/lex.erl

build/parse.beam: src/parse.erl
	$(EC) $(EFLAGS) src/parse.erl

build/sew.beam: src/sew.erl
	$(EC) $(EFLAGS) src/sew.erl



.PHONY : clean
clean :
	rm $(BUILD)/*.beam
