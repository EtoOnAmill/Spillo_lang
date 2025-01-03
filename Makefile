DC=gdc
SRCD=./src
DFLAGS=-c -Wall -Wpedantic -Werror -I $(SRCD)
OBJD=./build
OBJ=$(OBJD)/spillocore.o

all : $(OBJ)
	$(DC) -o unin $(OBJ)

release : 
    $(DC) -o unin $(RELEASE) $(SRC_ALL)



.PHONY : clean
clean :
	rm unin $(OBJ)
