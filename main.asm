INCLUDE Irvine32.inc

main EQU start@0

; 外框尺寸
outerBoxWidth = 84
outerBoxHeight = 26

; 方塊尺寸
blockWidth  = 5
blockHeight = 3

; 方塊邊界
BlockTopBoundary    = blockPosInit.Y
BlockBottomBoundary = blockPosInit.Y + (blockHeight * 7)
blockLeftBoundary  = blockPosInit.X
blockRightBoundary = blockPosInit.X + (blockWidth * 15)

.data
; 外框字元
outerBoxTop    BYTE 0DAh, (outerBoxWidth - 2) DUP(0C4h), 0BFh
outerBoxBody   BYTE 0B3h, (outerBoxWidth - 2) DUP(' '), 0B3h
outerBoxBottom BYTE 0C0h, (outerBoxWidth - 2) DUP(0C4h), 0D9h

; 方塊字元
BlockTop    BYTE 0DAh, (blockWidth - 2) DUP(0C4h), 0BFh
BlockBody   BYTE 0B3h, (blockWidth - 2) DUP(' '), 0B3h
BlockBottom BYTE 0C0h, (blockWidth - 2) DUP(0C4h), 0D9h

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
outerAttributes WORD outerBoxWidth DUP(0Ah)  ; 只需要一行的屬性

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
    mov ax, blockPos.X
    mov dx, blockPos.Y
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, dx

    ; 畫上
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockTop, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 畫中
    mov cx, blockHeight-2
L2:
    push cx
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockBody, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop cx
    loop L2

    ; 畫下
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockBottom, blockWidth, outerBoxPos, ADDR count
    ret
drawBlock ENDP

;------------------------------------------------
; 移動方塊
;------------------------------------------------
moveBlock PROC USES eax ebx edx
START_MOVE:
    call Clrscr
    call outerBox
    call drawBlock

    call ReadChar

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
; Main
;------------------------------------------------
main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    call initBlock
    call moveBlock
    call Clrscr
    exit
main ENDP

END main
