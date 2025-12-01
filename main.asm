INCLUDE Irvine32.inc
;INCLUDE monsters.asm 為了讓 monsters.asm 能讀取到 main.asm 裡的常數（如 MAP_WIDTH）與變數（如 outputHandle），故將INCLUDE monsters.asm 移到最後面（在 END main 之前）。

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

; [修正 1] 新增怪物相關的原型宣告 (INVOKE 需要 PROTO)
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

; 塔的名稱字串 (補齊長度以便清除)
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

; [修正 2] 新增缺失的變數定義
startWave       DWORD 0       ; 用於控制是否開始生怪
cur_round       DWORD 1       ; 當前回合數

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
menuPrompt      BYTE "Use Arrow Keys to select, ENTER to confirm", 0

; 使用說明文字
helpTitle       BYTE "========== HOW TO PLAY ==========", 0
helpLine1       BYTE "Arrow Keys: Move cursor", 0
helpLine2       BYTE "A/B/C/D/E: Place tower (type A-E)", 0
helpLine3       BYTE "X: Delete tower", 0
helpLine4       BYTE "ESC: Open menu", 0
helpLine5       BYTE "Towers can only be placed on empty tiles", 0
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
    
    ; 清空畫面
    call Clrscr
    
    ; 顯示標題第一行
    mov dh, 8
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle1
    call WriteString
    
    ; 顯示標題第二行
    mov dh, 9
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle2
    call WriteString
    
    ; 顯示標題第三行
    mov dh, 10
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle3
    call WriteString
    
    ; 顯示標題第四行
    mov dh, 11
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle4
    call WriteString
    
    ; 顯示標題第五行
    mov dh, 12
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle5
    call WriteString
    
    ; 顯示標題第六行
    mov dh, 13
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle6
    call WriteString
    
    ; 空兩行後顯示提示訊息
    mov dh, 16
    mov dl, 22
    call Gotoxy
    mov edx, OFFSET startPrompt
    call WriteString
    call Gotoxy
    mov edx, OFFSET startPrompt
    call WriteString
    
    ; 等待使用者按下 ENTER 鍵
WAIT_ENTER:
    call ReadChar
    cmp al, 13  ; 13 = ENTER 鍵的 ASCII 碼
    jne WAIT_ENTER
    
    ; 清空畫面準備進入遊戲
    call Clrscr
    
    ret
showStartScreen ENDP

; =================================================================================
; 顯示 ESC 選單
; =================================================================================
showEscMenu PROC USES ebx ecx edx
    ; 初始化游標位置為第一個選項
    mov menuCursor, 0
    
MENU_LOOP:
    ; 清空畫面
    call Clrscr
    
    ; 顯示選單標題
    mov dh, 8
    mov dl, 27
    call Gotoxy
    mov edx, OFFSET menuTitle
    call WriteString
    
    ; 顯示選項 1 (Continue)
    mov dh, 10
    mov dl, 25
    call Gotoxy
    movzx eax, menuCursor
    cmp eax, 0
    jne SKIP_ARROW1
    mov edx, OFFSET menuArrow
    call WriteString
SKIP_ARROW1:
    mov dh, 10
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption1
    call WriteString
    
    ; 顯示選項 2 (Restart)
    mov dh, 11
    mov dl, 25
    call Gotoxy
    movzx eax, menuCursor
    cmp eax, 1
    jne SKIP_ARROW2
    mov edx, OFFSET menuArrow
    call WriteString
SKIP_ARROW2:
    mov dh, 11
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption2
    call WriteString
    
    ; 顯示選項 3 (How to Play)
    mov dh, 12
    mov dl, 25
    call Gotoxy
    movzx eax, menuCursor
    cmp eax, 2
    jne SKIP_ARROW3
    mov edx, OFFSET menuArrow
    call WriteString
SKIP_ARROW3:
    mov dh, 12
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption3
    call WriteString
    
    ; 顯示選項 4 (End Game)
    mov dh, 13
    mov dl, 25
    call Gotoxy
    movzx eax, menuCursor
    cmp eax, 3
    jne SKIP_ARROW4
    mov edx, OFFSET menuArrow
    call WriteString
SKIP_ARROW4:
    mov dh, 13
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET menuOption4
    call WriteString
    
    ; 顯示提示
    mov dh, 15
    mov dl, 18
    call Gotoxy
    mov edx, OFFSET menuPrompt
    call WriteString
    
    ; 等待使用者輸入
    call ReadKey
    jz MENU_LOOP
    
    ; 檢查上箭頭 (擴展鍵碼 4800h)
    cmp ax, 4800h
    je MENU_UP
    
    ; 檢查下箭頭 (擴展鍵碼 5000h)
    cmp ax, 5000h
    je MENU_DOWN
    
    ; 檢查 ENTER 鍵 (ASCII 13)
    cmp al, 13
    je MENU_SELECT
    
    ; 檢查 ESC 鍵 (返回遊戲)
    cmp ax, 011Bh
    je MENU_CANCEL
    
    jmp MENU_LOOP
    
MENU_UP:
    ; 向上移動游標
    movzx eax, menuCursor
    cmp eax, 0
    je MENU_LOOP  ; 已經在最上面
    dec menuCursor
    jmp MENU_LOOP
    
MENU_DOWN:
    ; 向下移動游標
    movzx eax, menuCursor
    cmp eax, MENU_OPTION_COUNT - 1
    jge MENU_LOOP  ; 已經在最下面
    inc menuCursor
    jmp MENU_LOOP
    
MENU_SELECT:
    ; 根據游標位置執行對應動作
    movzx eax, menuCursor
    inc eax  ; 返回 1-4
    jmp MENU_EXIT
    
MENU_CANCEL:
    ; ESC 鍵返回遊戲
    mov eax, 1  ; Continue
    
MENU_EXIT:
    ret
showEscMenu ENDP

; =================================================================================
; 顯示使用說明
; =================================================================================
showHowToPlay PROC USES edx
    call Clrscr
    
    ; 顯示標題
    mov dh, 6
    mov dl, 24
    call Gotoxy
    mov edx, OFFSET helpTitle
    call WriteString
    
    ; 顯示說明行 1
    mov dh, 8
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine1
    call WriteString
    
    ; 顯示說明行 2
    mov dh, 9
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine2
    call WriteString
    
    ; 顯示說明行 3
    mov dh, 10
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine3
    call WriteString
    
    ; 顯示說明行 4
    mov dh, 11
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine4
    call WriteString
    
    ; 顯示說明行 5
    mov dh, 12
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine5
    call WriteString
    
    ; 顯示提示
    mov dh, 15
    mov dl, 22
    call Gotoxy
    mov edx, OFFSET helpPrompt
    call WriteString
    
    ; 等待任意鍵
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
    
    ; 計算位置: Y = START_Y + (i * SPACING)
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

; =================================================================================
; 繪製側邊選單游標 + 顯示對應塔名稱
; =================================================================================
drawSideMenuCursor PROC USES eax
    mov eax, sideMenuCursorIndex
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    add eax, 1                  ; 對齊塔的中間
    
    mov sideMenuCursorPos.Y, ax
    mov ax, SIDE_MENU_X
    add ax, 6                   
    mov sideMenuCursorPos.X, ax
    
    ; 1. 畫游標 " << "
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuCursor, 4, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR menuCursorStr, 4, sideMenuCursorPos, ADDR count
    
    ; 2. 游標往右移，準備畫名字
    add sideMenuCursorPos.X, 5
    
    ; 3. 根據 sideMenuCursorIndex 決定畫哪個名字
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

; =================================================================================
; 清除側邊選單游標 + 清除名稱
; =================================================================================
clearSideMenuCursor PROC USES eax
    mov eax, sideMenuCursorIndex
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    add eax, 1
    
    mov sideMenuCursorPos.Y, ax
    mov ax, SIDE_MENU_X
    add ax, 6
    mov sideMenuCursorPos.X, ax
    
    ; 1. 清除游標 " << "
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 4, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 4, sideMenuCursorPos, ADDR count
    
    ; 2. 游標往右移，準備清除名字
    add sideMenuCursorPos.X, 5
    
    ; 3. 清除名字區域 (長度設為 10 確保清乾淨)
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 10, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 10, sideMenuCursorPos, ADDR count
    
    ret
clearSideMenuCursor ENDP

; =================================================================================
; 切換 遊戲/選單 模式
; =================================================================================
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

; =================================================================================
; 處理側邊選單輸入 (Enter 直接建造)
; =================================================================================
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

; [修正 3] 這裡原本有一個重複的 moveBlock，已刪除。
; 請直接接續 handleNormalInput

; =================================================================================
; 處理一般模式輸入
; =================================================================================
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

; =================================================================================
; 繪圖函式 (使用 F0h 白底屬性)
; =================================================================================

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
; 遊戲主迴圈 (Main Loop)
; =================================================================================
moveBlock PROC
START_MOVE:
    call updateDashAnimation    ; 更新動畫狀態
    

    call restoreGraphicsAtPos
    call drawMovingDashedCursor ; 畫地圖游標 (始終顯示)
    mov ax, blockPos.X
    mov prevBlockPos.X, ax
    mov ax, blockPos.Y
    mov prevBlockPos.Y, ax


    ; 檢查是否開啟選單
    cmp menuState, 1
    je DRAW_MENU_STATE
    jmp AFTER_DRAW

DRAW_MENU_STATE:
    ; call drawTowerMenu          ; 這裡你原本註解掉或呼叫不存在的函式，我先註解掉以免報錯，你的 drawSideMenu 已經畫好了
AFTER_DRAW:

	;怪物指令入口			---------------------------------------------------------	
    cmp startWave, 1		 ;注意:按下回合開始鍵要把startWave設成1以進入怪物指令入口
    jne SKIP_SPAWN			;--------------------------------------------------------
    invoke createMonsters, cur_round      
    mov startWave, 0         ; 避免無限生怪
SKIP_SPAWN:

    call updateMonstersPositions      ; 更新怪位置
    call removeMonsters  	 ; 移除怪
    call drawMonsters        ; 畫出怪
	
    mov eax, 50                 ; 延遲控制 Frame Rate
    call Delay
    
    call ReadKey
    jz NO_KEY_PRESSED
    
    .IF ax == 2166h ; 'f' 鍵 (開關選單)
        call toggleMenuState
    .ENDIF
	
    cmp menuState, 1
    je HANDLE_MENU_INPUT_LABEL        ; 選單模式輸入
    
    call handleNormalInput      ; 一般模式輸入
    jmp END_INPUT_CHECK

HANDLE_MENU_INPUT_LABEL:
    call handleSideMenuInput

NO_KEY_PRESSED:
END_INPUT_CHECK:

    .IF ax == 011Bh ; ESC 鍵開啟選單
        call showEscMenu
        
        .IF eax == 1  ; Continue - 返回遊戲
            ; 重繪遊戲畫面
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawAllTowers
            call drawSideMenu
        .ELSEIF eax == 2  ; Restart - 重新開始
            ; 清空塔資料並重繪
            mov towerCount, 0
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawSideMenu
        .ELSEIF eax == 3  ; How to Play - 顯示說明
            call showHowToPlay
            ; 顯示完說明後重繪遊戲畫面
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawAllTowers
            call drawSideMenu
        .ELSEIF eax == 4  ; End Game - 結束遊戲
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

drawTower PROC USES eax ebx ecx edi esi
    mov eax, [esp+24]
    push DWORD PTR outerBoxPos
    mov esi, OFFSET towersPosX
    mov ebx, eax
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.X, ax
    mov esi, OFFSET towersPosY
    mov eax, [esp+28]
    mov ebx, eax
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.Y, ax
    mov esi, OFFSET towersType
    mov eax, [esp+28]
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
    ret 4
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

; Tower A: 加農砲 (Cannon)
; Visual:
;  /╧\
;  |█|
; ▲###▲
drawATower PROC USES esi
    mov esi, OFFSET attrTowerA 
    
    ; Row 1:  /╧\ 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 2Fh   ; '/'
    mov tempBuffer+2, 0CFh  ; '╧' (上突出的連接座)
    mov tempBuffer+3, 5Ch   ; '\'
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 2: |█|
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 7Ch   ; '| '
    mov tempBuffer+2, 0DBh  ; '█' (側半填滿方塊，模擬砲管陰影或開口)
    mov tempBuffer+3, 7Ch   ; '|'
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 3: ▲###▲
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Eh      ; '▲'
    mov tempBuffer+1, 23h    ; '#'
    mov tempBuffer+2, 23h    ; '#'
    mov tempBuffer+3, 23h    ; '#'
    mov tempBuffer+4, 1Eh    ; '▲'
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    
    ret
drawATower ENDP

; Tower B: 狙擊槍 (Sniper) - 簡潔版
; 造型設計:
; Row 1: (空)
; Row 2: ─═╤╞╦  (模擬 ╾━╤デ╦)
; Row 3:  ▲     (左下角三角形腳架)
drawBTower PROC USES esi
    mov esi, OFFSET attrTowerB

    ; Row 1: 空白
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 20h   ; ' '
    mov tempBuffer+2, 20h   ; ' '
    mov tempBuffer+3, 20h   ; ' '
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; Row 2: ─═╤╞╦ (槍身)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0C4h    ; ─ (槍口)
    mov tempBuffer+1, 0CDh  ; ═ (槍管)
    mov tempBuffer+2, 0D1h  ; ╤ (瞄準鏡)
    mov tempBuffer+3, 0C6h  ; ╞ (槍身)
    mov tempBuffer+4, 0CBh  ; ╦ (槍托)
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; Row 3:  ▲    (三角形腳架)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 5Eh   ; ▲ (實心三角形，位於槍管下方)
    mov tempBuffer+2, 20h   ; ' '
    mov tempBuffer+3, 20h   ; ' '
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count

    ret
drawBTower ENDP


; Tower C: 寒冰箭 (Ice Arrow)
drawCTower PROC USES esi
    mov esi, OFFSET attrTowerC
    
    ; Row 1:   /) 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 2Fh   ; '/ '
    mov tempBuffer+2, 29h   ; ')'
    mov tempBuffer+3, 20h   ; ' '
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 2: <--##
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 3Ch     ; '<'
    mov tempBuffer+1, 2Dh   ; '-'
    mov tempBuffer+2, 2Dh   ; '-'
    mov tempBuffer+3, 23h   ; '#'
    mov tempBuffer+4, 23h   ; '#'
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 3:   \) 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 5Ch   ; '\'
    mov tempBuffer+2, 29h   ; ')'
    mov tempBuffer+3, 20h   ; ' '
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawCTower ENDP


; Tower D: 法師塔 (Mage) - 符文
drawDTower PROC USES esi
    mov esi, OFFSET attrTowerD
    ; Row 1: 魔法符文
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h
    mov tempBuffer+1, 0DAh  ; ┌
    mov tempBuffer+2, 0E8h  ; Φ
    mov tempBuffer+3, 0BFh  ; ┐
    mov tempBuffer+4, 20h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 2: 懸浮座
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h
    mov tempBuffer+1, 0C0h  ; └
    mov tempBuffer+2, 0B3h  ; │
    mov tempBuffer+3, 0D9h  ; ┘
    mov tempBuffer+4, 20h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 3: 法陣
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h
    mov tempBuffer+1, 0C4h  ; ─
    mov tempBuffer+2, 0CAh  ; ╩
    mov tempBuffer+3, 0C4h  ; ─
    mov tempBuffer+4, 20h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawDTower ENDP

; Tower E: 導彈 (missile) 
drawETower PROC USES esi
    mov esi, OFFSET attrTowerC
    ; Row 1:   ^   (Tip)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 20h   ; ' '
    mov tempBuffer+2, 1Eh   ; '^'
    mov tempBuffer+3, 20h   ; ' '
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 2:  |#|  (Shaft)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 7Ch   ; '|'
    mov tempBuffer+2, 23h   ; '#'
    mov tempBuffer+3, 7Ch   ; '|'
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; Row 3:  /#\  (Base)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 2Fh     ; '/'
    mov tempBuffer+1, 23h   ; '#'
    mov tempBuffer+2, 7Ch   ; '|'
    mov tempBuffer+3, 23h   ; '#'
    mov tempBuffer+4, 5Ch   ; '\'
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