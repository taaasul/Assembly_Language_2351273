.model small
.stack 100h
.data
    crlf db 0dh, 0ah, '$'    ; 回车换行

.code
main proc
    mov ax, @data
    mov ds, ax
    
    mov cx, 26          ; 外层循环：26个字母
    mov bl, 'a'         ; 起始字符 'a'
    mov bh, 0           ; 行内计数器
    
outer_loop:
    push cx             ; 保存外层CX
    
    mov dl, bl          ; 要输出的字符
    mov ah, 02h         ; DOS功能：输出字符
    int 21h
    
    mov dl, ' '         ; 输出空格
    int 21h
    
    inc bl              ; 下一个字母
    inc bh              ; 行内计数+1
    
    cmp bh, 13          ; 是否达到13个？
    jne skip_newline
    
    ; 输出回车换行
    push dx
    lea dx, crlf
    mov ah, 09h
    int 21h
    pop dx
    
    mov bh, 0           ; 重置行内计数
    
skip_newline:
    pop cx              ; 恢复外层CX
    loop outer_loop
    
    ; 程序结束
    mov ah, 4ch
    int 21h
    
main endp
end main