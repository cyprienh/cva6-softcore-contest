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
  *f = test3;
  return 0;
}
