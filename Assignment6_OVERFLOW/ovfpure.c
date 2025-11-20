#include <stdio.h>
#include <dos.h>

void interrupt(*old_int4)();

void interrupt new_int4()
{
    printf("Overflow!\n");
}

int main()
{
    char a, b, result;

    old_int4 = _dos_getvect(4);
    _dos_setvect(4, new_int4);

    /* 测试1: 127 + 1 = 溢出 */
    a = 127;
    b = 1;
    printf("Test: %d + %d\n", a, b);

    asm mov al, a
        asm add al, b
        asm mov result, al
        asm into

        printf("Result = %d\n", result);

    _dos_setvect(4, old_int4);
    return 0;
}