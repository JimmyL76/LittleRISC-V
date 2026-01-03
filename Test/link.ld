OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
    /* I_MEM: 16KB starting at 0 */
    rom (rx) : ORIGIN = 0x00000000, LENGTH = 16K 
    /* D_MEM: 16KB starting at 16K offset */
    ram (rw) : ORIGIN = 0x00004000, LENGTH = 16K 
}

SECTIONS
{
    .text : { *(.text*) } > rom  
    .data : { *(.data*) } > ram 
    .bss  : { *(.bss*)  } > ram
}