SRC = $(wildcard $(USERSRC)/*.c)

OBJ = $(SRC:%.c=%.o)
DEP = $(SRC:%.c=%.d)

all : $(DEP) $(OBJ)

sinclude $(TOPDIR)/rules.mk
sinclude $(LIBDEP)
