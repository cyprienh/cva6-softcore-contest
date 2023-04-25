#include <zephyr/kernel.h>

int func(int a) {
  printk("Hello world !");
  return a*a;
}

int main() {
  int (*func_ptr)(int) = &func;
  int x = 3;

  int y = (*func_ptr)(x);
  int z = (*func_ptr)(y);
  int w = (*func_ptr)(z);

  return 0;
}
