/* #include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>

#include <zephyr/kernel.h> */

#include "ripe_attack_generator.h"


int ret2libc_target() {
  printf("\n La mort pour toujours");
  while(1);
  return 0;
}

int waste_time() {
  int index=0;

  while(index < 10) {
    index++;
    printf("- ", index);
  }
  printf("\n");
  return 0;
}


int main() {
  printf("--------------BEGIN TEST----------------\n");
  static int r1, r2, act;
  int length=32;
  
  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 0" : "=r"(r2) : : ); 
  printf("last interval = [%p, %p]\n", r1, r2);


  /*
  int (*stack_func_ptr)(const char *);
  char stack_buffer1[length];
  static char * buffer1;
  char stack_buffer2[length];
  static char * buffer2;
  char stack_buffer3[length];
  static char * buffer3;

  buffer1 = stack_buffer1;
  buffer2 = stack_buffer2;
  buffer3 = stack_buffer3;

  
  printf("buffer1: %p\n", buffer1);
  memset(buffer1, 'A', length);

  waste_time();

  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 0" : "=r"(r2) : : ); 
  printf("interval after memset buffer1 = [%p, %p]\n", r1, r2);

  printf("buffer2: %p\n", buffer2);
  memset(buffer2, 'B', length);

  waste_time();

  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 0" : "=r"(r2) : : ); 
  printf("interval after memset buffer2 = [%p, %p]\n", r1, r2);

  printf("buffer3: %p\n", buffer3);
  memset(buffer3, 'B', length);

  waste_time();

  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 0" : "=r"(r2) : : ); 
  printf("interval after memset buffer3 = [%p, %p]\n", r1, r2);

  memcpy(buffer1, buffer2, length);
  
  waste_time();

  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 0" : "=r"(r2) : : ); 
  printf("interval after memcpy = [%p, %p]\n", r1, r2);
  
  wes
  */
  __asm__(".insn s 0x23, 0, a4, 0(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 1(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 2(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 3(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 4(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 5(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 6(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 7(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 8(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 9(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 10(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 11(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 12(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 13(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 14(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 15(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 16(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 17(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 18(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 19(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 20(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 21(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 22(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 23(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 24(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 25(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 26(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 27(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 28(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 29(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 30(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 31(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 32(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 33(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 34(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 35(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 36(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 37(fp)" :  :  : ); 
  __asm__(".insn s 0x23, 0, a4, 38(fp)" :  :  : ); 

  //__asm__("jalr zero, 25(fp)" :  :  : );


  waste_time();
  
  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 0" : "=r"(r2) : : ); 
  printf("interval end of program = [%p, %p]\n", r1, r2);
  printf("--------------END OF PROGRAM----------------\n");
  return 0;
}
