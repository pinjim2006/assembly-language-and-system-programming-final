INCLUDE Irvine32.inc
;INCLUDE monsters.asm 為了讓 monsters.asm 能讀取到 main.asm 裡的常數，故將 INCLUDE 移到最後面。

; =================================================================================
; 函式原型宣告
; =================================================================================
showStartScreen PROTO       
showEscMenu PROTO
showHowToPlay PROTO
initConsoleWindow PROTO     
outerBox PROTO
initBlock PROTO
drawMovingDashedCursor PROTO
hasMapComponentAtCursor PROTO
toggleMenuState PROTO
handleNormalInput PROTO
handleSideMenuInput PROTO   
drawSideMenu PROTO          
drawSideMenuCursor PROTO    
clearSideMenuCursor PROTO   
updateDashAnimation PROTO
moveBlock PROTO
addTowerWithType PROTO
checkTowerAtCurrentPosition PROTO
deleteTower PROTO
isTowerAtPositionSimple PROTO
removeTowerAtIndexSimple PROTO
drawTower PROTO
initMapSystem PROTO
canPlaceTowerAtCurrentPos PROTO
drawMapComponents PROTO
drawComponent PROTO
calculateScreenPosition PROTO
drawATower PROTO
drawBTower PROTO
drawCTower PROTO
drawDTower PROTO
drawETower PROTO
drawAllTowers PROTO
restoreGraphicsAtPos PROTO
getTowerTypeAtPos PROTO

createMonsters PROTO :DWORD
updateMonstersPositions PROTO
removeMonsters PROTO
drawMonsters PROTO

; =================================================================================
; 常數定義
; =================================================================================
main EQU start@0

; 視窗大小
WINDOW_WIDTH        = 120
WINDOW_HEIGHT       = 40

; 介面尺寸
outerBoxWidth       = 84
outerBoxHeight      = 26

; 遊戲方塊
blockWidth          = 5
blockHeight         = 3

; 地圖常數
MAP_WIDTH           = 16
MAP_HEIGHT          = 8

; 地圖元件 ID
COMPONENT_EMPTY     = 0
COMPONENT_OUTLET    = 1
COMPONENT_EXIT      = 2
COMPONENT_PATH_H    = 3
COMPONENT_PATH_V    = 4
COMPONENT_CORNER_1  = 5
COMPONENT_CORNER_2  = 6
COMPONENT_CORNER_3  = 7
COMPONENT_CORNER_4  = 8

; 側邊選單設定
SIDE_MENU_X         = 90     
SIDE_MENU_Y         = 4
SIDE_MENU_SPACING   = 5      
TOWER_MENU_COUNT    EQU 5

; 動畫速度
DASH_SPEED          EQU 5

; 選單設定
MENU_OPTION_COUNT   EQU 4

.data

; 選單游標位置 (0-3)
menuCursor          BYTE 0
; =================================================================================
; 介面資料
; =================================================================================
windowRect      SMALL_RECT <0, 0, WINDOW_WIDTH-1, WINDOW_HEIGHT-1>
consoleSize     COORD <WINDOW_WIDTH, WINDOW_HEIGHT>

outerBoxTop     BYTE 0DAh, 82 DUP(0C4h), 0BFh
outerBoxBody    BYTE 0B3h, 82 DUP(' '), 0B3h
outerBoxBottom  BYTE 0C0h, 82 DUP(0C4h), 0D9h

; Handle
outputHandle    DWORD 0
inputHandle     DWORD 0     
cellsWritten    DWORD ?
count           DWORD 0
numEvents       DWORD 0     

; 座標位置
outerBoxPosInit COORD <5,3>     
outerBoxPos     COORD <?, ?>    
blockPosInit    COORD <7, 4>    
blockPos        COORD <?, ?>    
prevBlockPos    COORD <?, ?>    

; 側邊選單游標控制
sideMenuCursorIndex DWORD 0     
sideMenuCursorPos   COORD <?, ?>

; 建造狀態
currentBuildType    BYTE 1      

; 顏色屬性 (F0h = 白底黑字)
outerAttributes WORD outerBoxWidth DUP(0F0h)
blockAttributes WORD blockWidth DUP(0F0h)
cursorAttr      WORD blockWidth DUP(0F0h)     
emptyLine       BYTE 60 DUP(' ') 

; 各塔顏色 (背景 F=白, 文字顏色不同)
attrTowerA      WORD blockWidth DUP(0F0h) 
attrTowerB      WORD blockWidth DUP(0F0h) 
attrTowerC      WORD blockWidth DUP(0F0h) 
attrTowerD      WORD blockWidth DUP(0F0h) 
attrTowerE      WORD blockWidth DUP(0F0h) 

; 塔的名稱字串
strNameA        BYTE "Cannon ", 0
strNameB        BYTE "Sniper ", 0
strNameC        BYTE "Ice    ", 0  
strNameD        BYTE "Mage   ", 0
strNameE        BYTE "Missile", 0 

; 側邊選單游標樣式
attrMenuCursor  WORD 4 DUP(0C0h) 
menuCursorStr   BYTE " << "

; 顯示選單名稱的屬性 (白底黑字)
attrMenuName    WORD 10 DUP(0F0h)

tempBuffer      BYTE blockWidth DUP(?)

; =================================================================================
; 遊戲資料
; =================================================================================
towerMax        EQU 30 
towersPosX      WORD towerMax DUP(?)  
towersPosY      WORD towerMax DUP(?)  
towersType      BYTE towerMax DUP(?)  
towerCount      DWORD 0               

; [修正 2] 狀態變數
; 0: 等待下一波
; 1: 觸發生成 (瞬間狀態)
; 2: 戰鬥進行中 (怪物移動中)
startWave       DWORD 0       
cur_round       DWORD 1       

; 狀態控制
menuState           DWORD 0  
towerTypes          BYTE 1, 2, 3, 4, 5

; 動畫變數
dashTimer       DWORD 0       
dashAnimState   DWORD 0       
dashStyle1      BYTE '-', ' ', '-', ' ', '-', ' ', ' ', '-', ' ', '-', ' ', '-'   
dashStyle2      BYTE ' ', '-', ' ', '-', ' ', '|', '|', ' ', '-', ' ', '-', ' '   

; 開始畫面文字
startTitle1     BYTE " _____                       ____       __                    ", 0
startTitle2     BYTE "|_   _|____      _____ _ __ |  _ \  ___|  | ___ _ __  ___  ___ ", 0
startTitle3     BYTE "  | |/ _ \ \ /\ / / _ \ '__|| | | |/ _ \ |_ / _ \ '_ \/ __|/ _ \", 0
startTitle4     BYTE "  | | (_) \ V  V /  __/ |   | |_| |  __/  _|  __/ | | \__ \  __/", 0
startTitle5     BYTE "  |_|\___/ \_/\_/ \___|_|   |____/ \___|_|  \___|_| |_|___/\___|", 0
startTitle6     BYTE "                                                                 ", 0
startPrompt     BYTE "                Press ENTER to start...", 0

; ESC 選單文字
menuTitle       BYTE "========== MENU ==========", 0
menuOption1     BYTE "   Continue", 0
menuOption2     BYTE "   Restart", 0
menuOption3     BYTE "   How to Play", 0
menuOption4     BYTE "   End Game", 0
menuArrow       BYTE ">>", 0
twoSpaces       BYTE "  ", 0
menuPrompt      BYTE "Use Arrow Keys to select, ENTER to confirm", 0

; 使用說明文字
helpTitle       BYTE "========== HOW TO PLAY ==========", 0
helpLine1       BYTE "Arrow Keys: Move cursor", 0
helpLine2       BYTE "F: Select tower (use up and down arrow keys)", 0
helpLine3       BYTE "ENTER: Build tower", 0
helpLine4       BYTE "X: Delete tower", 0
helpLine5       BYTE "ESC: Open menu", 0
helpLine6       BYTE "Towers can only be placed on empty tiles", 0
helpPrompt      BYTE "Press any key to continue...", 0

; 地圖資料
mapData BYTE (MAP_WIDTH * MAP_HEIGHT) DUP(0)
map1Data BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
         BYTE 0,1,0,6,3,3,3,3,3,3,3,5,0,2,0,0
         BYTE 0,4,0,4,0,0,0,0,0,0,0,4,0,4,0,0
         BYTE 0,4,0,4,0,0,6,3,3,3,3,8,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,7,3,8,0,0,7,3,3,3,3,3,3,8,0,0
         BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; 元件 ASCII
componentChars LABEL BYTE
component0 BYTE 15 DUP(20h)
component1 BYTE 5 DUP(20h), 20h, 3 DUP(0DCh), 20h, 0DEh, 0DBh, 0DFh, 0DBh, 0DDh
component2 BYTE 5 DUP(20h), 20h, 3 DUP(0DCh), 20h, 0DEh, 3 DUP(0B0h), 0DDh
component3 BYTE 5 DUP(20h), 5 DUP(0B0h), 5 DUP(20h)
component4 BYTE 20h, 3 DUP(0B0h), 20h, 20h, 3 DUP(0B0h), 20h, 20h, 3 DUP(0B0h), 20h
component5 BYTE 5 DUP(20h), 4 DUP(0B0h), 20h, 20h, 3 DUP(0B0h), 20h
component6 BYTE 5 DUP(20h), 20h, 4 DUP(0B0h), 20h, 3 DUP(0B0h), 20h
component7 BYTE 20h, 3 DUP(0B0h), 20h, 20h, 4 DUP(0B0h), 5 DUP(20h)
component8 BYTE 20h, 3 DUP(0B0h), 20h, 4 DUP(0B0h), 20h, 5 DUP(20h)

.code
; =================================================================================
; 程式進入點
; =================================================================================
main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    INVOKE GetStdHandle, STD_INPUT_HANDLE   
    mov inputHandle, eax
    
    call initConsoleWindow

    INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
    call Clrscr 
    
    ; 顯示開始畫面
    call showStartScreen

    call outerBox       
    call initMapSystem  
    call initBlock      
    
    call drawMapComponents
    call drawAllTowers
    call drawSideMenu

    call moveBlock      
    
    call Clrscr
    exit
main ENDP

; =================================================================================
; 設定視窗大小
; =================================================================================
initConsoleWindow PROC
    INVOKE SetConsoleScreenBufferSize, outputHandle, consoleSize
    INVOKE SetConsoleWindowInfo, outputHandle, TRUE, ADDR windowRect
    ret
initConsoleWindow ENDP

; =================================================================================
; 顯示開始畫面並等待 ENTER 鍵
; =================================================================================
showStartScreen PROC USES edx
    call Clrscr
    mov dh, 8
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle1
    call WriteString
    mov dh, 9
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle2
    call WriteString
    mov dh, 10
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle3
    call WriteString
    mov dh, 11
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle4
    call WriteString
    mov dh, 12
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle5
    call WriteString
    mov dh, 13
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle6
    call WriteString
    mov dh, 16
    mov dl, 22
    call Gotoxy
    mov edx, OFFSET startPrompt
    call WriteString
WAIT_ENTER:
    call ReadChar
    cmp al, 13  
    jne WAIT_ENTER
    call Clrscr
    ret
showStartScreen ENDP

; =================================================================================
; 顯示 ESC 選單
; =================================================================================
showEscMenu PROC USES ebx ecx edx
    LOCAL oldCursor:BYTE
    LOCAL keyCode:WORD
    
    mov menuCursor, 0
    call Clrscr
    
    mov dh, 8
    mov dl, 27
    call Gotoxy
    mov edx, OFFSET menuTitle
    call WriteString
    mov dh, 10
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption1
    call WriteString
    mov dh, 11
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption2
    call WriteString
    mov dh, 12
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption3
    call WriteString
    mov dh, 13
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption4
    call WriteString
    mov dh, 15
    mov dl, 18
    call Gotoxy
    mov edx, OFFSET menuPrompt
    call WriteString
    mov dh, 10
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET menuArrow
    call WriteString
    
MENU_WAIT_INPUT:
    mov eax, 50
    call Delay
    call ReadKey
    jz MENU_WAIT_INPUT
    
    mov keyCode, ax
    movzx eax, menuCursor
    mov oldCursor, al
    
    mov ax, keyCode
    cmp ax, 4800h
    je MENU_UP
    cmp ax, 5000h
    je MENU_DOWN
    cmp al, 13
    je MENU_SELECT
    cmp ax, 011Bh
    je MENU_CANCEL
    jmp MENU_WAIT_INPUT
    
MENU_UP:
    movzx eax, menuCursor
    cmp eax, 0
    je MENU_WAIT_INPUT  
    dec menuCursor
    call FlushKeyBuffer
    jmp UPDATE_CURSOR
    
MENU_DOWN:
    movzx eax, menuCursor
    cmp eax, MENU_OPTION_COUNT - 1
    jge MENU_WAIT_INPUT  
    inc menuCursor
    call FlushKeyBuffer
    jmp UPDATE_CURSOR
    
UPDATE_CURSOR:
    movzx eax, oldCursor
    add al, 10 
    mov dh, al
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET twoSpaces
    call WriteString
    movzx eax, menuCursor
    add al, 10 
    mov dh, al
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET menuArrow
    call WriteString
    jmp MENU_WAIT_INPUT
    
MENU_SELECT:
    movzx eax, menuCursor
    inc eax  
    jmp MENU_EXIT
    
MENU_CANCEL:
    mov eax, 1  
    
MENU_EXIT:
    ret
showEscMenu ENDP

FlushKeyBuffer PROC
FLUSH_LOOP:
    call ReadKey
    jnz FLUSH_LOOP 
    ret
FlushKeyBuffer ENDP

showHowToPlay PROC USES edx
    call Clrscr
    mov dh, 6
    mov dl, 24
    call Gotoxy
    mov edx, OFFSET helpTitle
    call WriteString
    mov dh, 8
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine1
    call WriteString
    mov dh, 9
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine2
    call WriteString
    mov dh, 10
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine3
    call WriteString
    mov dh, 11
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine4
    call WriteString
    mov dh, 12
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine5
    call WriteString
    mov dh, 13
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine6
    call WriteString
    mov dh, 15
    mov dl, 22
    call Gotoxy
    mov edx, OFFSET helpPrompt
    call WriteString
    call ReadChar
    ret
showHowToPlay ENDP

; =================================================================================
; 繪製常駐側邊選單 (常駐狀態只畫圖)
; =================================================================================
drawSideMenu PROC USES eax ecx esi
    push DWORD PTR outerBoxPos
    mov ecx, 0
DRAW_MENU_LOOP:
    cmp ecx, TOWER_MENU_COUNT
    jge DRAW_MENU_FINISH
    mov eax, ecx
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    mov outerBoxPos.Y, ax
    mov outerBoxPos.X, SIDE_MENU_X
    push ecx
    cmp ecx, 0
    je D_A
    cmp ecx, 1
    je D_B
    cmp ecx, 2
    je D_C
    cmp ecx, 3
    je D_D
    cmp ecx, 4
    je D_E
    jmp D_NEXT
D_A: call drawATower
     jmp D_NEXT
D_B: call drawBTower
     jmp D_NEXT
D_C: call drawCTower
     jmp D_NEXT
D_D: call drawDTower
     jmp D_NEXT
D_E: call drawETower
D_NEXT:
    pop ecx
    inc ecx
    jmp DRAW_MENU_LOOP
DRAW_MENU_FINISH:
    pop DWORD PTR outerBoxPos
    ret
drawSideMenu ENDP

drawSideMenuCursor PROC USES eax
    mov eax, sideMenuCursorIndex
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    add eax, 1                  
    mov sideMenuCursorPos.Y, ax
    mov ax, SIDE_MENU_X
    add ax, 6                   
    mov sideMenuCursorPos.X, ax
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuCursor, 4, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR menuCursorStr, 4, sideMenuCursorPos, ADDR count
    add sideMenuCursorPos.X, 5
    mov eax, sideMenuCursorIndex
    cmp eax, 0
    je SHOW_NAME_A
    cmp eax, 1
    je SHOW_NAME_B
    cmp eax, 2
    je SHOW_NAME_C
    cmp eax, 3
    je SHOW_NAME_D
    cmp eax, 4
    je SHOW_NAME_E
    jmp SKIP_NAME
SHOW_NAME_A:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 7, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameA, 7, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_B:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 7, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameB, 7, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_C:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 7, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameC, 7, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_D:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 7, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameD, 7, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_E:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 7, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameE, 7, sideMenuCursorPos, ADDR count
SKIP_NAME:
    ret
drawSideMenuCursor ENDP

clearSideMenuCursor PROC USES eax
    mov eax, sideMenuCursorIndex
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    add eax, 1
    mov sideMenuCursorPos.Y, ax
    mov ax, SIDE_MENU_X
    add ax, 6
    mov sideMenuCursorPos.X, ax
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 4, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 4, sideMenuCursorPos, ADDR count
    add sideMenuCursorPos.X, 5
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 10, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 10, sideMenuCursorPos, ADDR count
    ret
clearSideMenuCursor ENDP

toggleMenuState PROC
    mov eax, menuState
    xor eax, 1
    mov menuState, eax
    cmp eax, 1
    je SWITCH_TO_MENU
    call clearSideMenuCursor
    jmp TOGGLE_DONE
SWITCH_TO_MENU:
    call drawSideMenuCursor
TOGGLE_DONE:
    ret
toggleMenuState ENDP

handleSideMenuInput PROC USES eax
    cmp ax, 4800h ; UP
    je MENU_UP
    cmp ax, 5000h ; DOWN
    je MENU_DOWN
    cmp ax, 1C0Dh ; ENTER
    je MENU_SELECT
    jmp MENU_INPUT_DONE

MENU_UP:
    call clearSideMenuCursor      
    dec sideMenuCursorIndex
    cmp sideMenuCursorIndex, 0
    jge UPDATE_CURSOR
    mov sideMenuCursorIndex, 4    
    jmp UPDATE_CURSOR

MENU_DOWN:
    call clearSideMenuCursor      
    inc sideMenuCursorIndex
    cmp sideMenuCursorIndex, 4
    jle UPDATE_CURSOR
    mov sideMenuCursorIndex, 0    
    jmp UPDATE_CURSOR

UPDATE_CURSOR:
    call drawSideMenuCursor       
    jmp MENU_INPUT_DONE

MENU_SELECT:
    mov eax, sideMenuCursorIndex
    inc eax                       
    mov bl, al                    
    call addTowerWithType
    call restoreGraphicsAtPos 
    call toggleMenuState          
    jmp MENU_INPUT_DONE

MENU_INPUT_DONE:
    ret
handleSideMenuInput ENDP

handleNormalInput PROC USES eax ebx
    cmp ax, 4800h ; UP
    je HANDLE_UP
    cmp ax, 5000h ; DOWN
    je HANDLE_DOWN
    cmp ax, 4B00h ; LEFT
    je HANDLE_LEFT
    cmp ax, 4D00h ; RIGHT
    je HANDLE_RIGHT
    cmp ax, 2d78h ; 'x' -> Delete
    je HANDLE_X
    jmp END_NORMAL_INPUT

HANDLE_UP:
    sub blockPos.Y, blockHeight
    mov bx, blockPosInit.Y
    cmp blockPos.Y, bx
    jge END_NORMAL_INPUT
    add blockPos.Y, blockHeight 
    jmp END_NORMAL_INPUT

HANDLE_DOWN:
    add blockPos.Y, blockHeight
    mov bx, (blockHeight * 7)
    add bx, blockPosInit.Y
    cmp blockPos.Y, bx
    jbe END_NORMAL_INPUT
    sub blockPos.Y, blockHeight
    jmp END_NORMAL_INPUT

HANDLE_LEFT:
    sub blockPos.X, blockWidth
    mov bx, blockPosInit.X
    cmp blockPos.X, bx
    jae END_NORMAL_INPUT
    add blockPos.X, blockWidth
    jmp END_NORMAL_INPUT

HANDLE_RIGHT:
    add blockPos.X, blockWidth
    mov bx, (blockWidth * 15)
    add bx, blockPosInit.X
    cmp blockPos.X, bx
    jbe END_NORMAL_INPUT
    sub blockPos.X, blockWidth
    jmp END_NORMAL_INPUT
    
HANDLE_X:
    call deleteTower 
    call restoreGraphicsAtPos
    
END_NORMAL_INPUT:
    ret
handleNormalInput ENDP

outerBox PROC USES eax ecx
    mov ax, outerBoxPosInit.X
    mov outerBoxPos.X, ax
    mov ax, outerBoxPosInit.Y
    mov outerBoxPos.Y, ax
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxTop, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    mov ecx, outerBoxHeight-2
L1: push ecx
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBody, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop ecx
    loop L1
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBottom, outerBoxWidth, outerBoxPos, ADDR count
    ret
outerBox ENDP

initBlock PROC USES eax
    mov ax, blockPosInit.X
    mov blockPos.X, ax
    mov blockPos.Y, ax
    mov prevBlockPos.X, ax 
    mov prevBlockPos.Y, ax
    ret
initBlock ENDP

drawMovingDashedCursor PROC USES eax esi edi
    push DWORD PTR outerBoxPos
    mov ax, blockPos.X
    mov dx, blockPos.Y
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, dx
    mov esi, OFFSET dashStyle1
    cmp dashAnimState, 1
    jne USE_STYLE
    mov esi, OFFSET dashStyle2
USE_STYLE:
    mov al, [esi+0] 
    mov tempBuffer, al
    mov al, [esi+1] 
    mov tempBuffer+1, al
    mov al, [esi+2] 
    mov tempBuffer+2, al
    mov al, [esi+3] 
    mov tempBuffer+3, al
    mov al, [esi+4] 
    mov tempBuffer+4, al
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    mov al, [esi+5]     
    mov tempBuffer, al
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, 1, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, 1, outerBoxPos, ADDR count
    add outerBoxPos.X, 4
    mov al, [esi+6]     
    mov tempBuffer, al
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, 1, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, 1, outerBoxPos, ADDR count
    sub outerBoxPos.X, 4
    inc outerBoxPos.Y
    mov al, [esi+7]
    mov tempBuffer, al
    mov al, [esi+8]
    mov tempBuffer+1, al
    mov al, [esi+9]
    mov tempBuffer+2, al
    mov al, [esi+10]
    mov tempBuffer+3, al
    mov al, [esi+11]
    mov tempBuffer+4, al
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    pop DWORD PTR outerBoxPos
    ret
drawMovingDashedCursor ENDP

hasMapComponentAtCursor PROC USES ebx ecx esi
    movzx eax, blockPos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax    
    movzx eax, blockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx         
    cmp ebx, MAP_WIDTH
    jge NO_MAP_COMPONENT
    cmp eax, MAP_HEIGHT
    jge NO_MAP_COMPONENT
    cmp ebx, 0
    jl NO_MAP_COMPONENT
    cmp eax, 0
    jl NO_MAP_COMPONENT
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    cmp al, COMPONENT_EMPTY
    je NO_MAP_COMPONENT
    mov eax, 1
    ret
NO_MAP_COMPONENT:
    mov eax, 0
    ret
hasMapComponentAtCursor ENDP

updateDashAnimation PROC
    inc dashTimer
    cmp dashTimer, DASH_SPEED
    jl NO_ANIM_CHANGE
    mov dashTimer, 0
    xor dashAnimState, 1  
NO_ANIM_CHANGE:
    ret
updateDashAnimation ENDP

restoreGraphicsAtPos PROC USES eax ebx ecx esi edi
    push DWORD PTR outerBoxPos
    mov ax, prevBlockPos.X
    mov outerBoxPos.X, ax
    mov ax, prevBlockPos.Y
    mov outerBoxPos.Y, ax
    call getTowerTypeAtPos
    cmp eax, 0
    je RESTORE_MAP
    cmp al, 1
    je DRAW_A
    cmp al, 2
    je DRAW_B
    cmp al, 3
    je DRAW_C
    cmp al, 4
    je DRAW_D
    cmp al, 5
    je DRAW_E
    jmp RESTORE_DONE
DRAW_A: call drawATower
        jmp RESTORE_DONE
DRAW_B: call drawBTower
        jmp RESTORE_DONE
DRAW_C: call drawCTower
        jmp RESTORE_DONE
DRAW_D: call drawDTower
        jmp RESTORE_DONE
DRAW_E: call drawETower
        jmp RESTORE_DONE
RESTORE_MAP:
    movzx eax, prevBlockPos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax    
    movzx eax, prevBlockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx         
    cmp ebx, MAP_WIDTH
    jge RESTORE_DONE
    cmp eax, MAP_HEIGHT
    jge RESTORE_DONE
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi] 
    movzx eax, cl
    mov edx, 15
    mul edx
    mov esi, OFFSET componentChars
    add esi, eax
    mov ecx, blockHeight
DRAW_RESTORE_LOOP:
    push ecx
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, blockWidth, outerBoxPos, ADDR count
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    add esi, blockWidth
    inc outerBoxPos.Y
    pop ecx
    loop DRAW_RESTORE_LOOP
RESTORE_DONE:
    pop DWORD PTR outerBoxPos
    ret
restoreGraphicsAtPos ENDP

getTowerTypeAtPos PROC USES ebx ecx esi
    mov ecx, 0
CHECK_LOOP:
    cmp ecx, towerCount
    jge NOT_FOUND
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, prevBlockPos.X 
    jne NEXT
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, prevBlockPos.Y 
    jne NEXT
    mov esi, OFFSET towersType
    mov eax, ecx
    add esi, eax
    movzx eax, BYTE PTR [esi]
    ret
NEXT:
    inc ecx
    jmp CHECK_LOOP
NOT_FOUND:
    mov eax, 0
    ret
getTowerTypeAtPos ENDP

; =================================================================================
; 遊戲主迴圈 (Main Loop) - 簡化版 (0=準備, 1=戰鬥)
; =================================================================================
moveBlock PROC
START_MOVE:
    call updateDashAnimation    
    call restoreGraphicsAtPos
    call drawMovingDashedCursor 
    mov ax, blockPos.X
    mov prevBlockPos.X, ax
    mov ax, blockPos.Y
    mov prevBlockPos.Y, ax

    ; 檢查是否開啟選單 (選單開啟時暫停其他繪製或覆蓋)
    cmp menuState, 1
    je DRAW_MENU_STATE
    jmp AFTER_DRAW

DRAW_MENU_STATE:
AFTER_DRAW:

    ; =========================================================
    ; 戰鬥狀態檢查 (State: 1 = 戰鬥中)
    ; =========================================================
    cmp startWave, 1          
    jne SKIP_COMBAT_LOGIC     ; 如果是 0 (準備期)，跳過怪物更新
    
    ; --- 戰鬥中邏輯 (每一幀都執行) ---
    call updateMonstersPositions      
    call removeMonsters  	 
    call drawMonsters
    
    ; [注意]
    ; 你需要在 monsters.asm 的 removeMonsters 裡判斷：
    ; 如果怪物數量 (monsterCount) 歸零，就執行 mov startWave, 0
    ; 這樣才能自動回到準備期

SKIP_COMBAT_LOGIC:	
    ; =========================================================
	
    mov eax, 50                 
    call Delay
    
    call ReadKey
    jz NO_KEY_PRESSED
    
    ; ---------------------------------------------------------
    ; [G鍵] 開始戰鬥 (僅在準備期有效)
    ; ---------------------------------------------------------
    .IF (al == 'g') || (al == 'G')
        .IF (startWave == 0) && (menuState == 0)
            ; 1. 先生成怪物 (只執行這一次)
            invoke createMonsters, cur_round
            
            ; 2. 切換狀態為 1 (戰鬥開始)
            mov startWave, 1      
        .ENDIF
    .ENDIF

    ; ---------------------------------------------------------
    ; [F鍵] 開啟選單 (僅在準備期有效)
    ; ---------------------------------------------------------
    .IF ax == 2166h ; 'f'
        ; 只有在 "準備期 (0)" 才允許蓋塔
        .IF startWave == 0
            call toggleMenuState
        .ENDIF
    .ENDIF
	
    cmp menuState, 1
    je HANDLE_MENU_INPUT_LABEL        
    
    ; 移動控制 (戰鬥中、準備期皆可移動)
    call handleNormalInput      
    jmp END_INPUT_CHECK

HANDLE_MENU_INPUT_LABEL:
    call handleSideMenuInput

NO_KEY_PRESSED:
END_INPUT_CHECK:

    .IF ax == 011Bh ; ESC 
        call showEscMenu
        
        .IF eax == 1  ; Continue
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawAllTowers
            call drawSideMenu
        .ELSEIF eax == 2  ; Restart
            mov towerCount, 0
            mov startWave, 0      ; 重置回準備期
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawSideMenu
        .ELSEIF eax == 3  ; How to Play
            call showHowToPlay
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawAllTowers
            call drawSideMenu
        .ELSEIF eax == 4  ; End Game
            jmp EXIT_MOVE
        .ENDIF
    .ENDIF

    jmp START_MOVE
EXIT_MOVE:
    ret
moveBlock ENDP

; =================================================================================
; 新增塔到陣列中
; =================================================================================
addTowerWithType PROC USES eax ecx esi
    call checkTowerAtCurrentPosition
    cmp eax, 1
    je NO_ADD_TYPE
    call canPlaceTowerAtCurrentPos
    cmp eax, 0
    je NO_ADD_TYPE
    mov eax, towerCount
    cmp eax, towerMax
    jge NO_ADD_TYPE
    mov ecx, eax
    mov esi, OFFSET towersPosX
    imul eax, 2
    add esi, eax
    mov ax, blockPos.X
    mov WORD PTR [esi], ax
    mov esi, OFFSET towersPosY
    mov eax, ecx
    imul eax, 2
    add esi, eax
    mov ax, blockPos.Y
    mov WORD PTR [esi], ax
    mov esi, OFFSET towersType
    mov eax, ecx
    add esi, eax
    mov BYTE PTR [esi], bl
    inc towerCount
NO_ADD_TYPE:
    ret
addTowerWithType ENDP

checkTowerAtCurrentPosition PROC USES ebx ecx esi
    mov ecx, 0
CHECK_POS_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_HERE
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.X
    jne NEXT_CHECK_POS
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.Y
    je TOWER_HERE
NEXT_CHECK_POS:
    inc ecx
    jmp CHECK_POS_LOOP
TOWER_HERE:
    mov eax, 1
    ret
NO_TOWER_HERE:
    mov eax, 0
    ret
checkTowerAtCurrentPosition ENDP

deleteTower PROC USES eax ebx ecx esi
    cmp towerCount, 0
    je DELETE_DONE
    mov ecx, 0
CHECK_TOWER_LOOP:
    cmp ecx, towerCount
    jge DELETE_DONE
    call isTowerAtPositionSimple
    cmp eax, 1
    je DELETE_FOUND_TOWER
    inc ecx
    jmp CHECK_TOWER_LOOP
DELETE_FOUND_TOWER:
    call removeTowerAtIndexSimple
DELETE_DONE:
    ret
deleteTower ENDP

isTowerAtPositionSimple PROC USES ebx esi
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.X
    jne NOT_MATCH_SIMPLE
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.Y
    je TOWER_FOUND_AT_POSITION
NOT_MATCH_SIMPLE:
    mov eax, 0
    ret
TOWER_FOUND_AT_POSITION:
    mov eax, 1
    ret
isTowerAtPositionSimple ENDP

removeTowerAtIndexSimple PROC USES eax ebx edx esi edi
    mov eax, ecx
    mov ebx, towerCount
    dec ebx
    cmp eax, ebx
    jge JUST_DECREASE_COUNT_SIMPLE
    mov edx, eax
    mov esi, OFFSET towersPosX
    mov eax, edx
    imul eax, 2
    add esi, eax
    mov edi, esi
    add esi, 2
    mov eax, ebx
    sub eax, edx
MOVE_X_LOOP_SIMPLE:
    cmp eax, 0
    je MOVE_Y_ARRAY_SIMPLE
    mov cx, WORD PTR [esi]
    mov WORD PTR [edi], cx
    add esi, 2
    add edi, 2
    dec eax
    jmp MOVE_X_LOOP_SIMPLE
MOVE_Y_ARRAY_SIMPLE:
    mov esi, OFFSET towersPosY
    mov eax, edx
    imul eax, 2
    add esi, eax
    mov edi, esi
    add esi, 2
    mov eax, ebx
    sub eax, edx
MOVE_Y_LOOP_SIMPLE:
    cmp eax, 0
    je MOVE_TYPE_ARRAY_SIMPLE
    mov cx, WORD PTR [esi]
    mov WORD PTR [edi], cx
    add esi, 2
    add edi, 2
    dec eax
    jmp MOVE_Y_LOOP_SIMPLE
MOVE_TYPE_ARRAY_SIMPLE:
    mov esi, OFFSET towersType
    mov eax, edx
    add esi, eax
    mov edi, esi
    inc esi
    mov eax, ebx
    sub eax, edx
MOVE_TYPE_LOOP_SIMPLE:
    cmp eax, 0
    je JUST_DECREASE_COUNT_SIMPLE
    mov cl, BYTE PTR [esi]
    mov BYTE PTR [edi], cl
    inc esi
    inc edi
    dec eax
    jmp MOVE_TYPE_LOOP_SIMPLE
JUST_DECREASE_COUNT_SIMPLE:
    dec towerCount
    ret
removeTowerAtIndexSimple ENDP

; [修正] drawTower 現在正確讀取堆疊參數 (Index) 並自行查表取得座標
drawTower PROC USES eax ebx ecx edi esi
    ; 堆疊結構: [ESP+24] = Tower Index (由 drawAllTowers 的 push ecx 傳入)
    
    mov edi, [esp+24]      ; 取得 Index

    push DWORD PTR outerBoxPos

    ; 取得 X 座標
    mov esi, OFFSET towersPosX
    mov ebx, edi
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.X, ax

    ; 取得 Y 座標
    mov esi, OFFSET towersPosY
    mov ebx, edi
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.Y, ax

    ; 取得 Type 並繪製
    mov esi, OFFSET towersType
    mov eax, edi
    add esi, eax
    mov bl, BYTE PTR [esi]
    
    cmp bl, 1
    je DRAW_TOWER_A
    cmp bl, 2
    je DRAW_TOWER_B
    cmp bl, 3
    je DRAW_TOWER_C
    cmp bl, 4
    je DRAW_TOWER_D
    cmp bl, 5
    je DRAW_TOWER_E
    call drawATower
    jmp DRAW_TOWER_DONE

DRAW_TOWER_A: call drawATower
    jmp DRAW_TOWER_DONE
DRAW_TOWER_B: call drawBTower
    jmp DRAW_TOWER_DONE
DRAW_TOWER_C: call drawCTower
    jmp DRAW_TOWER_DONE
DRAW_TOWER_D: call drawDTower
    jmp DRAW_TOWER_DONE
DRAW_TOWER_E: call drawETower
DRAW_TOWER_DONE:
    pop DWORD PTR outerBoxPos
    ret 4 ; 清除堆疊中的一個參數 (Index)
drawTower ENDP

initMapSystem PROC USES eax ecx esi edi
    mov esi, OFFSET map1Data
    mov edi, OFFSET mapData
    mov ecx, (MAP_WIDTH * MAP_HEIGHT)
    rep movsb
    ret
initMapSystem ENDP

canPlaceTowerAtCurrentPos PROC USES ebx ecx esi
    movzx eax, blockPos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax
    movzx eax, blockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx
    cmp ebx, MAP_WIDTH
    jge CANNOT_PLACE
    cmp eax, MAP_HEIGHT
    jge CANNOT_PLACE
    cmp ebx, 0
    jl CANNOT_PLACE
    cmp eax, 0
    jl CANNOT_PLACE
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    cmp al, COMPONENT_EMPTY
    je CAN_PLACE
CANNOT_PLACE:
    mov eax, 0
    ret
CAN_PLACE:
    mov eax, 1
    ret
canPlaceTowerAtCurrentPos ENDP

drawMapComponents PROC USES eax ebx ecx edx esi edi
    mov eax, 0
DRAW_MAP_Y_LOOP:
    cmp eax, MAP_HEIGHT
    jge DRAW_MAP_DONE
    mov ebx, 0
DRAW_MAP_X_LOOP:
    cmp ebx, MAP_WIDTH
    jge NEXT_MAP_Y
    push eax
    push ebx
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi]
    pop ebx
    pop eax
    call drawComponent
NEXT_MAP_X:
    inc ebx
    jmp DRAW_MAP_X_LOOP
NEXT_MAP_Y:
    inc eax
    jmp DRAW_MAP_Y_LOOP
DRAW_MAP_DONE:
    ret
drawMapComponents ENDP

drawComponent PROC USES eax ebx ecx edx esi edi
    push ecx
    call calculateScreenPosition 
    pop ecx
    movzx eax, cl
    mov edx, 15                  
    mul edx
    mov esi, OFFSET componentChars
    add esi, eax
    mov ecx, blockHeight
DRAW_COMPONENT_Y_LOOP:
    push ecx
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, blockWidth, outerBoxPos, ADDR count
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    add esi, blockWidth
    inc outerBoxPos.Y
    pop ecx
    loop DRAW_COMPONENT_Y_LOOP
    ret
drawComponent ENDP

calculateScreenPosition PROC
    push ebx
    push eax
    mov eax, ebx
    mov ecx, blockWidth
    mul ecx
    add eax, 7
    mov outerBoxPos.X, ax
    pop eax
    push eax
    mov ecx, blockHeight
    mul ecx
    add eax, 4
    mov outerBoxPos.Y, ax
    pop eax
    pop ebx
    ret
calculateScreenPosition ENDP

; =================================================================================
; 各式防禦塔外觀 (精細化 + 白底黑字)
; =================================================================================

drawATower PROC USES esi
    mov esi, OFFSET attrTowerA 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 2Fh   
    mov tempBuffer+2, 0CFh  
    mov tempBuffer+3, 5Ch   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 7Ch   
    mov tempBuffer+2, 0DBh  
    mov tempBuffer+3, 7Ch   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Eh      
    mov tempBuffer+1, 23h    
    mov tempBuffer+2, 23h    
    mov tempBuffer+3, 23h    
    mov tempBuffer+4, 1Eh    
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawATower ENDP

drawBTower PROC USES esi
    mov esi, OFFSET attrTowerB
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 20h   
    mov tempBuffer+2, 20h   
    mov tempBuffer+3, 20h   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0C4h    
    mov tempBuffer+1, 0CDh  
    mov tempBuffer+2, 0D1h  
    mov tempBuffer+3, 0C6h  
    mov tempBuffer+4, 0CBh  
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 5Eh   
    mov tempBuffer+2, 20h   
    mov tempBuffer+3, 20h   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawBTower ENDP

drawCTower PROC USES esi
    mov esi, OFFSET attrTowerC
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 2Fh   
    mov tempBuffer+2, 29h   
    mov tempBuffer+3, 20h   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 3Ch     
    mov tempBuffer+1, 2Dh   
    mov tempBuffer+2, 2Dh   
    mov tempBuffer+3, 23h   
    mov tempBuffer+4, 23h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 5Ch   
    mov tempBuffer+2, 29h   
    mov tempBuffer+3, 20h   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawCTower ENDP

drawDTower PROC USES esi
    mov esi, OFFSET attrTowerD
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h
    mov tempBuffer+1, 0DAh  
    mov tempBuffer+2, 0E8h  
    mov tempBuffer+3, 0BFh  
    mov tempBuffer+4, 20h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h
    mov tempBuffer+1, 0C0h  
    mov tempBuffer+2, 0B3h  
    mov tempBuffer+3, 0D9h  
    mov tempBuffer+4, 20h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h
    mov tempBuffer+1, 0C4h  
    mov tempBuffer+2, 0CAh  
    mov tempBuffer+3, 0C4h  
    mov tempBuffer+4, 20h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawDTower ENDP

drawETower PROC USES esi
    mov esi, OFFSET attrTowerC
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 20h   
    mov tempBuffer+2, 1Eh   
    mov tempBuffer+3, 20h   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     
    mov tempBuffer+1, 7Ch   
    mov tempBuffer+2, 23h   
    mov tempBuffer+3, 7Ch   
    mov tempBuffer+4, 20h   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 2Fh     
    mov tempBuffer+1, 23h   
    mov tempBuffer+2, 7Ch   
    mov tempBuffer+3, 23h   
    mov tempBuffer+4, 5Ch   
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawETower ENDP

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

INCLUDE monsters.asm

END main