#include <stdio.h>
#include <dos.h>

void interrupt(*old_int4)();

void interrupt new_int4()
{
    printf("Overflow!\n");
}

void test_overflow()
{
    char a, b, c;
    a = 127;
    b = 1;

    printf("Testing: 127 + 1\n");

    asm mov al, a
        asm add al, b
        asm mov c, al
        asm into

        printf("Result = %d\n", c);
}

void test_no_overflow()
{
    char a, b, c;
    a = 10;
    b = 20;

    printf("Testing: 10 + 20\n");

    asm mov al, a
        asm add al, b
        asm mov c, al
        asm into

        printf("Result = %d\n", c);
}

int main()
{
    old_int4 = getvect(4);
    setvect(4, new_int4);

    test_no_overflow();
    test_overflow();

    setvect(4, old_int4);
    return 0;
}