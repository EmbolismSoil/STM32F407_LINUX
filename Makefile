#定义通用符号
Q = @ 
TypeOfMCU = STM32F40_41xxx
PROJNAME = STM32F407

#定义源码目录
TOPDIR = $(shell pwd)
LIBDIR = $(TOPDIR)/lib/stm32f4_dsp_stdperiph_lib
DRIVER_LIB_DIR = $(LIBDIR)/STM32F4xx_DSP_StdPeriph_Lib/Libraries/STM32F4xx_StdPeriph_Driver
CMSIS_LIB_DIR = $(LIBDIR)/STM32F4xx_DSP_StdPeriph_Lib/Libraries/CMSIS
ARCHDIR = $(TOPDIR)/arch

USERSRC = $(TOPDIR)/src
DRIVER_LIB_SRC = $(DRIVER_LIB_DIR)/src
CMSIS_SRC = $(CMSIS_LIB_DIR)/Device/ST/STM32F4xx/Source/Templates

CROSS_COMPILE = arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar
OBJCOPY = $(CROSS_COMPILE)objcopy

INCLUDE = -I $(TOPDIR)/inc
INCLUDE += -I $(CMSIS_LIB_DIR)/Include
INCLUDE += -I $(DRIVER_LIB_DIR)/inc
INCLUDE += -I $(CMSIS_LIB_DIR)/Device/ST/STM32F4xx/Include

OBJCFLAGS = #--gap-fill=0xff
CFLAGS = $(INCLUDE) -g -O2 -Wall -mcpu=cortex-m4 -mthumb

#编译宏选项
CFLAGS += -D$(TypeOfMCU)
CFLAGS += -DVECT_TAB_FLASH
CFLAGS += -D"assert_parm(expr)=((void)0)"
CFLAGS += -DUSE_STDPERIPH_DRIVER
ARFLAGS = cr
LDFLAGS = -Bstatic -T $(TOPDIR)/ldscripts/$(PROJNAME).lds -N

LIBS = $(LIBDIR)/libstm32.a
LIBS += $(USERSRC)/libapp.a
OBJS := $(ARCHDIR)/startup.o


export

.PHONY:all $(PROJNAME).bin $(PROJNAME).elf $(LIBS) $(OBJS)	
all: $(PROJNAME).bin

$(PROJNAME).bin : $(PROJNAME).elf
	$(OBJCOPY) $(OBJCFLAGS) -O binary $< $@

$(PROJNAME).elf : $(OBJS) $(LIBS)	
	$(LD) $(LDFLAGS) $(OBJS) \
		--start-group $(LIBS) --end-group -o $@

$(OBJS) $(LIBS):
	$(Q) make -C $(dir $@)

.PHONY:clean cleanAll	
cleanAll : clean
	$(Q) -rm $(shell find $(TOPDIR) -name *.d*)
clean:
	 $(Q) -rm $(shell find $(TOPDIR) -name *.o)	
	 $(Q) -rm $(shell find $(TIODIR) -name *.a)
	 $(Q) -rm $(PROJNAME).elf
	 $(Q) -rm $(PROJNAME).bin
