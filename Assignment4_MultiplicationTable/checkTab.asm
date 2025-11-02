data segment
table  db 7,2,3,4,5,6,7,8,9             ;9*9表数据（第1行）
       db 2,4,7,8,10,12,14,16,18        ;第2行
       db 3,6,9,12,15,18,21,24,27       ;第3行
       db 4,8,12,16,7,24,28,32,36       ;第4行
       db 5,10,15,20,25,30,35,40,45     ;第5行
       db 6,12,18,24,30,7,42,48,54      ;第6行
       db 7,14,21,28,35,42,49,56,63     ;第7行
       db 8,16,24,32,40,48,56,7,72      ;第8行
       db 9,18,27,36,45,54,63,72,81     ;第9行
       
msg_error db '  error$'
msg_ok db 'accomplished!$'
msg_x db 'x  y$'
crlf db 0Dh, 0Ah, '$'
data ends

stack segment stack
    dw 100 dup(?)
stack ends

code segment
assume cs:code, ds:data, ss:stack

; 打印字符串过程
print_string proc
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
print_string endp

; 打印单个字符
print_char proc
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
print_char endp

; 打印数字（个位数）
print_digit proc
    push ax
    push dx
    add dl, '0'
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
print_digit endp

; 打印换行
print_newline proc
    push ax
    push dx
    lea dx, crlf
    call print_string
    pop dx
    pop ax
    ret
print_newline endp

; 打印空格
print_space proc
    push dx
    mov dl, ' '
    call print_char
    pop dx
    ret
print_space endp

main proc far
    mov ax, data
    mov ds, ax
    mov ax, stack
    mov ss, ax
    
    ; 打印表头 "x  y"
    lea dx, msg_x
    call print_string
    call print_newline
    
    mov si, 0           ; SI指向table的索引
    mov ch, 1           ; CH = 行号 (1-9)
    
check_outer:
    mov cl, 1           ; CL = 列号 (1-9)
    
check_inner:
    ; 计算正确值：行 * 列
    mov al, ch
    mul cl              ; AX = 行 * 列
    
    ; 读取表中的值
    mov bl, table[si]
    mov bh, 0
    
    ; 比较
    cmp ax, bx
    je correct
    
    ; 发现错误，打印 "行号  列号  error"
    mov dl, ch          ; 打印行号
    call print_digit
    call print_space
    call print_space
    
    mov dl, cl          ; 打印列号
    call print_digit
    
    ; 打印"  error"
    lea dx, msg_error
    call print_string
    call print_newline
    
correct:
    inc si              ; 移动到下一个数据
    inc cl              ; 列号+1
    cmp cl, 10          ; 是否检查完当前行
    jl check_inner
    
    inc ch              ; 行号+1
    cmp ch, 10          ; 是否检查完所有行
    jl check_outer
    
    ; 打印完成信息
    lea dx, msg_ok
    call print_string
    call print_newline
    
    ; 退出程序
    mov ax, 4C00h
    int 21h
    
main endp
code ends
end main