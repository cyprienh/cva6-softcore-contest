int *f;
void test2() {

}

void test3() {
  
}

void test() {
  int a = test2;
  f = &a;
}

int main() {
  test();
  printf("attack\n");
  *f = test3;
  printf("finish\n");
  return 0;
}
