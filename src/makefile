SRC = $(wildcard $(USERSRC)/*.c)

OBJ = $(SRC:%.c=%.o)
DEP = $(SRC:%.c=%.d)

.PHONY:libapp.a
libapp.a : $(DEP) $(OBJ)
	$(AR) $(ARFLAGS) $(USERSRC)/$@ $(OBJ)

sinclude $(TOPDIR)/rules.mk
sinclude $(DEP)
