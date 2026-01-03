.section .text
.global _start

_start:
    # set sp to top of memory
    # FPGA mem is 32KB with 4K words, stack is in bytes so still 32K
    li sp, 0x00008000 

    call main

    # 3. if main ever returns, stay in an infinite loop
_park:
    j _park
