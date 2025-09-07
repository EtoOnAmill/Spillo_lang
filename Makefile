
SRCD=./src
OBJD=./build
OBJ=$(OBJD)/lex.o $(OBJD)/parse.o $(OBJD)/parse_spillocore.o $(OBJD)/semantic_ast.o

DC=dmd

DFLAGS=-debug -g -w -c -I=$(SRCD)


all : $(OBJ) $(OBJD)/spillocore.o
	$(DC) -of=$(OBJD)/cuci1 $(OBJ) $(OBJD)/spillocore.o

test : $(OBJ) $(OBJD)/test.o
	$(DC) -of=$(OBJD)/TEST $(OBJ) $(OBJD)/test.o
$(OBJD)/test.o : $(patsubst $(OBJD)/%.o,$(SRCD)/%.d, $(OBJ)) $(SRCD)/test.d
	$(DC) $(DFLAGS) $(SRCD)/test.d -of=$(OBJD)/test.o

$(OBJD)/lex.o : $(SRCD)/lex.d
	$(DC) $(DFLAGS) $(SRCD)/lex.d -of=$(OBJD)/lex.o

$(OBJD)/parse.o : $(SRCD)/lex.d $(SRCD)/parse.d
	$(DC) $(DFLAGS) $(SRCD)/parse.d -of=$(OBJD)/parse.o

$(OBJD)/parse_spillocore.o : $(SRCD)/parse.d $(SRCD)/parse_spillocore.d 
	$(DC) $(DFLAGS) $(SRCD)/parse_spillocore.d -of=$(OBJD)/parse_spillocore.o

$(OBJD)/semantic_ast.o  : $(SRCD)/parse_spillocore.d $(SRCD)/semantic_ast.d
	$(DC) $(DFLAGS) $(SRCD)/semantic_ast.d -of=$(OBJD)/semantic_ast.o

$(OBJD)/spillocore.o : $(patsubst $(OBJD)/%.o,$(SRCD)/%.d, $(OBJ)) $(SRCD)/spillocore.d
	$(DC) $(DFLAGS) $(SRCD)/spillocore.d -of=$(OBJD)/spillocore.o

release :
	$(DC)


.PHONY : clean
clean :
	rm $(OBJD)/cuci1 $(OBJ)
