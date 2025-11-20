STACK SEGMENT PARA STACK
    DW 128 DUP(0)
STACK ENDS

DATA SEGMENT
    MSG_OVERFLOW DB 0DH, 0AH, 'Overflow Error!', 0DH, 0AH, '$'
    MSG_START DB 'Program Start...', 0DH, 0AH, '$'
    MSG_END DB 'Program End.', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK
    
START:
    MOV AX, DATA
    MOV DS, AX
    
    MOV AH, 09H
    LEA DX, MSG_START
    INT 21H
    
    ; 保存原INT4中断向量
    MOV AH, 35H
    MOV AL, 04H
    INT 21H
    PUSH ES
    PUSH BX
    
    ; 设置新的INT4中断向量
    PUSH CS
    POP DS
    MOV AH, 25H
    MOV AL, 04H
    MOV DX, OFFSET NEW_INT4
    INT 21H
    
    MOV AX, DATA
    MOV DS, AX
    
    ; 测试溢出 - 不用JO/JNO
    MOV AL, 7FH
    MOV BL, 02H
    ADD AL, BL
    INTO             ; ← 直接INTO，自动触发中断
    
    ; 恢复原中断向量
    POP DX
    POP DS
    MOV AH, 25H
    MOV AL, 04H
    INT 21H
    
    MOV AX, DATA
    MOV DS, AX
    MOV AH, 09H
    LEA DX, MSG_END
    INT 21H
    
    MOV AH, 4CH
    INT 21H

NEW_INT4 PROC
    PUSH AX
    PUSH DX
    PUSH DS
    
    MOV AX, DATA
    MOV DS, AX
    MOV AH, 09H
    LEA DX, MSG_OVERFLOW
    INT 21H
    
    POP DS
    POP DX
    POP AX
    IRET
NEW_INT4 ENDP

CODE ENDS
    END START