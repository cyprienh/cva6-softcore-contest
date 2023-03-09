/* #include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>

#include <zephyr/kernel.h> */

#include "ripe_attack_generator.h"

// cd workdir/ && west build -p -b cv32a6_zybo /workdir/test_emily/ && west debug

void* memcpy2(void *destination, const void *source, size_t size ) {
  __asm__(
    "mv t1,a0         \n\t\
    beqz a2,out       \n\t\
    loop:             \n\t\
    lb t2,0(a1)       \n\t\
    sb t2,0(t1)       \n\t\
    addi a2,a2,-1     \n\t\
    addi a1,a1,1     \n\t\
    addi t1,t1,1      \n\t\
    bnez a2,loop      \n\t\
    out:              \n\t\
    " : : : );
}

/* Notes 
lb t2,0(a1) -> non
lb t4,0(ra) -> non
lb t2,0(sp) -> non
lw t2,0(sp) -> non
lw x0,0(sp) -> oui (à 1 près avant/après)
lb x0,0(sp) -> oui (à 1 près avant/après)
ccl: ne dépend pas de lw/lb

lb x0,0(a1) -> non 

nop avant lb -> non

lb a1,0(t2) -> oui ???????????????????????????????

lb a1,0(t2)       
sb a1,0(t1) -> non

lb x0,0(a1)  
sb t2,0(t1)    -> non

lb x0,0(sp)  
sb t2,0(t1)    -> oui

lb x0,0(a1)  
sb t2,0(t1) 
en enlevant le addi a1, a1, 1   -> OUI

ccl: ça marche quand y'a aucune dépendance entre le load et le reste de la boucle 
PLUS PRECISEMENT
il ne faut pas que le lb et sb aient la meme "destination" 
OU il ne faut pas que l'addr en memoire à load soit incrementee dans la boucle
*/


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
  static int r1, r2;
  static int r3, r4;
  static int r5, r6;
  static int r7, r8;
  int length=354;
  
  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 1" : "=r"(r2) : : ); 
  printf("last interval = [%p, %p]\n", r1, r2);

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

  __asm__(".insn u 0x0B, %0, 2" : "=r"(r3) : : ); 
  __asm__(".insn u 0x2B, %0, 3" : "=r"(r4) : : ); 
  printf("interval after memset buffer1 = [%p, %p]\n", r3, r4);

  printf("buffer2: %p\n", buffer2);
  memset(buffer2, 'B', length);

  waste_time();

  __asm__(".insn u 0x0B, %0, 4" : "=r"(r5) : : ); 
  __asm__(".insn u 0x2B, %0, 5" : "=r"(r6) : : ); 
  printf("interval after memset buffer2 = [%p, %p]\n", r5, r6);

  printf("buffer3: %p\n", buffer3);
  memset(buffer3, 'B', length);

  waste_time();

  __asm__(".insn u 0x0B, %0, 6" : "=r"(r7) : : ); 
  __asm__(".insn u 0x2B, %0, 7" : "=r"(r8) : : ); 
  printf("interval after memset buffer3 = [%p, %p]\n", r7, r8);

  memcpy2(buffer1, buffer2, length);
  __asm__(".insn u 0x0B, %0, 10" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 11" : "=r"(r2) : : ); 
  __asm__(".insn u 0x0B, %0, 12" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 13" : "=r"(r2) : : ); 
  __asm__(".insn u 0x0B, %0, 14" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 15" : "=r"(r2) : : ); 
  __asm__(".insn u 0x0B, %0, 102" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 113" : "=r"(r2) : : ); 
  __asm__(".insn u 0x0B, %0, 104" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 119" : "=r"(r2) : : ); 
  
  /*
    Notes
    en enlevant lb                                -> ca marche
    en mettant autre chose à la place de lb (nop) -> ca marche (starts 1 late and stops 1 early ?)
    avec un lw x0,0(a1)                           -> [0x80006fa1, 0x80006faf] ??
    avec un lw x0,0(sp)                           -> ça marche
  */
  
  waste_time();

  __asm__(".insn u 0x0B, %0, 107" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 111" : "=r"(r2) : : ); 
  printf("interval after memcpy = [%p, %p]\n", r1, r2);

  /*
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

  */
  waste_time();
  
  __asm__(".insn u 0x0B, %0, 8" : "=r"(r1) : : ); 
  __asm__(".insn u 0x2B, %0, 9" : "=r"(r2) : : ); 
  printf("interval end of program = [%p, %p]\n", r1, r2);
  printf("--------------END OF PROGRAM----------------\n");
  return 0;
}
