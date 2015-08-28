OUTPUT_ARCH(arm)
ENTRY(Reset_Handler)
MEMORY
{
	RAM : ORIGIN =   0x20000000, LENGTH = 112K
	FLASH : ORIGIN = 0x08000000, LENGTH = 1M 
}

SECTIONS
{
	. = ALIGN(4);

	.isr_vectors : 
	{		
		KEEP(*(.isr_vectors))
		. = ALIGN(4);
		_eisr = .;
	} > FLASH

	.text : AT (_eisr) 
	{
		_stext = .;
		*(.text*)
		. = ALIGN(4);
		_etext = .;
	} > RAM
	
	.data : AT (_eisr + SIZEOF(.text))
	{
		_sdata = .;
		*(.*data*)
		. = ALIGN(4);
		_edata = .;
	} > RAM

	.bss : 
	{
		. = ALIGN(4);
		_sbss = .;
		*(.bss)
		. = ALIGN(4);
		_ebss = .;
	} > RAM

	.stack : 
	{
		. = ALIGN(4);
		_sstack = .;
		*(.stack);
		. = ALIGN(4);
		_estack = .;
	} > RAM	
}
