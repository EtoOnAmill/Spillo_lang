
SRCD=./src
OBJD=./build
OBJ=$(OBJD)/lex.o $(OBJD)/parse.o $(OBJD)/parse_spillocore.o $(OBJD)/spillocore.o

DC=dmd

DFLAGS=-w -c -I=$(SRCD)


all : $(OBJ)
	$(DC) -of=$(OBJD)/cuci1 $(OBJ)

$(OBJD)/lex.o : $(SRCD)/lex.d
	$(DC) $(DFLAGS) $(SRCD)/lex.d -of=$(OBJD)/lex.o

$(OBJD)/parse.o : $(SRCD)/lex.d $(SRCD)/parse.d
	$(DC) $(DFLAGS) $(SRCD)/parse.d -of=$(OBJD)/parse.o

$(OBJD)/parse_spillocore.o : $(SRCD)/parse.d $(SRCD)/parse_spillocore.d 
	$(DC) $(DFLAGS) $(SRCD)/parse_spillocore.d -of=$(OBJD)/parse_spillocore.o

$(OBJD)/spillocore.o : $(SRCD)/lex.d $(SRCD)/parse.d $(SRCD)/parse_spillocore.d $(SRCD)/spillocore.d
	$(DC) $(DFLAGS) $(SRCD)/spillocore.d -of=$(OBJD)/spillocore.o

release :
	$(DC)


.PHONY : clean
clean :
	rm $(OBJD)/cuci1 $(OBJ)
