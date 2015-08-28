LIBSRC = $(wildcard $(DRIVER_LIB_SRC)/*.c)
LIBSRC += $(wildcard $(CMSIS_SRC)/*.c)

LIBOBJ = $(LIBSRC:%.c=%.o)
LIBDEP = $(LIBSRC:%.c=%.d)

libstm32.a: $(LIBDEP) $(LIBOBJ)
	$(Q) $(AR) $(ARFLAGS) $(LIBDIR)/$@ $(LIBOBJ)

sinclude $(TOPDIR)/rules.mk
sinclude $(LIBDEP)
