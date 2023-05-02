#include <stdio.h>

int g(void) {
  printf("function g\n");
  return 123;
}

int f(void) {
  printf("function f\n");
  return 123;
}

void test(int i, long v) {
  printf("function test\n");
  char m[16];
  int (*fun_ptr)(void);
  fun_ptr = g;
  m[i] = v;
  fun_ptr();
  f();
  //__asm__ volatile ("movq %rax, %rsp");
}
