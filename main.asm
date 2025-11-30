INCLUDE Irvine32.inc
INCLUDE monsters.asm

; =================================================================================
; 函式原型宣告 (Prototypes)
; =================================================================================
outerBox PROTO
initBlock PROTO
drawMovingDashedCursor PROTO
hasMapComponentAtCursor PROTO
clearMenuArea PROTO
toggleMenuState PROTO
handleNormalInput PROTO
handleMenuInput PROTO
drawTowerMenu PROTO
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

; =================================================================================
; 常數定義
; =================================================================================
main EQU start@0

; 介面尺寸
outerBoxWidth   = 84
outerBoxHeight  = 26

; 遊戲方塊 (Cursor/Tower) 尺寸
blockWidth      = 5
blockHeight     = 3

; 地圖系統常數
MAP_WIDTH       = 16
MAP_HEIGHT      = 8

; 地圖元件類型 ID
COMPONENT_EMPTY     = 0
COMPONENT_OUTLET    = 1
COMPONENT_EXIT      = 2
COMPONENT_PATH_H    = 3
COMPONENT_PATH_V    = 4
COMPONENT_CORNER_1  = 5
COMPONENT_CORNER_2  = 6
COMPONENT_CORNER_3  = 7
COMPONENT_CORNER_4  = 8

; 選單設定
TOWER_MENU_COUNT    EQU 5
MENU_START_X        EQU 20
MENU_START_Y        EQU 30

; 動畫設定
DASH_SPEED          EQU 8        ; 數值越大動畫越慢

.data
; =================================================================================
; 介面與繪圖資料
; =================================================================================
; 外框字元定義 (上、中、下)
outerBoxTop     BYTE 0DAh, 82 DUP(0C4h), 0BFh
outerBoxBody    BYTE 0B3h, 82 DUP(' '), 0B3h
outerBoxBottom  BYTE 0C0h, 82 DUP(0C4h), 0D9h

; Console Handle 相關
outputHandle    DWORD 0
bytesWritten    DWORD 0
count           DWORD 0
hConsole        HANDLE ?

; 座標位置
outerBoxPosInit COORD <5,3>     ; 遊戲框起始點
outerBoxPos     COORD <?, ?>    ; 繪圖游標暫存
blockPosInit    COORD <7, 4>    ; 玩家游標起始點
blockPos        COORD <?, ?>    ; 玩家目前位置

; 顏色屬性
cellsWritten    DWORD ?
outerAttributes WORD outerBoxWidth DUP(0F0h)  ; 白底黑字 (外框)
blockAttributes WORD blockWidth DUP(0F0h)     ; 白底黑字 (一般方塊)
emptyAttributes WORD 80 DUP(0F0h)             ; 清除用屬性
cursorAttr      WORD blockWidth DUP(0F0h)     ; 游標屬性 (白底黑字)

; 暫存緩衝區
tempBuffer      BYTE blockWidth DUP(?)
emptyLine       BYTE 60 DUP(' ')

; =================================================================================
; 塔 (Tower) 資料結構
; =================================================================================
towerMax        EQU 30 
towersPosX      WORD towerMax DUP(?)  ; 塔的 X 座標陣列
towersPosY      WORD towerMax DUP(?)  ; 塔的 Y 座標陣列
towersType      BYTE towerMax DUP(?)  ; 塔的類型陣列
towerCount      DWORD 0               ; 目前塔的數量

; 選單相關變數
menuState           DWORD 0           ; 0: 遊戲模式, 1: 選單模式
selectedTowerIndex  DWORD 0           ; 目前選中的塔索引
towerTypes          BYTE 1, 2, 3, 4, 5

; =================================================================================
; 動畫與游標樣式
; =================================================================================
dashTimer       DWORD 0       
dashAnimState   DWORD 0       ; 0 或 1，用於切換虛線樣式
; 定義跑馬燈游標樣式 ('-' 橫線, '|' 直線, ' ' 空白)
; 順序：上(5) -> 左中(1) -> 右中(1) -> 下(5)
dashStyle1      BYTE '-', ' ', '-', ' ', '-'   ; Top 
                BYTE ' ', ' '                  ; Mid L, Mid R (鏤空)
                BYTE '-', ' ', '-', ' ', '-'   ; Bot 

dashStyle2      BYTE ' ', '-', ' ', '-', ' '   ; Top 
                BYTE '|', '|'                  ; Mid L, Mid R (填補)
                BYTE ' ', '-', ' ', '-', ' '   ; Bot 

; =================================================================================
; 地圖資料
; =================================================================================
mapData BYTE (MAP_WIDTH * MAP_HEIGHT) DUP(0)

; 預設地圖配置 (0=空地, 其他=路徑/障礙)
map1Data BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
         BYTE 0,1,0,6,3,3,3,3,3,3,3,5,0,2,0,0
         BYTE 0,4,0,4,0,0,0,0,0,0,0,4,0,4,0,0
         BYTE 0,4,0,4,0,0,6,3,3,3,3,8,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,7,3,8,0,0,7,3,3,3,3,3,3,8,0,0
         BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; 元件 ASCII 圖形資料
componentChars LABEL BYTE
component0 BYTE 5 DUP(20h), 5 DUP(20h), 5 DUP(20h)
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
    mov hConsole, eax
    INVOKE SetConsoleTextAttribute, hConsole, 0f0h ; 設定預設為白底黑字
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    call Clrscr 
    call outerBox       ; 繪製遊戲邊框

    call initMapSystem  ; 初始化地圖
    call initBlock      ; 初始化游標位置
    call moveBlock      ; 進入遊戲主迴圈
    
    call Clrscr
    exit
main ENDP

; =================================================================================
; 繪製遊戲外框
; =================================================================================
outerBox PROC USES eax ecx
    mov ax, outerBoxPosInit.X
    mov outerBoxPos.X, ax
    mov ax, outerBoxPosInit.Y
    mov outerBoxPos.Y, ax

    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    
    ; 畫上邊框
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxTop, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 畫中間部分
    mov ecx, outerBoxHeight-2
L1:
    push ecx
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBody, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop ecx
    loop L1

    ; 畫下邊框
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBottom, outerBoxWidth, outerBoxPos, ADDR count
    ret
outerBox ENDP

; =================================================================================
; 初始化游標位置
; =================================================================================
initBlock PROC USES eax
    mov ax, blockPosInit.X
    mov blockPos.X, ax
    mov ax, blockPosInit.Y
    mov blockPos.Y, ax
    ret
initBlock ENDP

; =================================================================================
; 繪製動態虛線游標 (中間鏤空)
; =================================================================================
drawMovingDashedCursor PROC USES eax esi edi
    push DWORD PTR outerBoxPos
    
    ; 設定繪製起點為 blockPos
    mov ax, blockPos.X
    mov dx, blockPos.Y
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, dx

    ; 根據動畫狀態(0/1)選擇樣式
    mov esi, OFFSET dashStyle1
    cmp dashAnimState, 1
    jne USE_STYLE
    mov esi, OFFSET dashStyle2
USE_STYLE:
    
    ; --- 1. 上邊框 ---
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

    ; --- 2. 左右邊框 (中間跳過不畫) ---
    ; 左邊框
    mov al, [esi+5]     
    mov tempBuffer, al
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, 1, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, 1, outerBoxPos, ADDR count
    
    ; 跳過中間 3 格
    add outerBoxPos.X, 4
    
    ; 右邊框
    mov al, [esi+6]     
    mov tempBuffer, al
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, 1, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, 1, outerBoxPos, ADDR count
    
    ; 復歸 X 並換行
    sub outerBoxPos.X, 4
    inc outerBoxPos.Y

    ; --- 3. 下邊框 ---
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

; =================================================================================
; 檢查游標位置是否有地圖元件
; 回傳: EAX=1 (有元件), EAX=0 (空)
; =================================================================================
hasMapComponentAtCursor PROC USES ebx ecx esi
    ; 計算 Grid X
    movzx eax, blockPos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax    ; EBX = Grid X
    
    ; 計算 Grid Y
    movzx eax, blockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx         ; EAX = Grid Y

    ; 邊界檢查
    cmp ebx, MAP_WIDTH
    jge NO_MAP_COMPONENT
    cmp eax, MAP_HEIGHT
    jge NO_MAP_COMPONENT
    cmp ebx, 0
    jl NO_MAP_COMPONENT
    cmp eax, 0
    jl NO_MAP_COMPONENT

    ; 計算 Map Array Index: (Y * Width) + X
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    
    ; 檢查內容
    mov al, BYTE PTR [esi]
    cmp al, COMPONENT_EMPTY
    je NO_MAP_COMPONENT
    mov eax, 1
    ret
NO_MAP_COMPONENT:
    mov eax, 0
    ret
hasMapComponentAtCursor ENDP

; =================================================================================
; 清除選單區域 (用空白覆蓋)
; =================================================================================
clearMenuArea PROC USES eax ecx
    mov outerBoxPos.X, MENU_START_X
    mov outerBoxPos.Y, MENU_START_Y
    mov ecx, 3 
CLEAR_MENU_LOOP:
    push ecx
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 60, outerBoxPos, ADDR count
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR emptyAttributes, 60, outerBoxPos, ADDR cellsWritten
    inc outerBoxPos.Y
    pop ecx
    loop CLEAR_MENU_LOOP
    ret
clearMenuArea ENDP

; =================================================================================
; 切換選單/遊戲狀態
; =================================================================================
toggleMenuState PROC
    mov eax, menuState
    xor eax, 1             ; 0 <-> 1 切換
    mov menuState, eax
    cmp eax, 0
    jne MENU_OPENED
    call clearMenuArea     ; 如果關閉選單，清除該區域
MENU_OPENED:
    ret
toggleMenuState ENDP

; =================================================================================
; 處理一般模式輸入 (移動、刪除塔)
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
    cmp ax, 2d78h ; 'x' 鍵
    je HANDLE_X
    jmp END_NORMAL_INPUT

HANDLE_UP:
    sub blockPos.Y, blockHeight
    mov bx, blockPosInit.Y
    cmp blockPos.Y, bx
    jge END_NORMAL_INPUT
    add blockPos.Y, blockHeight ; 復原 (若超出邊界)
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
    call deleteTower ; 刪除當前位置的塔
    
END_NORMAL_INPUT:
    ret
handleNormalInput ENDP

; =================================================================================
; 處理選單模式輸入 (選擇塔、建造)
; =================================================================================
handleMenuInput PROC USES eax ebx ecx
    .IF al == 67h ; 'g' 鍵 (確認建造)
        mov eax, selectedTowerIndex
        mov esi, OFFSET towerTypes
        add esi, eax
        movzx ebx, BYTE PTR [esi] ; 取得選定的塔類型 ID
        
        call canPlaceTowerAtCurrentPos
        cmp eax, 1
        je PLACE_TOWER_AND_EXIT
        jmp END_MENU_HANDLE
        
PLACE_TOWER_AND_EXIT:
        call addTowerWithType ; 新增塔
        mov menuState, 0      ; 關閉選單
        call clearMenuArea 
    
    .ELSEIF ax == 4B00h ; Left Arrow
        mov eax, selectedTowerIndex
        cmp eax, 0
        je END_MENU_HANDLE
        dec selectedTowerIndex
    .ELSEIF ax == 4D00h ; Right Arrow
        mov eax, selectedTowerIndex
        inc eax
        cmp eax, TOWER_MENU_COUNT
        jge END_MENU_HANDLE
        mov selectedTowerIndex, eax
    .ENDIF
    
END_MENU_HANDLE:
    ret
handleMenuInput ENDP

; =================================================================================
; 繪製塔選單介面
; =================================================================================
drawTowerMenu PROC USES eax ebx ecx edx esi edi
    push DWORD PTR outerBoxPos
    mov ecx, 0 
L_MENU_LOOP:
    cmp ecx, TOWER_MENU_COUNT
    jge L_MENU_DONE

    ; 計算選單項目的螢幕座標
    mov eax, ecx
    imul eax, blockWidth
    imul eax, 2
    add eax, MENU_START_X
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, MENU_START_Y

    ; 取得對應的塔類型並繪製預覽
    mov esi, OFFSET towerTypes
    add esi, ecx
    mov bl, BYTE PTR [esi]

    push ecx
    cmp bl, 1
    je DRAW_MENU_A
    cmp bl, 2
    je DRAW_MENU_B
    cmp bl, 3
    je DRAW_MENU_C
    cmp bl, 4
    je DRAW_MENU_D
    cmp bl, 5
    je DRAW_MENU_E
    jmp DRAW_MENU_SKIP
DRAW_MENU_A: call drawATower
    jmp DRAW_MENU_SKIP
DRAW_MENU_B: call drawBTower
    jmp DRAW_MENU_SKIP
DRAW_MENU_C: call drawCTower
    jmp DRAW_MENU_SKIP
DRAW_MENU_D: call drawDTower
    jmp DRAW_MENU_SKIP
DRAW_MENU_E: call drawETower
DRAW_MENU_SKIP:
    pop ecx

    ; 如果是被選取的項目，在上面畫虛線框游標
    mov eax, ecx
    cmp eax, selectedTowerIndex
    jne NEXT_ITEM

    push blockPos.X 
    push blockPos.Y
    
    ; 暫時將 blockPos 指向選單位置以重用 drawMovingDashedCursor
    mov ax, outerBoxPos.X
    mov blockPos.X, ax
    mov ax, outerBoxPos.Y
    mov blockPos.Y, ax
    
    call drawMovingDashedCursor 
    
    pop blockPos.Y
    pop blockPos.X
    
NEXT_ITEM:
    inc ecx
    jmp L_MENU_LOOP
L_MENU_DONE:
    pop DWORD PTR outerBoxPos
    ret
drawTowerMenu ENDP

; =================================================================================
; 更新虛線動畫計時器
; =================================================================================
updateDashAnimation PROC
    inc dashTimer
    cmp dashTimer, DASH_SPEED
    jl NO_ANIM_CHANGE
    
    mov dashTimer, 0
    xor dashAnimState, 1  ; 切換狀態 0 <-> 1
    
NO_ANIM_CHANGE:
    ret
updateDashAnimation ENDP

; =================================================================================
; 遊戲主迴圈 (Main Loop)
; =================================================================================
moveBlock PROC
START_MOVE:
    call updateDashAnimation    ; 更新動畫狀態
    
    call drawMapComponents      ; 畫地圖 (底層)
    call drawAllTowers          ; 畫已建造的塔
    call drawMovingDashedCursor ; 畫地圖游標 (始終顯示)
    
    ; 檢查是否開啟選單
    cmp menuState, 1
    je DRAW_MENU_STATE
    jmp AFTER_DRAW

DRAW_MENU_STATE:
    call drawTowerMenu          ; 繪製選單
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
    je HANDLE_MENU_INPUT        ; 選單模式輸入
    
    call handleNormalInput      ; 一般模式輸入
    jmp END_INPUT_CHECK

HANDLE_MENU_INPUT:
    call handleMenuInput

NO_KEY_PRESSED:
END_INPUT_CHECK:

    .IF ax == 011Bh ; ESC 鍵退出
        jmp EXIT_MOVE
    .ENDIF

    jmp START_MOVE
EXIT_MOVE:
    ret
moveBlock ENDP

; =================================================================================
; 新增塔到陣列中
; =================================================================================
addTowerWithType PROC USES eax ecx esi
    ; 1. 檢查位置是否有重複
    call checkTowerAtCurrentPosition
    cmp eax, 1
    je NO_ADD_TYPE
    
    ; 2. 檢查是否可以放置 (非路徑)
    call canPlaceTowerAtCurrentPos
    cmp eax, 0
    je NO_ADD_TYPE
    
    ; 3. 檢查數量是否達上限
    mov eax, towerCount
    cmp eax, towerMax
    jge NO_ADD_TYPE
    
    ; 儲存 X 座標
    mov ecx, eax
    mov esi, OFFSET towersPosX
    imul eax, 2
    add esi, eax
    mov ax, blockPos.X
    mov WORD PTR [esi], ax
    
    ; 儲存 Y 座標
    mov esi, OFFSET towersPosY
    mov eax, ecx
    imul eax, 2
    add esi, eax
    mov ax, blockPos.Y
    mov WORD PTR [esi], ax
    
    ; 儲存類型
    mov esi, OFFSET towersType
    mov eax, ecx
    add esi, eax
    mov BYTE PTR [esi], bl
    
    inc towerCount
NO_ADD_TYPE:
    ret
addTowerWithType ENDP

; =================================================================================
; 檢查當前位置是否已有塔
; =================================================================================
checkTowerAtCurrentPosition PROC USES ebx ecx esi
    mov ecx, 0
CHECK_POSITION_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_AT_POSITION
    
    ; Check X
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.X
    jne NEXT_TOWER_CHECK
    
    ; Check Y
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.Y
    je TOWER_FOUND_AT_POSITION
    
NEXT_TOWER_CHECK:
    inc ecx
    jmp CHECK_POSITION_LOOP
    
TOWER_FOUND_AT_POSITION:
    mov eax, 1
    ret
NO_TOWER_AT_POSITION:
    mov eax, 0
    ret
checkTowerAtCurrentPosition ENDP

; =================================================================================
; 刪除當前位置的塔 (封裝函式)
; =================================================================================
deleteTower PROC USES eax ebx ecx esi
    cmp towerCount, 0
    je NO_TOWER_FOUND
    mov ecx, 0
CHECK_TOWER_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_FOUND
    call isTowerAtPositionSimple
    cmp eax, 1
    je DELETE_FOUND_TOWER
    inc ecx
    jmp CHECK_TOWER_LOOP
DELETE_FOUND_TOWER:
    call removeTowerAtIndexSimple
    jmp DELETE_DONE
NO_TOWER_FOUND:
DELETE_DONE:
    ret
deleteTower ENDP

; =================================================================================
; 檢查指定 Index 的塔是否在當前游標位置
; =================================================================================
isTowerAtPositionSimple PROC USES ebx esi
    ; Check X
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.X
    jne NOT_MATCH_SIMPLE
    
    ; Check Y
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

; =================================================================================
; 移除指定 Index 的塔 (將後方資料前移)
; =================================================================================
removeTowerAtIndexSimple PROC USES eax ebx edx esi edi
    mov eax, ecx
    mov ebx, towerCount
    dec ebx
    cmp eax, ebx
    jge JUST_DECREASE_COUNT_SIMPLE
    mov edx, eax
    
    ; 移動 X 陣列
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
    ; 移動 Y 陣列
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
    ; 移動 Type 陣列
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

; =================================================================================
; 繪製單一個塔
; 參數透過 Stack 傳遞 (Index)
; =================================================================================
drawTower PROC USES eax ebx ecx edi esi
    mov eax, [esp+24]           ; 取得 Index
    push DWORD PTR outerBoxPos
    
    ; 讀取 X
    mov esi, OFFSET towersPosX
    mov ebx, eax
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.X, ax
    
    ; 讀取 Y
    mov esi, OFFSET towersPosY
    mov eax, [esp+28]
    mov ebx, eax
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.Y, ax

    ; 讀取類型
    mov esi, OFFSET towersType
    mov eax, [esp+28]
    add esi, eax
    mov bl, BYTE PTR [esi]

    ; 根據類型跳轉繪製
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

; =================================================================================
; 初始化地圖資料 (從 map1Data 複製到 mapData)
; =================================================================================
initMapSystem PROC USES eax ecx esi edi
    mov esi, OFFSET map1Data
    mov edi, OFFSET mapData
    mov ecx, (MAP_WIDTH * MAP_HEIGHT)
    rep movsb
    ret
initMapSystem ENDP

; =================================================================================
; 判斷是否可在此位置建造 (不能蓋在路徑或障礙物上)
; =================================================================================
canPlaceTowerAtCurrentPos PROC USES ebx ecx esi
    ; 換算 X Grid
    movzx eax, blockPos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax
    
    ; 換算 Y Grid
    movzx eax, blockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx
    
    ; 邊界檢查
    cmp ebx, MAP_WIDTH
    jge CANNOT_PLACE
    cmp eax, MAP_HEIGHT
    jge CANNOT_PLACE
    cmp ebx, 0
    jl CANNOT_PLACE
    cmp eax, 0
    jl CANNOT_PLACE
    
    ; 讀取地圖資料
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    
    ; 只有空地 (COMPONENT_EMPTY) 才能蓋塔
    cmp al, COMPONENT_EMPTY
    je CAN_PLACE
    
CANNOT_PLACE:
    mov eax, 0
    ret
CAN_PLACE:
    mov eax, 1
    ret
canPlaceTowerAtCurrentPos ENDP

; =================================================================================
; 繪製所有地圖元件
; =================================================================================
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

; =================================================================================
; 繪製單一地圖元件 (路徑等)
; =================================================================================
drawComponent PROC USES eax ebx ecx edx esi edi
    push ecx
    call calculateScreenPosition ; 計算螢幕座標
    pop ecx
    
    movzx eax, cl
    mov edx, 15                  ; 每個元件佔 15 bytes (5x3)
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

; =================================================================================
; Grid座標 轉 螢幕座標
; 輸入: EAX(Y), EBX(X) -> 設定 outerBoxPos
; =================================================================================
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
; 各式防禦塔外觀繪製 (A~E)
; =================================================================================
drawATower PROC USES esi
    mov esi, OFFSET blockAttributes 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0DBh
    mov tempBuffer+1, 0DBh
    mov tempBuffer+2, 0DBh
    mov tempBuffer+3, 0DBh
    mov tempBuffer+4, 0DBh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0DBh
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 07h
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 0DBh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0DBh
    mov tempBuffer+1, 0DBh
    mov tempBuffer+2, 0DBh
    mov tempBuffer+3, 0DBh
    mov tempBuffer+4, 0DBh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawATower ENDP

drawBTower PROC USES esi
    mov esi, OFFSET blockAttributes
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Eh
    mov tempBuffer+1, 1Eh
    mov tempBuffer+2, 1Eh
    mov tempBuffer+3, 1Eh
    mov tempBuffer+4, 1Eh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0BAh
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 04h
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 0BAh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0CDh
    mov tempBuffer+1, 0CDh
    mov tempBuffer+2, 0CDh
    mov tempBuffer+3, 0CDh
    mov tempBuffer+4, 0CDh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawBTower ENDP

drawCTower PROC USES esi
    mov esi, OFFSET blockAttributes
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, ' '
    mov tempBuffer+1, 0C9h
    mov tempBuffer+2, 0CDh
    mov tempBuffer+3, 0BBh
    mov tempBuffer+4, ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 10h
    mov tempBuffer+1, 06h
    mov tempBuffer+2, ' '
    mov tempBuffer+3, 06h
    mov tempBuffer+4, 11h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, ' '
    mov tempBuffer+1, 0C8h
    mov tempBuffer+2, 0CDh
    mov tempBuffer+3, 0BCh
    mov tempBuffer+4, ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawCTower ENDP

drawDTower PROC USES esi
    mov esi, OFFSET blockAttributes
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 15h
    mov tempBuffer+1, 15h
    mov tempBuffer+2, 15h
    mov tempBuffer+3, 15h
    mov tempBuffer+4, 15h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 7Eh
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 0Fh
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 7Eh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0E9h
    mov tempBuffer+1, 0E9h
    mov tempBuffer+2, 0E9h
    mov tempBuffer+3, 0E9h
    mov tempBuffer+4, 0E9h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawDTower ENDP

drawETower PROC USES esi
    mov esi, OFFSET blockAttributes
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0Eh
    mov tempBuffer+1, 0Dh
    mov tempBuffer+2, 0Eh
    mov tempBuffer+3, 0Dh
    mov tempBuffer+4, 0Eh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 11h
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 03h
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 10h
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Fh
    mov tempBuffer+1, 1Fh
    mov tempBuffer+2, 1Fh
    mov tempBuffer+3, 1Fh
    mov tempBuffer+4, 1Fh
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawETower ENDP

; =================================================================================
; 迴圈繪製所有已建造的塔
; =================================================================================
drawAllTowers PROC USES ecx
    mov ecx, 0
L:
    cmp ecx, towerCount
    jge DONE
    push ecx
    call drawTower ; 呼叫單一繪製函式
    inc ecx
    jmp L
DONE:
    ret
drawAllTowers ENDP

END main