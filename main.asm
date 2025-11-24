INCLUDE Irvine32.inc

main EQU start@0

; 外框尺寸
outerBoxWidth = 82
outerBoxHeight = 26

; 方塊尺寸
blockWidth  = 5
blockHeight = 3

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

outerBoxPosInit COORD <5,3>
outerBoxPos COORD <5,3>
blockPosInit COORD <6, 4>
blockPos COORD <6, 4>

cellsWritten DWORD ?
outerAttributes WORD outerBoxWidth DUP(0Ah)  ; 只需要一行的屬性

.code

outerBox PROC USES eax ecx

    ; Get the console ouput handle
    mov ax, outerBoxPosInit.X
    mov outerBoxPos.X, ax
    mov ax, outerBoxPosInit.Y
    mov outerBoxPos.Y, ax

    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax	; save console handle
    call Clrscr
    
    ; draw top of the box
    INVOKE WriteConsoleOutputAttribute,
        outputHandle, 
        ADDR outerAttributes,
        outerBoxWidth,          ; 只設定一行的屬性
        outerBoxPos,
        ADDR cellsWritten

    INVOKE WriteConsoleOutputCharacter,
        outputHandle,	; console output handle
        ADDR outerBoxTop,	; pointer to the top box line
        outerBoxWidth,	; size of box line
        outerBoxPos,	; coordinates of first char
        ADDR count	; output count

    inc outerBoxPos.Y	; next line

    ; draw body of the box
    mov ecx, (outerBoxHeight-2)	; number of lines in body
L1:	push ecx	; save counter

    ; 每行都設定屬性
    INVOKE WriteConsoleOutputAttribute,
        outputHandle, 
        ADDR outerAttributes,
        outerBoxWidth,
        outerBoxPos,
        ADDR cellsWritten

    INVOKE WriteConsoleOutputCharacter,
        outputHandle,	; console output handle
        ADDR outerBoxBody,	; pointer to the box body
        outerBoxWidth,	; size of box line
        outerBoxPos,	; coordinates of first char
        ADDR count; output count

    inc outerBoxPos.Y	; next line
    pop ecx	; restore counter
    loop L1

    ; draw bottom of the box
    INVOKE WriteConsoleOutputAttribute,
        outputHandle, 
        ADDR outerAttributes,
        outerBoxWidth,
        outerBoxPos,
        ADDR cellsWritten

    INVOKE WriteConsoleOutputCharacter,
        outputHandle,	; console output handle
        ADDR outerBoxBottom,	; pointer to the bottom of the box
        outerBoxWidth,	; size of box line
        outerBoxPos,	; coordinates of first char
        ADDR count	; output count
    ret
outerBox ENDP

initBlock PROC USES eax ecx
    ; 將方5*3的方塊左上角放在6*4的位置
    mov ax, blockPosInit.X
    mov blockPos.X, ax
    mov ax, blockPosInit.Y
    mov blockPos.Y, ax
    ret
initBlock ENDP

moveBlock PROC USES eax ecx edx

    ret
moveBlock ENDP

main PROC
    call outerBox
    call moveBlock
    call WaitMsg
    call Clrscr
    exit
main ENDP
END main
