#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>

#include <zephyr/kernel.h>

int *f;
void test2() {

}

void test3() {
  
}

int test() {
  int a = test2;
  int r1;
  int r2;
  __asm__(".insn u 0x0B, %0, 0" : "=r"(r1) : : ); 
  //__asm__(".insn i 0x2B, 0, %0, sp, 12" : "=r"(result) : : ); 
  f = &a;
  __asm__(".insn i 0x2B, 0, %0, sp, 100" : "=r"(r2) : : ); 
  printf("result: %p - %p\n", r2, r1);
  return r1;
}

int main() {
  int r2;
  __asm__(".insn u 0x0B, %0, 0" : "=r"(r2) : : ); 
  int r1 = test();
  *f = test3;
  int r3;
  __asm__(".insn u 0x0B, %0, 2000" : "=r"(r3) : : ); 
  
  printf("result: %p - %p - %p\n", r2, r1, r3);
  return 0;
}
