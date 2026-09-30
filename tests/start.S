.section .text.init
.global _start

_start:
    # Initialize Stack Pointer (sp) at 0x0FF0, not at top of data memory.
    # This is so, we have some space to write PASS/FAIL status codes to be polled by tb_top.v
    la sp, __stack_top

    # Clear the .bss section to zero out initialized global variables/static variables.
    la t0, __bss_start
    la t1, __bss_end

bss_loop:
    bge t0, t1, bss_done   
    sw zero, 0(t0)         
    addi t0, t0, 4         
    j bss_loop

bss_done:
    call main

end_loop:
    j end_loop

