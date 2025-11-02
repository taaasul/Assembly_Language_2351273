data segment
data ends

stack segment stack
    dw 100 dup(?)
stack ends

code segment
assume cs:code, ds:data, ss:stack

; 打印一个数字的过程
print_num proc
    ; 输入：AX = 要打印的数字
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
    
divide_loop:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne divide_loop
    
print_digits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_num endp

; 打印字符过程
print_char proc
    ; 输入：DL = 要打印的字符
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
print_char endp

; 打印换行过程
print_newline proc
    push dx
    mov dl, 0Dh
    call print_char
    mov dl, 0Ah
    call print_char
    pop dx
    ret
print_newline endp

main proc far
    mov ax, data
    mov ds, ax
    
    mov cx, 9           ; 外层循环：i = 1 to 9
    mov bh, 1           ; BH = i
    
outer_loop:
    push cx
    mov bl, 1           ; BL = j
    mov cl, bh          ; 内层循环次数 = i
    
inner_loop:
    push cx
    
    ; 计算 i * j
    mov al, bh
    mul bl              ; AX = i * j
    
    ; 打印 i
    mov al, bh
    mov ah, 0
    call print_num
    
    ; 打印 *
    mov dl, '*'
    call print_char
    
    ; 打印 j
    mov al, bl
    mov ah, 0
    call print_num
    
    ; 打印 =
    mov dl, '='
    call print_char
    
    ; 打印结果
    mov al, bh
    mul bl
    call print_num
    
    ; 打印空格或制表符
    mov dl, 09h         ; TAB
    call print_char
    
    inc bl
    pop cx
    loop inner_loop
    
    call print_newline
    
    inc bh
    pop cx
    loop outer_loop
    
    ; 退出
    mov ax, 4C00h
    int 21h
    
main endp
code ends
end main