OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{

  imem (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  dmem (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
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

  /* Top of 4KB DMEM (0x1000 bytes) minus 16-byte alignment offset = 0x0FF0 */
  __stack_top = ORIGIN(dmem) + LENGTH(dmem) - 16;
}