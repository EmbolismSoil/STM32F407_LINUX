#在LINUX下开始一个STM32工程
[TOC]
##一、安装工具
* 安装交叉编译工具链arm-none-eabi
* 安装make
* 安装vim
* 安装git
***
##二、 如何工作
###2.1 需要作的工作
* [下载stm32固件库](http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stm32f4_dsp_stdperiph_lib.zip)
* 编写连接器脚本
* 编写makefile

###2.2 工作分析
####2.2.1 makefile分析
当我们开发STM32时，会有两部分源码，一部分是由意法半导体提供的固件库，一部分是我们自己编写的用户层代码。 在开发过程中，除非我们进行版本更新否则固件库是不会改变的。而用户代码是会在开发过程当中增删减的。这样，我们可以首先把不变的固件库编译成静态库，之后的每次编译过程中只需要编译用户代码然后再把已经编译好的固件静态库链接进来就可以了，这样做可以大大节省编译时间，因为固件库结构本身是比较庞大和复杂的。

####2.2.2 链接器脚本分析
在总控makefile编译完用户代码之后，就会将静态固件库链接进来，形成最终的镜像文件。这个链接过程由是链接器脚本控制完成的。
连接器脚本主要是用于安排不同代码段在内存中的位置的，程序中的段属性可以大致分为只读的代码段(.textd段)和可读可写的数据段(.data段和.bss段)。而在嵌入式微控制器中，内存也主要分为两种：只读的FLASH和可读可写的RAM。我们可以把代码段放到FLASH中，而数据段放到RAM中。当然，如果RAM空间足够大的话，我们可以把整个镜像都放到RAM里面去。这里需要解释一下，一般来说我们烧录程序是烧录到FLASH内的，而不是RAM内，因为RAM是掉电易失的，而FLASH为非易失储存器。如果代码烧录到RAM内，在关机之后代码就没了。所以我们需要把整个镜像烧录到FLASH内，而后在BOOT阶段再拷贝那些原本被链接器安排到RAM的代码段拷贝到RAM里面去。总而言之，链接器脚本主要完成的工作是：安排好不同.o文件不同段所在的位置，并且解决符号引用问题。
*(注：关于链接的详细介绍，可以看我的[另外一篇博文](http://www.hainter.com/clinker))*

###2.3 分析结果
我们的工程应该需要编写：
* 负责固件库编译的makefile
* 负责用户代码编译和链接生成最终镜像的makefile
* 负责链接过程中安排各个程序段的链接器脚本

##三、开始工作
###3.1 创建文工程目录
工程目录结构如图所示
<pre>|---project
     |---arch
     |---debug
     |---doc
     |---include
     |---ldscripts
     |---lib
     |---OS
     |---src
</pre>

下载固件库到lib文件夹中去并且解压备用
<pre>  cd lib
  wget www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stm32f4_dsp_stdperiph_lib.zip
  unzip stm32f4_dsp_stdperiph_lib.zip -d stm32f4_dsp_stdperiph_lib</pre>

###3.2 编写连接器脚本
首先创建一个.lds文件并且编辑之
<pre>  cd ldscripts/ && touch STM32F407.lds && vim STM32F407.lds</pre>

定义机器架构为ARM，入口符号为Reset_Handler
<pre>  1 OUTPUT_ARCH(arm)
  2 ENTRY(Reset_Handler)
</pre>

定义RAM区和FLASH区的起始地址与长度
<pre>  3 MEMORY
  4 {
  5         RAM : ORIGIN = 0x20000000, LENGTH = 112K
  6         FLASH : ORIGIN = 0x08000000, LENGTH = 1M
  7 }
  8 
</pre>

定义各个段的位置。
为了加快程序运行速度，将中断向量表所在的isr段放到flash内，其他所有段都放到RAM内。并且安排整个镜像的加载地址是连续摆放的，这样可以避免镜像中出现空洞
<pre>   9 SECTIONS
  10 {
  11         . = ALIGN(4);
  12          
  13         .isr_vectors :
  14         {
  15                 KEEP(\*(.isr_vectors))
  16                 . = ALIGN(4);
  17                 _eisr = .;
  18         } > FLASH
  19                 
  20         .text : AT (_eisr) 
  21         { 
  22                 _stext = .;
  23                \*(.text)
  24                 . = ALIGN(4);
  25                 _etext = .;
  26         } > RAM
  27                 
  28         .data : AT (__eisr+SIZEOF(.text))
  29         { 
  30                 _sdata = .;
  31                 \*(.data\*)
  32                 . = ALIGN(4);
  33                 _edata = .;
  34         } > RAM 
  35  
  36         .bss : 
  37         {
  38                 . = ALIGN(4);
  39                 _sbss = .;
  40                 \*(.bss)
  41                 . = ALIGN(4);
  42                 _ebss = .;
  43         } > RAM
  44  
  45         .stack :
  46         {
  47                 . = ALIGN(4);
  48                 _sstack = .;
  49                 \*(.stack);
  50                 . = ALIGN(4);
  51                 _estack = .;
  52         } > RAM
  53 }
</pre>

###3.3 编写Makefile
整个工程目录下，只有src、lib、arch三个子目录下有于源文件需要编译。为了结构层次清晰明了，这里采用总控Makefile配合各个源码子目录下Makefile的方式来完成整个编译过程。所以整个工程内一共有四份Makefile：
* 工程根目录下的总控Makefile
* src、lib、arch 子目录下的Makefile

在开始编写之前，先在工程目录和src、lib、arch目录下分别都创建一个名为Makefile的文件,再在工程目录下创建一个rules.mk文件，用于提炼四个Makefile文件中的相同代码。
<pre>  cd project && touch Makefile src/Makefile lib/Makefile arch/Makefile</pre>

####3.3.1 总控Makfile
总控Makefile的主要职责是定义所有Makefile都要使用到的全局变量，并且控制各个子目录下的Makefile行为。
<pre>  1 #定义通用符号
  2 Q = @
  3 TypeOfMCU = STM32F40_41xxx
  4 PROJNAME = STM32F407
  5 
</pre>
定义各个通用符号，Q = @表示编译过程中执行的命令不显示出来。TypeOfMCU定义了处理器系列。PROJNAME则为工程名字。
<pre>  6 #定义源码目录
  7 TOPDIR = $(shell pwd)
  8 LIBDIR = $(TOPDIR)/lib/stm32f4_dsp_stdperiph_lib
  9 DRIVER_LIB_DIR = $(LIBDIR)/STM32F4xx_DSP_StdPeriph_Lib/Libraries/STM32F4xx_StdPeriph_Driver
  10 CMSIS_LIB_DIR = $(LIBDIR)/STM32F4xx_DSP_StdPeriph_Lib/Libraries/CMSIS
  11 ARCHDIR = $(TOPDIR)/arch
  12
  13 USERSRC = $(TOPDIR)/src
  14 DRIVER_LIB_SRC = $(DRIVER_LIB_DIR)/src
  15 CMSIS_SRC = $(CMSIS_LIB_DIR)/Device/ST/STM32F4xx/Source/Templates
</pre>

为了方便起见，这里定义了各个源码目录，以免每次都要重写各个路径。
<pre>
  16 #定义交叉编译器
  17 CROSS_COMPILE = arm-none-eabi-
  18 CC = $(CROSS_COMPILE)gcc
  19 LD = $(CROSS_COMPILE)ld
  20 AR = $(CROSS_COMPILE)ar
  21 OBJCOPY = $(CROSS_COMPILE)objcopy
</pre> 

这里需要定义交叉编译器，一来方便读写，二来可以方便以后拓展，如果换到其它的编译器，只需要在这里修改即可。
<pre>
  23 INCLUDE = -I $(TOPDIR)/inc
  24 INCLUDE += -I $(CMSIS_LIB_DIR)/Include
  25 INCLUDE += -I $(DRIVER_LIB_DIR)/inc
  26 INCLUDE += -I $(CMSIS_LIB_DIR)/Device/ST/STM32F4xx/Include
  27 
  28 OBJCFLAGS = --gap-fill=0xff
  29 CFLAGS = $(INCLUDE) -g -O2 -Wall -mcpu=cortex-m4 -mthumb
  30 
  31 #编译宏选项
  32 CFLAGS += -D$(TypeOfMCU)
  33 CFLAGS += -DVECT_TAB_FLASH
  34 CFLAGS += -D"assert_parm(expr)=((void)0)"
  35 CFLAGS += -DUSE_STDPERIPH_DRIVER
  36 ARFLAGS = cr
  37 LDFLAGS = -Bstatic -T $(TOPDIR)/ldscripts/$(PROJNAME).lds -N
  38
</pre>

以上定义了编译选项、链接选项，格式转化选项。因为在这个工程里大量使用了GNU make的隐含依赖链，所以编译选项必须定义为CFLAGS。
<pre>  39 LIBS = $(LIBDIR)/libstm32.a
  40 LIBS += $(USERSRC)/libapp.a
  41 OBJS := $(ARCHDIR)/startup.o
  42
  43</pre>
  
这三句定义了lib、src、arch目录下的Makefile生成的目标。总控Makefile通过控制执行各个子目录下的Makefile从而得到这三个目标，最后将这三个目标链接形成最终的镜像。
<pre>  44 export
  45 
  46 .PHONY:all $(PROJNAME).bin $(PROJNAME).elf $(LIBS) $(OBJS)</pre>
  
第44行的export将所有定义的变量导出，以便各个子目录的Makefile使用。第46行则定义了将各个目标声明为伪目标，从而能地在每次执行make时强制检测检测各个子目录下的依赖关系变化。
<pre>  47 all: $(PROJNAME).bin
  48 
  49 $(PROJNAME).bin : $(PROJNAME).elf
  50         $(OBJCOPY) $(OBJCFLAGS) @@bodylt; $@
  51 
  52 $(PROJNAME).elf : $(OBJS) $(LIBS)
  53         $(LD) $(LDFLAGS) $(OBJS) \
  54                 --start-group $(LIBS) --end-group -o $@
  55 
  56 $(OBJS) $(LIBS):
  57         $(Q) make -C $(dir $@)
  58 
</pre>  

总控Makefile最终生成的目标是$(PROJNAME).bin这个二进制镜像文件，该文件由$(PROJNAME).elf通过格式转化得来。而$(PROJNAME).elf则由$(OBJS) $(LIBS)通过链接得到。$(OBJS)和$(LIBS)都由相应子目录下的Makefile生成。
####3.3.2 src子目录Makefile
src/Makefile的唯一任务就是将src下的所有.c文件编译成为一个静态库libapp.a。具体代码如下：
<pre>  1 SRC = $(wildcard $(USERSRC)/*.c)
  2 
  3 OBJ = $(SRC:%.c=%.o)
  4 DEP = $(SRC:%.c=%.d)
  5 
  6 .PHONY:libapp.a
  7 libapp.a : $(DEP) $(OBJ)
  8         $(AR) $(ARFLAGS) $(USERSRC)/$@ $(OBJ)
  9 
 10 sinclude $(TOPDIR)/rules.mk
 11 sinclude $(DEP)
</pre> 

该Makefile比较简单，唯一需要说明的是第10行和第11行。第10行包含了工程目录下的rules.mk文件，第11行则包含了所有与每个.c文件对应的.d文件。rules.mk用于生成.d文件，rules.mk会为每个.c文件生成其对应的.d文件，.d文件记录了利用.c文件编译成.o文件的依赖关系。.o文件由GNU Make的隐含规则根据.d文件中的依赖关系编译生成,而最终生成libapp.a时只需要将所有.o文件打包即可。rules.mk代码如下：
<pre>  1 %.d : %.c
  2         $(Q) set -e;rm -f $@;\
  3         $(CC) -MM $(CFLAGS) @@bodylt; > $@.$$;\
  4                 sed 's/\($(notdir $*)\)\.o[ :]*/\1.o $(notdir $@) : /g' < $@.$$     > $@;\
  5                 rm -f $@.$$
</pre>

第3行利用gcc -MM自动推导了每个.c文件的依赖关系，并且写入.d.（随机数）这个临时文件中，依赖关系的格式为 xxx.o : xxx.c xxx.h yyy.h zzz.h…。第4行则在前面生成的依赖关系的目标中将对应的.d添加进去。并且将修改后的依赖关系写入.d文件中，最终格式为 xxx.c xxx.d : xxx.c xxx.h yyy.h zzz.h,这样做是为了能让.d文件在检测到.c或者.h文件变化时能够自动更新。这样，.d内记录的依赖关系就可以用来生成.o文件了。
####3.3.3 arch子目录Makefile
arch子目录下的Makefile与src/Makefile原理上一致，这里不做分析地列出代码如下：
<pre>
  1 obj = $(notdir $(OBJS))
  2 dep = $(obj:%.o=%.d)
  3 
  4 .PHONY:all
  5 all: $(dep) $(obj)
  6 
  7 sinclude $(TOPDIR)/rules.mk
  8 sinclude $(dep)</pre>
  
####3.3.4 lib子目录Makefile
arch子目录下的Makefile与src/Makefile原理上一致，这里不做分析地列出代码如下：
<pre>  1 LIBSRC = $(wildcard $(DRIVER_LIB_SRC)/*.c)
  2 LIBSRC += $(wildcard $(CMSIS_SRC)/*.c)
  3 
  4 LIBOBJ = $(LIBSRC:%.c=%.o)
  5 LIBDEP = $(LIBSRC:%.c=%.d)
  6 
  7 libstm32.a: $(LIBDEP) $(LIBOBJ)
  8         $(Q) $(AR) $(ARFLAGS) $(LIBDIR)/$@ $(LIBOBJ)
  9 
 11 sinclude $(LIBDEP)</pre>

####3.3.5 Makefile总结
该工程下的GNU make文件一共有五分，包括四份Makefile和一份rules.mk，其中工程目录下的Makefile作为总控Makefile，其它Makefile作为子Makefile被总控Makefile控制执行。每个Makefile的责任都是生成一个子模块，而总控Makefile的责任是将所有子模块链接成为最终的镜像文件。当用户在工程目录下键入一个make并且摁下回车键时，总控Makefile依次控制进入各个子目录并且在子目录下执行make指令，每个子目录下执行make指令时，会调用rules.mk生成.d文件，再根据.d文件描述的依赖关系去将该目录下的所有.c文件编译成.o文件，最后利用.o文件生成该子Makefile负责的模块。当所有子目录下的make指令都成功执行后，得到startup.o libapp.a libstm32.a三个模块，总控Makefile这时通过LD将三个模块链接，并且进行格式转化，就得到了最终的.bin镜像。
