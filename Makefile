DC=gdc

DFLAGS=-c -Wall -Wpedantic -Werror -I $(SRCD)
RELEASE=-O3

SRCD=./src
OBJD=./build
OBJ=$(OBJD)/spillocore.o $(OBJD)/lex.o

all : $(OBJ)
	$(DC) -o $(OBJD)/cuci1 $(OBJ)

$(OBJD)/lex.o : $(SRCD)/lex.d
	$(DC) $(DFLAGS) $(SRCD)/lex.d -o $(OBJD)/lex.o

$(OBJD)/spillocore.o : $(SRCD)/spillocore.d
	$(DC) $(DFLAGS) $(SRCD)/spillocore.d -o $(OBJD)/spillocore.o


release :
	$(DC) -o $(OBJD)/cuci1 $(RELEASE) $(SRC_ALL)


.PHONY : clean
clean :
	rm cuci1 $(OBJ)
