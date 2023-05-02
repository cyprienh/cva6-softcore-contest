all:
	g++ -g -fno-rtti -I`gcc -print-file-name=plugin`/include -fpic -shared -o plugin.so plugin.c
	gcc -fdump-tree-ssa -freport-bug -O0 -fplugin=./plugin.so -g -fdump-tree-optimized test.c -c
	#objdump -D test | grep -A16 '<test>'
	gcc -g -Wall -o main test.o main.c

main_orig: main.c test.c
	gcc -g -Wall -o main_orig main.c test.c
