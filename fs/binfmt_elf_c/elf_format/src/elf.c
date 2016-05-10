#include <stdio.h>

int add (int a, int b)
{
    printf("Numbers are added together.\n");
    return a + b;
}

int main(int argc, char *argv[])
{
    int a, b, ret;

    a = 3;
    b = 4;

    ret = add(a, b);
    printf("Result: %d\n", ret);

    return 0;
}
