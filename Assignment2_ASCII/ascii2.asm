.model small
.stack 100h
.data
    crlf db 0dh, 0ah, '$'

.code
main proc
    mov ax, @data
    mov ds, ax
    
    mov bl, 'a'         ; 当前字符
    mov bh, 0           ; 行内计数
    
print_loop:
    cmp bl, 'z'+1       ; 是否超过'z'？
    je done             ; 是，结束
    
    ; 输出当前字符
    mov dl, bl
    mov ah, 02h
    int 21h
    
    ; 输出空格
    mov dl, ' '
    int 21h
    
    inc bl              ; 下一个字母
    inc bh              ; 行内计数+1
    
    cmp bh, 13          ; 是否13个？
    jne print_loop      ; 不是，继续
    
    ; 输出换行
    push dx
    lea dx, crlf
    mov ah, 09h
    int 21h
    pop dx
    
    mov bh, 0           ; 重置计数
    jmp print_loop
    
done:
    mov ah, 4ch
    int 21h
    
main endp
end main