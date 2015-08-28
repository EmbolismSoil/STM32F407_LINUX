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

CROSS_COMPILE = arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar

INCLUDE = -I $(TOPDIR)/inc
INCLUDE += -I $(CMSIS_LIB_DIR)/Include
INCLUDE += -I $(DRIVER_LIB_DIR)/inc
INCLUDE += -I $(CMSIS_LIB_DIR)/Device/ST/STM32F4xx/Include

OBJCFLAGS = --gap-fill = 0xff
CFLAGS = $(INCLUDE) -g -O2 -Wall -mcpu=cortex-m4 -mthumb

#编译宏选项
CFLAGS += -D$(TypeOfMCU)
CFLAGS += -DVECT_TAB_FLASH
CFLAGS += -D"assert_parm(expr)=((void)0)"
CFLAGS += -DUSE_STDPERIPH_DRIVER


LIBS = libstm32.a
LIBS += libapp.a
OBJS := $(ARCHDIR)/startup.o

export

.PHONY:all	
all: $(PROJNAME).bin
$(PROJNAME).bin : $(OBJS) $(LIBS)


$(LIBS):
	make -C $(DRIVER_LIB_SRC)
	make -C $(USERSRC)
$(OBJS):
	echo OBJS = $(OBJS)
	make -C $(ARCHDIR)
