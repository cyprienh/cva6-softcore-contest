#include <stdio.h>
#include <stdlib.h>

extern void test(int, long);
extern int f(void);

int main(int argc, char **argv) {
  int i;
  long v;
  printf("f: %p -- %ld\n", f, f);
  printf("|v|: %ld\n", sizeof(v));
  scanf("%d", &i);
  scanf("%ld", &v);
  test(i, v);
  return 1;
}

/*
f: 0x556970fb8244 -- 93911355458116
|v|: 8
-8
93911355458116
function test
function f
function f
*/
