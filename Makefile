
SRCD=./src
OBJD=./build
OBJ=$(OBJD)/spillocore.o $(OBJD)/lex.o $(OBJD)/parse.o $(OBJD)/parse_spillocore.o

DC=dmd

DFLAGS=-w -c -I=$(SRCD)


all : $(OBJ)
	$(DC) -of=$(OBJD)/cuci1 $(OBJ)

$(OBJD)/spillocore.o : $(SRCD)/lex.d $(SRCD)/parse.d $(SRCD)/spillocore.d
	$(DC) $(DFLAGS) $(SRCD)/spillocore.d -of=$(OBJD)/spillocore.o

$(OBJD)/lex.o : $(SRCD)/lex.d
	$(DC) $(DFLAGS) $(SRCD)/lex.d -of=$(OBJD)/lex.o

$(OBJD)/parse.o : $(SRCD)/parse.d
	$(DC) $(DFLAGS) $(SRCD)/parse.d -of=$(OBJD)/parse.o

$(OBJD)/parse_spillocore.o : $(SRCD)/parse_spillocore.d
	$(DC) $(DFLAGS) $(SRCD)/parse_spillocore.d -of=$(OBJD)/parse_spillocore.o

release :
	$(DC)


.PHONY : clean
clean :
	rm $(OBJD)/cuci1 $(OBJ)
