.MODEL SMALL              ; 小内存模型
.STACK 100h               ; 堆栈大小256字节

.DATA
    ; ========== 游戏数据 ==========
    snakeX dw 200 dup(0)    ; 蛇身X坐标数组（最多200节）
    snakeY dw 200 dup(0)    ; 蛇身Y坐标数组
    snakeLength dw 3        ; 蛇的初始长度
    direction db 1          ; 当前方向：0=上, 1=右, 2=下, 3=左
    nextDirection db 1      ; 下一个方向（用于平滑转向）
    
    ; ========== 食物位置 ==========
    foodX dw 0              ; 食物X坐标
    foodY dw 0              ; 食物Y坐标
    
    ; ========== 游戏状态 ==========
    gameOver db 0           ; 游戏结束标志（0=进行中, 1=结束）
    score dw 0              ; 当前分数
    gameSpeed db 8          ; 游戏速度（延迟循环次数，数值越大越慢）
    
    ; ========== 中断向量保存 ==========
    oldInt09h dd 0          ; 保存原INT 09h中断向量（用于恢复）
    
    ; ========== 游戏提示消息 ==========
    welcomeMsg db "========================================$"
    titleMsg db "   Snake Game (Assembly Language)   $"
    separator db "========================================$"
    instruction1 db "Use Arrow Keys (Up/Down/Left/Right) to control$"
    instruction2 db "Eat food (#) to grow and score points$"
    instruction3 db "Press ESC to exit game$"
    instruction4 db "Press SPACE to start game$"
    gameOverMsg db "GAME OVER!$"
    scoreMsg db "Score: $"
    pressKeyMsg db "Press any key to exit...$"
    
.CODE
    ; ========== 中断处理程序数据（必须在代码段中） ==========
    oldInt09hTSR dd 0       ; 保存原键盘中断向量（TSR模式）
    directionTSR db 1      ; 方向变量（供中断处理程序使用）
    escPressed db 0         ; ESC键按下标志
    lastKeyProcessed db 0   ; 上次处理的按键（防抖，避免重复响应）

; ========== 主程序入口 ==========
MAIN PROC
    mov ax, @data           ; 初始化数据段寄存器
    mov ds, ax
    
    call showWelcome        ; 显示欢迎界面和操作说明
    
    call waitForStart       ; 等待用户按空格键开始游戏
    
    call initGame           ; 初始化游戏数据（蛇的位置、食物等）
    
    call installKeyboardInterrupt  ; 安装键盘中断处理程序（INT 09h）
    
    ; ========== 游戏主循环 ==========
gameMainLoop:
    cmp gameOver, 1         ; 检查游戏是否结束
    je endGame
    
    cmp cs:escPressed, 1    ; 检查是否按下ESC键
    je endGame
    
    ; ========== 从中断处理程序获取最新方向 ==========
    mov al, cs:directionTSR
    mov direction, al
    mov nextDirection, al
    
    call moveSnake          ; 根据方向移动蛇
    
    call checkCollision     ; 检查是否撞墙或撞到自己
    
    call checkFood          ; 检查是否吃到食物，如果吃到则增长并生成新食物
    
    call drawGame           ; 绘制游戏画面（蛇、食物、分数）
    
    call gameDelay          ; 延迟控制游戏速度
    
    jmp gameMainLoop        ; 继续下一帧
    
endGame:
    call uninstallKeyboardInterrupt  ; 恢复原键盘中断向量
    
    call showGameOver       ; 显示游戏结束界面和最终分数
    
    mov ah, 00h             ; 等待用户按键
    int 16h
    
    mov ah, 4ch             ; 退出程序，返回DOS
    int 21h
    
MAIN ENDP

; ========== 显示欢迎界面 ==========
showWelcome PROC
    call clearScreen        ; 清屏
    call newLine
    lea dx, welcomeMsg     ; 显示分隔线
    call printString
    call newLine
    lea dx, titleMsg        ; 显示游戏标题
    call printString
    call newLine
    lea dx, separator
    call printString
    call newLine
    call newLine
    
    ; 显示操作说明
    lea dx, instruction1
    call printString
    call newLine
    lea dx, instruction2
    call printString
    call newLine
    lea dx, instruction3
    call printString
    call newLine
    lea dx, instruction4
    call printString
    call newLine
    call newLine
    
    lea dx, separator
    call printString
    call newLine
    
    ret
showWelcome ENDP

; ========== 等待用户按空格开始游戏 ==========
waitForStart PROC
waitLoop:
    mov ah, 01h             ; 检查键盘缓冲区是否有按键
    int 16h
    jz waitLoop             ; 无按键则继续等待
    
    mov ah, 00h             ; 读取按键（清除缓冲区）
    int 16h
    
    cmp al, ' '             ; 检查是否按下空格键
    je startGame
    
    cmp al, 27              ; 检查ESC键（ASCII码）
    je exitFromWelcome
    
    cmp ah, 01h             ; 检查ESC键（扫描码）
    je exitFromWelcome
    
    jmp waitLoop            ; 其他按键忽略，继续等待
    
startGame:
    ret                     ; 空格键按下，开始游戏
    
exitFromWelcome:
    mov ah, 4ch             ; ESC键按下，直接退出程序
    int 21h
waitForStart ENDP

; ========== 初始化游戏 ==========
initGame PROC
    call clearScreen        ; 清屏
    
    ; 初始化蛇的位置（屏幕中央偏左，垂直排列）
    mov ax, 30              ; X坐标（第30列）
    mov snakeX[0], ax       ; 蛇头X坐标
    mov snakeX[2], ax       ; 第二节X坐标
    mov snakeX[4], ax       ; 第三节X坐标
    
    mov ax, 12              ; 蛇头Y坐标（第12行）
    mov snakeY[0], ax
    mov ax, 13              ; 第二节Y坐标
    mov snakeY[2], ax
    mov ax, 14              ; 第三节Y坐标
    mov snakeY[4], ax
    
    ; 初始化方向（向右）
    mov direction, 1        ; 0=上, 1=右, 2=下, 3=左
    mov nextDirection, 1
    mov cs:directionTSR, 1  ; 中断处理程序中的方向变量
    
    ; 初始化游戏状态
    mov snakeLength, 3      ; 初始长度为3节
    mov gameOver, 0         ; 游戏未结束
    mov score, 0            ; 分数归零
    mov gameSpeed, 8        ; 初始速度（数值越大越慢）
    mov cs:escPressed, 0    ; ESC键未按下
    
    call generateFood       ; 生成第一个食物
    
    call drawGame           ; 绘制初始画面
    
    ret
initGame ENDP

; 安装键盘中断处理程序
installKeyboardInterrupt PROC
    push ax
    push es
    push si
    
    ; 保存原INT 09h中断向量（中断向量表在0:0处，每个向量占4字节）
    mov ax, 0                ; 中断向量表段地址
    mov es, ax
    mov si, 09h * 4          ; INT 09h的偏移地址（09h * 4 = 36字节）
    mov ax, es:[si]          ; 读取原中断处理程序的偏移地址
    mov word ptr cs:oldInt09hTSR, ax
    mov ax, es:[si+2]        ; 读取原中断处理程序的段地址
    mov word ptr cs:oldInt09hTSR+2, ax
    
    ; 设置新的INT 09h中断向量（指向我们的键盘处理程序）
    cli                      ; 关中断，防止在修改向量表时被打断
    mov word ptr es:[09h*4], offset keyboardHandler  ; 设置偏移地址
    mov es:[09h*4+2], cs     ; 设置段地址（代码段）
    sti                      ; 开中断
    
    pop si
    pop es
    pop ax
    ret
installKeyboardInterrupt ENDP

; ========== 键盘中断处理程序（INT 09h） ==========
keyboardHandler PROC FAR
    pushf                   ; 保存标志寄存器
    push ax                 ; 保存寄存器
    push ds
    
    ; 设置数据段（中断处理程序需要访问代码段中的数据）
    push cs
    pop ds
    
    ; 从键盘端口60h读取扫描码
    in al, 60h              ; AL = 扫描码（按下时<80h，释放时>=80h）
    
    ; 检查按键状态：最高位为1表示释放，为0表示按下
    test al, 80h            ; 测试最高位（80h = 10000000b）
    jnz checkEscRelease     ; 如果是释放，跳转检查ESC释放
    
    ; 防抖处理：避免同一按键被重复处理
    cmp al, cs:lastKeyProcessed
    jne checkKeys           ; 新按键，继续处理
    jmp normalKey           ; 重复按键，忽略
    
checkKeys:
    ; 检查方向键扫描码（按下状态）
    cmp al, 48h             ; 上箭头扫描码（按下）
    jne checkRight
    jmp arrowUp
checkRight:
    cmp al, 4Dh             ; 右箭头扫描码（按下）
    jne checkDown
    jmp arrowRight
checkDown:
    cmp al, 50h             ; 下箭头扫描码（按下）
    jne checkLeft
    jmp arrowDown
checkLeft:
    cmp al, 4Bh             ; 左箭头扫描码（按下）
    jne checkEsc
    jmp arrowLeft
checkEsc:
    cmp al, 01h             ; ESC键扫描码（按下）
    jne notEscKey
    jmp escKey
    
notEscKey:
    jmp normalKey           ; 不是我们处理的按键，交给原处理程序
    
checkEscRelease:
    ; 检查是否是ESC键释放
    cmp al, 81h             ; ESC键释放（01h + 80h）
    jne checkDirRelease2
    jmp escKeyRelease
    
checkDirRelease2:
    
    ; 如果是方向键释放，清除lastKeyProcessed，允许下次按下
    cmp al, 0C8h            ; 上箭头释放（48h + 80h）
    jne checkRightRelease
    jmp clearLastKey
checkRightRelease:
    cmp al, 0CDh            ; 右箭头释放（4Dh + 80h）
    jne checkDownRelease
    jmp clearLastKey
checkDownRelease:
    cmp al, 0D0h            ; 下箭头释放（50h + 80h）
    jne checkLeftRelease
    jmp clearLastKey
checkLeftRelease:
    cmp al, 0CBh            ; 左箭头释放（4Bh + 80h）
    jne notDirectionRelease
    jmp clearLastKey
notDirectionRelease:
    
    jmp normalKey
    
clearLastKey:
    ; 清除lastKeyProcessed，允许下次按下
    mov cs:lastKeyProcessed, 0
    jmp normalKey
    
escKeyRelease:
    ; ESC键释放，设置退出标志
    mov cs:escPressed, 1
    jmp keyHandled
    
arrowUp:
    ; 不能直接反向（从下到上）
    cmp cs:directionTSR, 2
    jne setUp
    jmp normalKey
setUp:
    mov cs:directionTSR, 0
    mov cs:lastKeyProcessed, al  ; 记录已处理的按键
    jmp keyHandled
    
arrowRight:
    ; 不能直接反向（从左到右）
    cmp cs:directionTSR, 3
    jne setRight
    jmp normalKey
setRight:
    mov cs:directionTSR, 1
    mov cs:lastKeyProcessed, al  ; 记录已处理的按键
    jmp keyHandled
    
arrowDown:
    ; 不能直接反向（从上到下）
    cmp cs:directionTSR, 0
    jne setDown
    jmp normalKey
setDown:
    mov cs:directionTSR, 2
    mov cs:lastKeyProcessed, al  ; 记录已处理的按键
    jmp keyHandled
    
arrowLeft:
    ; 不能直接反向（从右到左）
    cmp cs:directionTSR, 1
    jne setLeft
    jmp normalKey
setLeft:
    mov cs:directionTSR, 3
    mov cs:lastKeyProcessed, al  ; 记录已处理的按键
    jmp keyHandled
    
escKey:
    ; ESC键按下，也设置退出标志（双重保险）
    mov cs:escPressed, 1
    jmp keyHandled
    
keyHandled:
    ; 向8259中断控制器发送EOI（中断结束信号）
    mov al, 20h             ; EOI命令
    out 20h, al             ; 必须发送，否则键盘中断会被屏蔽
    
    pop ds                  ; 恢复寄存器
    pop ax
    popf
    iret                    ; 中断返回
    
normalKey:
    ; 不是我们处理的按键，调用原中断处理程序
    pop ds
    pop ax
    popf
    jmp dword ptr cs:oldInt09hTSR  ; 跳转到原INT 09h处理程序
keyboardHandler ENDP

; ========== 移动蛇 ==========
moveSnake PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; 从中断处理程序获取最新方向
    mov al, cs:directionTSR
    mov direction, al
    
    ; 获取当前蛇头位置
    mov ax, snakeX[0]       ; 蛇头X坐标
    mov bx, snakeY[0]       ; 蛇头Y坐标
    
    ; 根据方向计算新蛇头位置
    cmp direction, 0        ; 0=上
    je moveUp
    cmp direction, 1        ; 1=右
    je moveRight
    cmp direction, 2        ; 2=下
    je moveDown
    jmp moveLeft            ; 3=左
    
moveUp:
    dec bx                  ; Y坐标减1（向上）
    jmp moveDone
    
moveRight:
    inc ax                  ; X坐标加1（向右）
    jmp moveDone
    
moveDown:
    inc bx                  ; Y坐标加1（向下）
    jmp moveDone
    
moveLeft:
    dec ax                  ; X坐标减1（向左）
    jmp moveDone
    
moveDone:
    ; 边界检测：屏幕范围0-79列，1-24行（第0行显示分数）
    cmp ax, 0               ; 左边界
    jl hitWall
    cmp ax, 79              ; 右边界
    jg hitWall
    cmp bx, 1               ; 上边界（第1行）
    jl hitWall
    cmp bx, 24              ; 下边界（第24行）
    jg hitWall
    
    ; 移动蛇身：每节移动到前一节的位置（从尾部开始）
    mov cx, snakeLength     ; 蛇的长度
    dec cx                  ; 跳过蛇头（从第1节开始）
    mov si, cx
    shl si, 1               ; 乘以2（word类型，每个元素2字节）
    
moveBody:
    cmp si, 0               ; 是否到达蛇头位置
    je updateHead
    ; 将前一节的位置复制到当前节
    mov dx, snakeX[si-2]     ; 前一节的X坐标
    mov snakeX[si], dx       ; 复制到当前节
    mov dx, snakeY[si-2]     ; 前一节的Y坐标
    mov snakeY[si], dx       ; 复制到当前节
    sub si, 2               ; 向前移动（索引减1，即减2字节）
    jmp moveBody
    
updateHead:
    ; 更新蛇头到新位置
    mov snakeX[0], ax       ; 新蛇头X坐标
    mov snakeY[0], bx       ; 新蛇头Y坐标
    
    jmp moveSnakeEnd
    
hitWall:
    mov gameOver, 1         ; 撞墙，游戏结束
    
moveSnakeEnd:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
moveSnake ENDP

; ========== 检查碰撞（撞到自己） ==========
checkCollision PROC
    push ax
    push bx
    push cx
    push si
    
    ; 获取蛇头位置
    mov ax, snakeX[0]
    mov bx, snakeY[0]
    
    ; 检查蛇头是否与蛇身重叠（从第2节开始，第1节紧邻蛇头不算碰撞）
    mov cx, snakeLength     ; 蛇的总长度
    dec cx                  ; 跳过蛇头
    mov si, 2               ; 从第2节开始检查（索引从1开始，si=2表示第2节）
    
checkSelf:
    cmp si, cx              ; 是否检查完所有节
    jg collisionOK          ; 检查完毕，无碰撞
    
    shl si, 1               ; 乘以2（word类型）
    ; 比较蛇头与当前节的坐标
    cmp ax, snakeX[si]      ; X坐标是否相同
    jne nextCheck
    cmp bx, snakeY[si]      ; Y坐标是否相同
    jne nextCheck
    
    ; 坐标相同，撞到自己了
    mov gameOver, 1
    jmp collisionEnd
    
nextCheck:
    shr si, 1               ; 恢复索引（除以2）
    inc si                  ; 检查下一节
    jmp checkSelf
    
collisionOK:
collisionEnd:
    pop si
    pop cx
    pop bx
    pop ax
    ret
checkCollision ENDP

; ========== 检查是否吃到食物 ==========
checkFood PROC
    push ax
    push bx
    push cx
    push si
    
    ; 检查蛇头坐标是否与食物坐标相同
    mov ax, snakeX[0]
    cmp ax, foodX           ; 比较X坐标
    jne foodNotEaten
    
    mov bx, snakeY[0]
    cmp bx, foodY           ; 比较Y坐标
    jne foodNotEaten
    
    ; 吃到食物了！
    inc score               ; 分数加1
    
    ; 蛇身增长：在尾部添加一节（位置与倒数第二节相同）
    mov ax, snakeLength
    shl ax, 1               ; 乘以2（word类型）
    mov si, ax              ; si = 新节的索引（当前尾部）
    ; 将倒数第二节的位置复制到新节
    mov bx, snakeX[si-2]    ; 倒数第二节的X坐标
    mov snakeX[si], bx      ; 复制到新节
    mov bx, snakeY[si-2]    ; 倒数第二节的Y坐标
    mov snakeY[si], bx      ; 复制到新节
    inc snakeLength         ; 长度加1
    
    call generateFood       ; 生成新食物
    
    ; 根据分数调整游戏速度（每吃5个食物加快一次）
    mov ax, score
    mov bl, 5
    div bl                  ; AL = score / 5（商），AH = score % 5（余数）
    mov bl, al              ; 保存商（每5分一级）
    mov al, 8               ; 初始速度值
    sub al, bl              ; 速度值减小（数值越小速度越快）
    cmp al, 3               ; 最快速度限制（最小为3）
    jge setSpeed
    mov al, 3               ; 限制最快速度
setSpeed:
    mov gameSpeed, al
    
foodNotEaten:
    pop si
    pop cx
    pop bx
    pop ax
    ret
checkFood ENDP

; ========== 生成食物（随机位置） ==========
generateFood PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
generateAgain:
    ; 获取系统时间作为随机数种子（INT 21h功能2Ch）
    mov ah, 2Ch             ; 获取系统时间
    int 21h                 ; 返回：CH=小时，CL=分钟，DH=秒，DL=百分之一秒
    
    ; 生成随机X坐标（0-79列）
    mov ax, dx              ; DX = DL(百分之一秒) + DH(秒)*256
    mov ah, 0               ; 只取DL（百分之一秒，0-99）
    mov bl, 79              ; 除数（80列：0-79）
    div bl                  ; AL = 商，AH = 余数（0-78）
    mov al, ah              ; 使用余数作为随机数
    mov ah, 0
    mov foodX, ax           ; 保存X坐标
    
    ; 生成随机Y坐标（1-23行）
    mov ax, dx
    mov al, dh              ; 取DH（秒，0-59）
    mov ah, 0
    mov bl, 23              ; 除数（23行：1-23）
    div bl                  ; AL = 商，AH = 余数（0-22）
    mov al, ah              ; 使用余数
    mov ah, 0
    inc al                  ; 加1，范围变为1-23（第0行显示分数）
    mov foodY, ax           ; 保存Y坐标
    
    ; 检查食物位置是否与蛇身重叠
    mov cx, snakeLength     ; 蛇的长度
    mov si, 0               ; 从第0节（蛇头）开始检查
    
checkSnake:
    cmp si, cx              ; 是否检查完所有节
    jge foodOK              ; 检查完毕，位置可用
    
    shl si, 1               ; 乘以2（word类型）
    ; 比较食物坐标与当前节坐标
    mov ax, foodX
    cmp ax, snakeX[si]      ; X坐标是否相同
    jne nextSnakeCheck
    mov ax, foodY
    cmp ax, snakeY[si]      ; Y坐标是否相同
    jne nextSnakeCheck
    
    ; 位置重叠，重新生成
    shr si, 1
    jmp generateAgain
    
nextSnakeCheck:
    shr si, 1               ; 恢复索引
    inc si                  ; 检查下一节
    jmp checkSnake
    
foodOK:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
generateFood ENDP

; ========== 绘制游戏画面 ==========
drawGame PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; 清屏（INT 10h功能06h：向上滚动窗口）
    mov ah, 06h             ; 滚动窗口功能
    mov al, 0               ; 0表示清屏
    mov bh, 07h             ; 属性：黑底白字
    mov ch, 1               ; 起始行（第1行）
    mov cl, 0               ; 起始列（第0列）
    mov dh, 24              ; 结束行（第24行）
    mov dl, 79              ; 结束列（第79列）
    int 10h                 ; 清屏（保留第0行显示分数）
    
    ; 再次清屏确保清除干净
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov ch, 1
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 10h
    
    ; 在第0行显示分数
    mov ah, 02h             ; 设置光标位置
    mov bh, 0               ; 第0页
    mov dx, 0               ; DH=0行，DL=0列
    int 10h
    
    lea dx, scoreMsg        ; 显示"Score: "
    mov ah, 09h             ; 显示字符串
    int 21h
    
    mov ax, score
    call printNumber        ; 显示分数数字
    
    ; 绘制蛇身（遍历所有节）
    mov cx, snakeLength     ; 循环次数
    mov si, 0               ; 从第0节开始
    
drawSnake:
    push cx                 ; 保存循环计数器
    shl si, 1               ; 乘以2（word类型）
    mov ax, snakeX[si]      ; 获取当前节的X坐标
    mov bx, snakeY[si]      ; 获取当前节的Y坐标
    
    ; 设置光标位置（INT 10h功能02h）
    mov dl, al              ; X坐标（列，低8位）
    mov dh, bl              ; Y坐标（行，低8位）
    mov ah, 02h
    mov bh, 0               ; 第0页
    int 10h
    
    push dx                 ; 保存坐标（防止被覆盖）
    
    ; 判断是蛇头还是蛇身
    cmp si, 0               ; si=0表示蛇头
    je drawHead
    mov dl, '*'             ; 蛇身用*表示
    jmp drawChar
    
drawHead:
    mov dl, '@'             ; 蛇头用@表示
    
drawChar:
    mov ah, 02h             ; 显示字符（INT 21h功能02h）
    int 21h
    
    pop dx                  ; 恢复坐标（保持栈平衡）
    
    shr si, 1               ; 恢复索引（除以2）
    inc si                  ; 下一节
    pop cx                  ; 恢复循环计数器
    loop drawSnake          ; 继续循环
    
    ; 绘制食物
    mov ax, foodX           ; 获取食物X坐标
    mov bx, ax              ; 保存到BX
    mov ax, foodY           ; 获取食物Y坐标
    mov cx, ax              ; 保存到CX
    
    ; 设置光标到食物位置
    mov dl, bl              ; X坐标
    mov dh, cl              ; Y坐标
    mov ah, 02h
    mov bh, 0
    int 10h
    
    mov dl, '#'             ; 食物用#表示
    mov ah, 02h
    int 21h
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
drawGame ENDP

; ========== 显示游戏结束界面 ==========
showGameOver PROC
    call clearScreen        ; 清屏
    
    call newLine
    call newLine
    
    lea dx, gameOverMsg    ; 显示"GAME OVER!"
    call printString
    call newLine
    call newLine
    
    lea dx, scoreMsg        ; 显示"Score: "
    call printString
    mov ax, score
    call printNumber        ; 显示最终分数
    call newLine
    call newLine
    
    lea dx, pressKeyMsg     ; 显示"Press any key to exit..."
    call printString
    call newLine
    
    ret
showGameOver ENDP

; ========== 卸载键盘中断处理程序 ==========
uninstallKeyboardInterrupt PROC
    push ax
    push es
    push si
    
    cli                     ; 关中断，防止在恢复向量时被打断
    mov ax, 0               ; 中断向量表段地址
    mov es, ax
    
    ; 恢复原INT 09h中断向量到中断向量表
    mov si, 09h * 4         ; INT 09h的偏移地址
    mov ax, word ptr cs:oldInt09hTSR      ; 原处理程序的偏移地址
    mov es:[si], ax
    mov ax, word ptr cs:oldInt09hTSR+2    ; 原处理程序的段地址
    mov es:[si+2], ax
    
    sti                     ; 开中断
    
    pop si
    pop es
    pop ax
    ret
uninstallKeyboardInterrupt ENDP

; ========== 清屏 ==========
clearScreen PROC
    push ax
    push bx
    push cx
    push dx
    
    ; 使用INT 10h功能06h清屏
    mov ah, 06h             ; 向上滚动窗口
    mov al, 0               ; 0表示清屏
    mov bh, 07h             ; 属性：黑底白字
    mov cx, 0               ; 起始位置（0行0列）
    mov dx, 184Fh           ; 结束位置（24行79列，184Fh = 24*256+79）
    int 10h
    
    ; 将光标移到左上角
    mov ah, 02h             ; 设置光标位置
    mov bh, 0               ; 第0页
    mov dx, 0               ; 0行0列
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
clearScreen ENDP

; ========== 打印数字（十进制） ==========
printNumber PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ax, score           ; 要打印的数字
    mov bx, 10             ; 除数（十进制）
    mov cx, 0              ; 计数器（记录位数）
    
divLoop:
    ; 将数字逐位分解（从低位到高位）
    mov dx, 0              ; 清零DX（被除数高16位）
    div bx                 ; AX = AX / 10，DX = AX % 10
    push dx                ; 将余数（个位）压栈
    inc cx                 ; 位数加1
    cmp ax, 0              ; 商是否为0
    jne divLoop            ; 不为0继续分解
    
printLoop:
    ; 从栈中取出各位数字并打印（从高位到低位）
    pop dx                 ; 取出一位数字
    add dl, '0'            ; 转换为ASCII字符（'0'=48）
    mov ah, 02h            ; 显示字符
    int 21h
    loop printLoop         ; 继续打印下一位
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
printNumber ENDP

; ========== 打印字符串 ==========
printString PROC
    push ax
    mov ah, 09h            ; INT 21h功能09h：显示字符串（DS:DX指向字符串，以$结尾）
    int 21h
    pop ax
    ret
printString ENDP

; ========== 换行 ==========
newLine PROC
    push ax
    push dx
    mov dl, 0Dh            ; 回车符（CR，光标移到行首）
    mov ah, 02h            ; 显示字符
    int 21h
    mov dl, 0Ah            ; 换行符（LF，光标移到下一行）
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
newLine ENDP

; ========== 游戏延迟（控制游戏速度） ==========
gameDelay PROC
    push ax
    push bx
    push cx
    push dx
    
    ; 根据gameSpeed值进行延迟（多层循环实现）
    mov al, gameSpeed       ; 获取速度值（数值越大越慢）
    mov ah, 0
    mov bx, ax              ; 保存到BX作为外层循环计数器
    
    ; 外层循环：执行gameSpeed次
delayOuter:
    cmp bx, 0               ; 外层循环是否结束
    je delayDone
    
    ; 第一层内循环：较长延迟
    mov cx, 0FFFFh          ; 65535次循环（约0.1秒，取决于CPU速度）
delayInner1:
    loop delayInner1        ; CX减1，直到为0
    
    ; 第二层内循环：较短延迟
    mov cx, 0FFFh           ; 4095次循环（微调延迟）
delayInner2:
    loop delayInner2
    
    dec bx                  ; 外层循环计数器减1
    jmp delayOuter
    
delayDone:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
gameDelay ENDP

END MAIN

