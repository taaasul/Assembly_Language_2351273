#include <stdio.h>

int main() {
    char ch = 'a';      // 对应 MOV BL, 'a'
    int count = 0;      // 对应 MOV BH, 0

    // 对应外层循环
    while (ch <= 'z') { // 对应 CMP BL, 'z'+1 / JE done

        printf("%c ", ch);  // 对应 INT 21H (功能02H)

        ch++;           // 对应 INC BL
        count++;        // 对应 INC BH

        // 对应条件跳转部分
        if (count == 13) {  // 对应 CMP BH, 13 / JNE skip
            printf("\n");   // 对应输出 CRLF
            count = 0;      // 对应 MOV BH, 0
        }
    }

    return 0;
}