%.d : %.c
	$(Q) set -e;rm -f $@;\
	$(CC) -MM $(CFLAGS) $< > $@.$$$$;\
		sed 's/\($(notdir $*)\)\.o[ :]*/\1.o $(notdir $@) : /g' < $@.$$$$ > $@;\
		rm -f $@.$$$$
