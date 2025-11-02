DATA SEGMENT
    PROMPT DB 'Please enter a number (1-100): $'
    RESULT DB 0DH, 0AH, 'Sum = $'
    NUM DW ?           ; 存储用户输入的数
    SUM DW 0           ; 存储求和结果
    TEMP DW ?          ; 临时变量
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA
    
START:
    MOV AX, DATA
    MOV DS, AX
    
    ; 显示提示信息
    LEA DX, PROMPT
    MOV AH, 09H
    INT 21H
    
    ; 接收用户输入（十进制数）
    CALL INPUT_DEC     ; 调用输入十进制数的子程序
    MOV NUM, AX        ; 保存输入的数到NUM
    
    ; 计算求和 1+2+...+NUM
    MOV CX, NUM        ; CX作为循环计数器
    MOV BX, 0          ; BX存储累加和
    MOV AX, 1          ; AX从1开始
    
SUM_LOOP:
    ADD BX, AX         ; 累加
    INC AX             ; AX++
    LOOP SUM_LOOP      ; CX--, 如果CX!=0则继续循环
    
    MOV SUM, BX        ; 保存结果
    
    ; 显示结果提示
    LEA DX, RESULT
    MOV AH, 09H
    INT 21H
    
    ; 输出十进制结果
    MOV AX, SUM
    CALL OUTPUT_DEC    ; 调用输出十进制数的子程序
    
    ; 程序结束
    MOV AH, 4CH
    INT 21H

;=====================================================
; 子程序：INPUT_DEC - 输入十进制数
; 输出：AX = 输入的十进制数
;=====================================================
INPUT_DEC PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 0          ; BX存储结果
    
INPUT_LOOP:
    MOV AH, 01H        ; 读取一个字符
    INT 21H
    
    CMP AL, 0DH        ; 是否为回车键
    JE INPUT_END
    
    SUB AL, 30H        ; ASCII转数字
    MOV CL, AL
    MOV CH, 0
    
    MOV AX, BX         ; AX = BX
    MOV DX, 10
    MUL DX             ; AX = BX * 10
    ADD AX, CX         ; AX = BX * 10 + 新数字
    MOV BX, AX         ; BX = 新结果
    
    JMP INPUT_LOOP
    
INPUT_END:
    MOV AX, BX         ; 返回结果
    
    POP DX
    POP CX
    POP BX
    RET
INPUT_DEC ENDP

;=====================================================
; 子程序：OUTPUT_DEC - 输出十进制数
; 输入：AX = 要输出的十进制数
;=====================================================
OUTPUT_DEC PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0          ; CX计数，记录位数
    MOV BX, 10         ; 除数
    
DIVIDE_LOOP:
    MOV DX, 0
    DIV BX             ; AX / 10, 商在AX，余数在DX
    PUSH DX            ; 余数入栈
    INC CX             ; 位数+1
    
    CMP AX, 0          ; 商是否为0
    JNE DIVIDE_LOOP    ; 不为0继续除
    
PRINT_LOOP:
    POP DX             ; 取出一位数字
    ADD DL, 30H        ; 转换为ASCII
    MOV AH, 02H        ; 显示字符
    INT 21H
    LOOP PRINT_LOOP    ; CX--, 继续输出
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
OUTPUT_DEC ENDP

CODE ENDS
END START