#include <stdio.h>

int main() {
    char ch = 'a';      // ��Ӧ MOV BL, 'a'
    int count = 0;      // ��Ӧ MOV BH, 0

    // ��Ӧ���ѭ��
    while (ch <= 'z') { // ��Ӧ CMP BL, 'z'+1 / JE done

        printf("%c ", ch);  // ��Ӧ INT 21H (����02H)

        ch++;           // ��Ӧ INC BL
        count++;        // ��Ӧ INC BH

        // ��Ӧ������ת����
        if (count == 13) {  // ��Ӧ CMP BH, 13 / JNE skip
            printf("\n");   // ��Ӧ��� CRLF
            count = 0;      // ��Ӧ MOV BH, 0
        }
    }

    return 0;
}