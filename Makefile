
SRCD=./src
OBJD=./build
OBJ=$(OBJD)/spillocore.o $(OBJD)/lex.o

DC=dmd

DFLAGS=-w -c -I=$(SRCD)


all : $(OBJ)
	$(DC) -of=$(OBJD)/cuci1 $(OBJ)

$(OBJD)/lex.o : $(SRCD)/lex.d
	$(DC) $(DFLAGS) $(SRCD)/lex.d -of=$(OBJD)/lex.o

$(OBJD)/spillocore.o : $(SRCD)/spillocore.d
	$(DC) $(DFLAGS) $(SRCD)/spillocore.d -of=$(OBJD)/spillocore.o


release :
	$(DC)


.PHONY : clean
clean :
	rm $(OBJD)/cuci1 $(OBJ)
