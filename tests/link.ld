OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  imem (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
  dmem (rwx) : ORIGIN = 0x00000000, LENGTH = 32K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text*)
  } > imem

  .rodata : {
    . = ALIGN(4);
    *(.rodata*)
  } > dmem

  .data : {
    . = ALIGN(4);
    *(.data*)
  } > dmem

  .bss : {
    . = ALIGN(4);
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > dmem

  /*
       0x7FF8          failing TESTNUM (riscv-tests)
       0x7FFC          PASS(1)/FAIL(2) signature polled by tb_top.v          */

  __stack_top = ORIGIN(dmem) + LENGTH(dmem) - 16;
  __signature = ORIGIN(dmem) + LENGTH(dmem) - 4;   /* 0x7FFC */

}
