; ========================================
; 程序名称: sum.asm
; 功能: 求 1+2+3+...+100 的和，并显示结果
; 输出: 5050
; ========================================

DATA SEGMENT
DATA ENDS

STACK SEGMENT STACK
    DW 100 DUP(?)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    MOV AX, DATA
    MOV DS, AX
    
    ; ========== 计算 1+2+...+100 ==========
    MOV CX, 100        ; 循环100次
    MOV AX, 0          ; AX存放和
    MOV BX, 1          ; 当前数字
    
SUM_LOOP:
    ADD AX, BX         ; 累加
    INC BX             ; 下一个数
    LOOP SUM_LOOP      
    
    ; 此时 AX = 5050 (十进制)
    
    ; ========== 输出结果 ==========
    CALL OUTPUT_DEC    
    
    ; ========== 换行 ==========
    MOV DL, 0DH        
    MOV AH, 02H
    INT 21H
    MOV DL, 0AH        
    INT 21H
    
    ; ========== 退出 ==========
    MOV AH, 4CH
    INT 21H

; ==========================================
; 子程序: OUTPUT_DEC
; 功能: 将AX中的数值以十进制输出
; 输入: AX = 要输出的数
; ==========================================
OUTPUT_DEC PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10         ; 除数
    XOR CX, CX         ; 计数器清零
    
    ; 特殊处理：如果AX=0
    CMP AX, 0
    JNE DIVIDE_LOOP
    PUSH AX            ; 压入0
    INC CX
    JMP PRINT_LOOP
    
DIVIDE_LOOP:
    XOR DX, DX         ; DX清零
    DIV BX             ; AX÷10，商在AX，余数在DX
    PUSH DX            ; 余数压栈
    INC CX             ; 计数
    CMP AX, 0          ; 商是否为0
    JNE DIVIDE_LOOP    ; 不为0继续
    
PRINT_LOOP:
    POP DX             ; 取出数字
    ADD DL, '0'        ; 转ASCII
    MOV AH, 02H        ; 输出字符
    INT 21H
    LOOP PRINT_LOOP    
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
OUTPUT_DEC ENDP

CODE ENDS
    END START