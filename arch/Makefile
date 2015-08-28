obj = $(notdir $(OBJS))
dep = $(obj:%.o=%.d)

.PHONY:all
all: $(dep) $(obj)

sinclude $(TOPDIR)/rules.mk
sinclude $(dep)

.PHONY:clean
clean:
	$(Q) -rm *.d* *.o 	
