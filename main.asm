INCLUDE Irvine32.inc

main EQU start@0

; 外框尺寸
outerBoxWidth = 84
outerBoxHeight = 26

; 方塊尺寸
blockWidth  = 5
blockHeight = 3

.data
; 外框字元
outerBoxTop    BYTE 0DAh, 82 DUP(0C4h), 0BFh
outerBoxBody   BYTE 0B3h, 82 DUP(' '), 0B3h
outerBoxBottom BYTE 0C0h, 82 DUP(0C4h), 0D9h

; 方塊字元
BlockTop    BYTE 0DAh, 3 DUP(0C4h), 0BFh
BlockBody   BYTE 0B3h, 3 DUP(' '), 0B3h
BlockBottom BYTE 0C0h, 3 DUP(0C4h), 0D9h

outputHandle DWORD 0
bytesWritten DWORD 0
count DWORD 0

; 外框與方塊初始位置
outerBoxPosInit COORD <5,3>
outerBoxPos COORD <?, ?>
blockPosInit COORD <7, 4>
blockPos COORD <?, ?>

; 用來設定屬性
cellsWritten DWORD ?
outerAttributes WORD outerBoxWidth DUP(0F0h)  ; 白底黑字
blockAttributes WORD blockWidth DUP(0F0h)     ; 白底黑字

hConsole HANDLE ?

; Tower 相關
towersPosX WORD 10 DUP(?)  ; 最多10個tower的X位置
towersPosY WORD 10 DUP(?)  ; Y位置
towersType BYTE 10 DUP(?)  ; 類型
towerCount DWORD 0
tempBuffer BYTE blockWidth DUP(?)

.code

;------------------------------------------------
; 畫外框
;------------------------------------------------
outerBox PROC USES eax ecx
    mov ax, outerBoxPosInit.X
    mov outerBoxPos.X, ax
    mov ax, outerBoxPosInit.Y
    mov outerBoxPos.Y, ax

    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    call Clrscr

    ; 畫頂
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxTop, outerBoxWidth, outerBoxPos, ADDR count

    inc outerBoxPos.Y

    ; 畫中間
    mov ecx, outerBoxHeight-2
L1:
    push ecx
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBody, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop ecx
    loop L1

    ; 畫底
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBottom, outerBoxWidth, outerBoxPos, ADDR count
    ret
outerBox ENDP

;------------------------------------------------
; 初始化方塊位置
;------------------------------------------------
initBlock PROC USES eax
    mov ax, blockPosInit.X
    mov blockPos.X, ax
    mov ax, blockPosInit.Y
    mov blockPos.Y, ax
    ret
initBlock ENDP

;------------------------------------------------
; 畫方塊
;------------------------------------------------
drawBlock PROC USES eax
    push DWORD PTR outerBoxPos
    mov ax, blockPos.X
    mov dx, blockPos.Y
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, dx

    ; 畫上
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockTop, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 畫中
    mov cx, blockHeight-2
L2:
    push cx
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockBody, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop cx
    loop L2

    ; 畫下
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockBottom, blockWidth, outerBoxPos, ADDR count
    pop DWORD PTR outerBoxPos
    ret
drawBlock ENDP

;------------------------------------------------
; 移動方塊 (修改版本，加入預設處理)
;------------------------------------------------
moveBlock PROC
START_MOVE:
    call Clrscr
    call outerBox
    call drawBlock
    call drawAllTowers

    call ReadChar

    ; 檢查放置Tower的鍵
    .IF ax == 1e61h
        call addTower
    .ENDIF
    
        ; 方向鍵檢測
        ; UP
    .IF ax == 4800h
        sub blockPos.Y, blockHeight
        mov bx, blockPosInit.Y
        cmp blockPos.Y, bx
        jge END_MOVE
        add blockPos.Y, blockHeight
    .ENDIF

    ; DOWN
    .IF ax == 5000h
        add blockPos.Y, blockHeight
        mov bx, (blockHeight * 7)
        add bx, blockPosInit.Y
        cmp blockPos.Y, bx
        jbe END_MOVE
        sub blockPos.Y, blockHeight
    .ENDIF

    ; LEFT
    .IF ax == 4B00h
        sub blockPos.X, blockWidth
        mov bx, blockPosInit.X
        cmp blockPos.X, bx
        jae END_MOVE
        add blockPos.X, blockWidth
    .ENDIF

    ; RIGHT
    .IF ax == 4D00h
        add blockPos.X, blockWidth
        mov bx, (blockWidth * 15)
        add bx, blockPosInit.X
        cmp blockPos.X, bx
        jbe END_MOVE
        sub blockPos.X, blockWidth
    .ENDIF

    ; ESC
    .IF ax == 011Bh
        jmp EXIT_MOVE
    .ENDIF

END_MOVE:
    jmp START_MOVE
EXIT_MOVE:
    ret
moveBlock ENDP

;------------------------------------------------
; 添加Tower (修正版本)
;------------------------------------------------
addTower PROC USES eax ebx esi
    mov eax, towerCount
    cmp eax, 10
    jge NO_ADD
    
    ; 保存當前索引
    mov ebx, eax
    
    ; 設定 X 座標
    mov esi, OFFSET towersPosX
    imul eax, 2  ; WORD 大小
    add esi, eax
    mov ax, blockPos.X
    mov WORD PTR [esi], ax
    
    ; 設定 Y 座標
    mov esi, OFFSET towersPosY
    mov eax, ebx
    imul eax, 2  ; WORD 大小
    add esi, eax
    mov ax, blockPos.Y
    mov WORD PTR [esi], ax
    
    ; 設定類型 (預設為類型 1)
    mov esi, OFFSET towersType
    mov eax, ebx
    add esi, eax  ; BYTE 大小
    mov BYTE PTR [esi], 1
    
    inc towerCount
NO_ADD:
    ret
addTower ENDP

;------------------------------------------------
; 畫單個Tower
;------------------------------------------------
drawTower PROC USES eax ebx ecx edi esi
    ; 參數在 [esp+24] (因為 USES 推入了5個暫存器)
    mov eax, [esp+24]  ; 索引參數
    push DWORD PTR outerBoxPos
    
    ; 獲取 X 座標
    mov esi, OFFSET towersPosX
    mov ebx, eax
    imul ebx, 2  ; WORD 大小
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.X, ax
    
    ; 獲取 Y 座標
    mov esi, OFFSET towersPosY
    mov eax, [esp+28]  ; 重新載入索引
    mov ebx, eax
    imul ebx, 2  ; WORD 大小
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.Y, ax

    ; 獲取類型
    mov esi, OFFSET towersType
    mov eax, [esp+28]  ; 重新載入索引
    add esi, eax  ; BYTE 大小
    mov bl, BYTE PTR [esi]

    ; 畫頂：=====
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    mov al, '='
    mov ecx, blockWidth
    lea edi, tempBuffer
    rep stosb
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 中： } {
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, ' '
    mov tempBuffer+1, '}'  
    mov tempBuffer+2, ' '
    mov tempBuffer+3, '{'
    mov tempBuffer+4, ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 底：=====
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    mov al, '='
    mov ecx, blockWidth
    lea edi, tempBuffer
    rep stosb
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    
    pop DWORD PTR outerBoxPos
    ret 4  ; 清除參數
drawTower ENDP

;------------------------------------------------
; 畫所有Tower
;------------------------------------------------
drawAllTowers PROC USES ecx
    mov ecx, 0
L:
    cmp ecx, towerCount
    jge DONE
    push ecx
    call drawTower
    inc ecx
    jmp L
DONE:
    ret
drawAllTowers ENDP

;------------------------------------------------
; Main
;------------------------------------------------
main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole, eax
    INVOKE SetConsoleTextAttribute, hConsole, 0f0h ; 白底黑字
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    call initBlock
    call moveBlock
    call Clrscr
    exit
main ENDP

END main
