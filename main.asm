INCLUDE Irvine32.inc
; INCLUDE monsters.asm 
; 注意：monsters.asm 的引入被移到檔案最末端。
; 原因：monsters.asm 需要使用 main.asm 中定義的常數 (如 WINDOW_WIDTH, MAP_WIDTH)，
; 若放在這裡引入，編譯器會因為尚未讀到常數定義而報錯。

; =================================================================================
; 函式原型宣告 (Function Prototypes)
; 宣告稍後會用到的函式，確保組譯器知道如何呼叫它們。
; =================================================================================
showStartScreen PROTO       ; 顯示遊戲標題畫面
showEscMenu PROTO           ; 顯示遊戲中暫停選單 (ESC)
showHowToPlay PROTO         ; 顯示操作說明
initConsoleWindow PROTO     ; 初始化視窗大小與緩衝區
outerBox PROTO              ; 繪製遊戲主外框
initBlock PROTO             ; 初始化游標位置
drawMovingDashedCursor PROTO; 繪製移動中的虛線框 (游標)
hasMapComponentAtCursor PROTO ; 檢查游標位置是否有地圖路徑元件
toggleMenuState PROTO       ; 切換 "建造選單" 的開啟/關閉狀態
handleNormalInput PROTO     ; 處理一般移動與刪除 (X) 輸入
handleSideMenuInput PROTO   ; 處理側邊選單的上下選擇輸入
drawSideMenu PROTO          ; 繪製側邊選單 (靜態圖形)
drawSideMenuCursor PROTO    ; 繪製側邊選單的選擇游標 (<<)
clearSideMenuCursor PROTO   ; 清除側邊選單的選擇游標
updateDashAnimation PROTO   ; 更新虛線框的動畫計時器
moveBlock PROTO             ; 遊戲主迴圈 (處理移動、輸入、畫面更新)
addTowerWithType PROTO      ; 在當前位置新增防禦塔
checkTowerAtCurrentPosition PROTO ; 檢查當前位置是否已經有塔
deleteTower PROTO           ; 刪除當前位置的塔
isTowerAtPositionSimple PROTO ; 輔助函式：檢查特定索引的塔是否在游標位置
removeTowerAtIndexSimple PROTO; 輔助函式：移除陣列中特定索引的塔
drawTower PROTO             ; 根據索引繪製單一座塔
initMapSystem PROTO         ; 初始化地圖資料 (從 map1Data 複製到 mapData)
canPlaceTowerAtCurrentPos PROTO ; 檢查當前地形是否可以蓋塔 (不能蓋在路徑上)
drawMapComponents PROTO     ; 繪製整個地圖的路徑元件
drawComponent PROTO         ; 繪製單一地圖元件
calculateScreenPosition PROTO ; 將地圖索引轉換為螢幕座標
drawATower PROTO            ; 繪製 A 型塔 (Cannon)
drawBTower PROTO            ; 繪製 B 型塔 (Sniper)
drawCTower PROTO            ; 繪製 C 型塔 (Ice)
drawDTower PROTO            ; 繪製 D 型塔 (Mage)
drawETower PROTO            ; 繪製 E 型塔 (Missile)
drawAllTowers PROTO         ; 繪製場上所有的塔
restoreGraphicsAtPos PROTO  ;還原游標離開後的圖形 (防止殘影)
getTowerTypeAtPos PROTO     ; 取得當前位置塔的類型 (用於還原圖形)

; 來自 monsters.asm 的函式原型
createMonsters PROTO :DWORD
updateMonstersPositions PROTO
removeMonsters PROTO
drawMonsters PROTO

; =================================================================================
; 常數定義 (Constants)
; =================================================================================
main EQU start@0

; --- 視窗設定 ---
WINDOW_WIDTH        = 120    ;視窗寬度 (字元)
WINDOW_HEIGHT       = 40     ;視窗高度 (字元)

; --- 介面尺寸 ---
outerBoxWidth       = 84     ; 遊戲主畫面框寬度
outerBoxHeight      = 26     ; 遊戲主畫面框高度

; --- 遊戲方塊 (Grid) 尺寸 ---
blockWidth          = 5      ; 每一格的寬度 (字元)
blockHeight         = 3      ; 每一格的高度 (字元)

; --- 地圖設定 ---
MAP_WIDTH           = 16     ; 地圖橫向格數
MAP_HEIGHT          = 8      ; 地圖縱向格數

; --- 地圖元件 ID 對照表 ---
COMPONENT_EMPTY     = 0      ; 空地 (可蓋塔)
COMPONENT_OUTLET    = 1      ; 起點
COMPONENT_EXIT      = 2      ; 終點
COMPONENT_PATH_H    = 3      ; 水平路徑
COMPONENT_PATH_V    = 4      ; 垂直路徑
COMPONENT_CORNER_1  = 5      ; 轉角 1
COMPONENT_CORNER_2  = 6      ; 轉角 2
COMPONENT_CORNER_3  = 7      ; 轉角 3
COMPONENT_CORNER_4  = 8      ; 轉角 4

; --- 側邊選單設定 ---
SIDE_MENU_X         = 90     ; 選單起始 X 座標
SIDE_MENU_Y         = 4      ; 選單起始 Y 座標
SIDE_MENU_SPACING   = 5      ; 選單選項垂直間距
TOWER_MENU_COUNT    EQU 5    ; 塔的種類數量

; --- 動畫速度 ---
DASH_SPEED          EQU 5    ; 虛線框動畫更新頻率 (數值越大越慢)

; --- 選單設定 ---
MENU_OPTION_COUNT   EQU 4    ; ESC 選單選項數量

.data

; 選單游標位置 (0-3) 用於 ESC 選單
menuCursor          BYTE 0

; =================================================================================
; 介面資料 (Console Buffer Data)
; =================================================================================
windowRect      SMALL_RECT <0, 0, WINDOW_WIDTH-1, WINDOW_HEIGHT-1>
consoleSize     COORD <WINDOW_WIDTH, WINDOW_HEIGHT>

; 外框繪製字元 (雙線框)
outerBoxTop     BYTE 0DAh, 82 DUP(0C4h), 0BFh    ; ┌───┐
outerBoxBody    BYTE 0B3h, 82 DUP(' '), 0B3h     ; │   │
outerBoxBottom  BYTE 0C0h, 82 DUP(0C4h), 0D9h    ; └───┘

; Windows Console Handles
outputHandle    DWORD 0
inputHandle     DWORD 0     
cellsWritten    DWORD ?      ; 用於接收 API 寫入的字元數 (不用管內容)
count           DWORD 0
numEvents       DWORD 0     

; --- 座標與位置控制 ---
outerBoxPosInit COORD <5,3>     ; 外框左上角起始點
outerBoxPos     COORD <?, ?>    ; 繪圖時使用的暫存座標
blockPosInit    COORD <7, 4>    ; 遊戲網格 (0,0) 對應的螢幕座標
blockPos        COORD <?, ?>    ; 玩家游標當前座標 (螢幕座標)
prevBlockPos    COORD <?, ?>    ; 玩家游標上一次的座標 (用於清除殘影)

; --- 側邊選單控制 ---
sideMenuCursorIndex DWORD 0     ; 側邊選單目前選到的索引 (0-4)
sideMenuCursorPos   COORD <?, ?>; 側邊選單游標的螢幕座標

; --- 建造狀態 ---
currentBuildType    BYTE 1      ; 目前預計建造的塔類型 (預設為 1)

; --- 顏色屬性 (Attributes) ---
; F0h = 白底黑字 (F=背景白, 0=文字黑)
outerAttributes WORD outerBoxWidth DUP(0F0h)
blockAttributes WORD blockWidth DUP(0F0h)
cursorAttr      WORD blockWidth DUP(0F0h)     
emptyLine       BYTE 60 DUP(' ') ; 用於清除文字的空白字串

; --- 各塔顏色設定 ---
attrTowerA      WORD blockWidth DUP(0F0h) 
attrTowerB      WORD blockWidth DUP(0F0h) 
attrTowerC      WORD blockWidth DUP(0F0h) 
attrTowerD      WORD blockWidth DUP(0F0h) 
attrTowerE      WORD blockWidth DUP(0F0h) 

; --- 塔的名稱字串 (顯示在選單旁) ---
strNameA        BYTE "Cannon ", 0
strNameB        BYTE "Sniper ", 0
strNameC        BYTE "Ice    ", 0  
strNameD        BYTE "Mage   ", 0
strNameE        BYTE "Missile", 0 

; --- 側邊選單游標樣式 ---
attrMenuCursor  WORD 4 DUP(0C0h) ; 紅底黑字 (C0h)
menuCursorStr   BYTE " << "

; --- 選單文字屬性 ---
attrMenuName    WORD 10 DUP(0F0h)

; --- 繪圖暫存緩衝區 ---
tempBuffer      BYTE blockWidth DUP(?)

; =================================================================================
; 遊戲邏輯資料 (Game Data)
; =================================================================================
towerMax        EQU 30                ; 最大塔數限制
towersPosX      WORD towerMax DUP(?)  ; 儲存所有塔的 X 座標
towersPosY      WORD towerMax DUP(?)  ; 儲存所有塔的 Y 座標
towersType      BYTE towerMax DUP(?)  ; 儲存所有塔的類型 (1-5)
towerCount      DWORD 0               ; 目前已建造的塔數量

; --- 遊戲狀態變數 ---
; startWave: 0 = 準備期 (可蓋塔), 1 = 戰鬥期 (怪物移動)
startWave       DWORD 0       
cur_round       DWORD 1       ; 當前波數 (傳給 monsters.asm 用)

; menuState: 0 = 游標在地圖上, 1 = 游標在側邊選單 (選塔中)
menuState           DWORD 0  
towerTypes          BYTE 1, 2, 3, 4, 5

; --- 動畫變數 ---
dashTimer       DWORD 0       ; 動畫計時器
dashAnimState   DWORD 0       ; 動畫狀態 (0 或 1)
; 虛線樣式 (兩組切換造成滾動效果)
dashStyle1      BYTE '-', ' ', '-', ' ', '-', ' ', ' ', '-', ' ', '-', ' ', '-'   
dashStyle2      BYTE ' ', '-', ' ', '-', ' ', '|', '|', ' ', '-', ' ', '-', ' '   

; --- 文字 UI資源 ---
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

; --- 地圖資料 ---
; mapData: 執行時使用的地圖陣列
mapData BYTE (MAP_WIDTH * MAP_HEIGHT) DUP(0)

; map1Data: 預設地圖配置 (唯讀來源)
map1Data BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
         BYTE 0,1,0,6,3,3,3,3,3,3,3,5,0,2,0,0
         BYTE 0,4,0,4,0,0,0,0,0,0,0,4,0,4,0,0
         BYTE 0,4,0,4,0,0,6,3,3,3,3,8,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,7,3,8,0,0,7,3,3,3,3,3,3,8,0,0
         BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; --- 地圖元件 ASCII 圖形 ---
; 每個元件寬度為 5 bytes，高度為 3 lines，共 15 bytes
componentChars LABEL BYTE
component0 BYTE 15 DUP(20h) ; 空白
component1 BYTE 5 DUP(20h), 20h, 3 DUP(0DCh), 20h, 0DEh, 0DBh, 0DFh, 0DBh, 0DDh ; 起點
component2 BYTE 5 DUP(20h), 20h, 3 DUP(0DCh), 20h, 0DEh, 3 DUP(0B0h), 0DDh      ; 終點
component3 BYTE 5 DUP(20h), 5 DUP(0B0h), 5 DUP(20h) ; 水平路
component4 BYTE 20h, 3 DUP(0B0h), 20h, 20h, 3 DUP(0B0h), 20h, 20h, 3 DUP(0B0h), 20h ; 垂直路
component5 BYTE 5 DUP(20h), 4 DUP(0B0h), 20h, 20h, 3 DUP(0B0h), 20h ; 轉角1
component6 BYTE 5 DUP(20h), 20h, 4 DUP(0B0h), 20h, 3 DUP(0B0h), 20h ; 轉角2
component7 BYTE 20h, 3 DUP(0B0h), 20h, 20h, 4 DUP(0B0h), 5 DUP(20h) ; 轉角3
component8 BYTE 20h, 3 DUP(0B0h), 20h, 4 DUP(0B0h), 20h, 5 DUP(20h) ; 轉角4

.code
; =================================================================================
; 程式進入點 (Entry Point)
; =================================================================================
main PROC
    ; 1. 取得標準輸入輸出 Handles
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    INVOKE GetStdHandle, STD_INPUT_HANDLE   
    mov inputHandle, eax
    
    ; 2. 初始化視窗設定 (大小、緩衝區)
    call initConsoleWindow

    ; 3. 設定預設顏色 (白底黑字) 並清空螢幕
    INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
    call Clrscr 
    
    ; 4. 顯示開始標題畫面
    call showStartScreen

    ; 5. 繪製遊戲主介面
    call outerBox           ; 畫外框
    call initMapSystem      ; 載入地圖資料
    call initBlock          ; 初始化游標位置
    
    call drawMapComponents  ; 畫地圖路徑
    call drawAllTowers      ; 畫已存在的塔 (剛開始為空)
    call drawSideMenu       ; 畫側邊選單

    ; 6. 進入遊戲主迴圈
    call moveBlock      
    
    ; 7. 結束程式
    call Clrscr
    exit
main ENDP

; =================================================================================
; 設定視窗大小 (Init Console)
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
    ; 設定游標位置並印出標題 ASCII Art
    mov dh, 8
    mov dl, 10
    call Gotoxy
    mov edx, OFFSET startTitle1
    call WriteString
    ; ... (略過重複的印字邏輯) ...
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
    
    ; 迴圈等待使用者按下 ENTER (ASCII 13)
WAIT_ENTER:
    call ReadChar
    cmp al, 13  
    jne WAIT_ENTER
    call Clrscr
    ret
showStartScreen ENDP

; =================================================================================
; 顯示 ESC 選單 (Pause Menu)
; 回傳值: EAX (1=Continue, 2=Restart, 3=HowToPlay, 4=EndGame)
; =================================================================================
showEscMenu PROC USES ebx ecx edx
    LOCAL oldCursor:BYTE
    LOCAL keyCode:WORD
    
    mov menuCursor, 0
    call Clrscr
    
    ; 繪製選單選項
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
    ; ... (繪製其餘選項) ...
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
    
    ; 繪製初始箭頭
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
    mov oldCursor, al   ; 記錄舊的游標位置以便清除
    
    mov ax, keyCode
    cmp ax, 4800h       ; Up Arrow
    je MENU_UP
    cmp ax, 5000h       ; Down Arrow
    je MENU_DOWN
    cmp al, 13          ; Enter
    je MENU_SELECT
    cmp ax, 011Bh       ; ESC (Cancel/Resume)
    je MENU_CANCEL
    jmp MENU_WAIT_INPUT
    
MENU_UP:
    movzx eax, menuCursor
    cmp eax, 0
    je MENU_WAIT_INPUT  ; 已經在最上面，忽略
    dec menuCursor
    call FlushKeyBuffer ; 清空緩衝區避免連點
    jmp UPDATE_CURSOR
    
MENU_DOWN:
    movzx eax, menuCursor
    cmp eax, MENU_OPTION_COUNT - 1
    jge MENU_WAIT_INPUT ; 已經在最下面，忽略
    inc menuCursor
    call FlushKeyBuffer
    jmp UPDATE_CURSOR
    
UPDATE_CURSOR:
    ; 清除舊箭頭
    movzx eax, oldCursor
    add al, 10          ; 計算 Y 座標 offset
    mov dh, al
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET twoSpaces
    call WriteString
    
    ; 繪製新箭頭
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
    inc eax  ; 回傳 1-4
    jmp MENU_EXIT
    
MENU_CANCEL:
    mov eax, 1  ; Default to Continue
    
MENU_EXIT:
    ret
showEscMenu ENDP

; 輔助函式：清空鍵盤緩衝區
FlushKeyBuffer PROC
FLUSH_LOOP:
    call ReadKey
    jnz FLUSH_LOOP 
    ret
FlushKeyBuffer ENDP

; =================================================================================
; 顯示操作說明 (How To Play)
; =================================================================================
showHowToPlay PROC USES edx
    call Clrscr
    ; 繪製多行說明文字 ...
    mov dh, 6
    mov dl, 24
    call Gotoxy
    mov edx, OFFSET helpTitle
    call WriteString
    ; ... (省略重複的寫字代碼) ...
    mov dh, 8
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine1
    call WriteString
    ; ... 
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
    call ReadChar ; 等待任意鍵
    ret
showHowToPlay ENDP

; =================================================================================
; 繪製常駐側邊選單 (Tower Selection UI)
; 僅繪製塔的圖示，不含游標
; =================================================================================
drawSideMenu PROC USES eax ecx esi
    push DWORD PTR outerBoxPos ; 保存當前繪圖座標
    mov ecx, 0
DRAW_MENU_LOOP:
    cmp ecx, TOWER_MENU_COUNT
    jge DRAW_MENU_FINISH
    
    ; 計算 Y 座標: BaseY + (Index * Spacing)
    mov eax, ecx
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    mov outerBoxPos.Y, ax
    mov outerBoxPos.X, SIDE_MENU_X
    
    ; 根據 Index 呼叫對應的繪圖函式
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
    pop DWORD PTR outerBoxPos ; 還原座標
    ret
drawSideMenu ENDP

; =================================================================================
; 繪製側邊選單的選擇游標 (<<) 和選中的塔名稱
; =================================================================================
drawSideMenuCursor PROC USES eax
    ; 計算游標位置
    mov eax, sideMenuCursorIndex
    imul eax, SIDE_MENU_SPACING
    add eax, SIDE_MENU_Y
    add eax, 1                  ; 微調 Y 使其置中
    mov sideMenuCursorPos.Y, ax
    mov ax, SIDE_MENU_X
    add ax, 6                   ; X 座標在塔圖示右側
    mov sideMenuCursorPos.X, ax
    
    ; 繪製 " << " 紅色背景
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuCursor, 4, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR menuCursorStr, 4, sideMenuCursorPos, ADDR count
    
    ; 繪製塔名稱 (移動 X 座標)
    add sideMenuCursorPos.X, 5
    mov eax, sideMenuCursorIndex
    ; 判斷顯示哪一個名字
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
    ; ... (重複結構針對不同塔名) ...
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
; 清除側邊選單游標 (用空白覆蓋)
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
    ; 覆蓋 " << "
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 4, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 4, sideMenuCursorPos, ADDR count
    add sideMenuCursorPos.X, 5
    ; 覆蓋名稱
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 10, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 10, sideMenuCursorPos, ADDR count
    ret
clearSideMenuCursor ENDP

; =================================================================================
; 切換選單狀態 (Menu State Toggle)
; =================================================================================
toggleMenuState PROC
    mov eax, menuState
    xor eax, 1          ; 0 變 1, 1 變 0
    mov menuState, eax
    cmp eax, 1
    je SWITCH_TO_MENU   ; 如果切換到選單模式 (1)
    call clearSideMenuCursor ; 如果關閉選單，清除游標
    jmp TOGGLE_DONE
SWITCH_TO_MENU:
    call drawSideMenuCursor  ; 繪製游標
TOGGLE_DONE:
    ret
toggleMenuState ENDP

; =================================================================================
; 處理側邊選單輸入 (選塔)
; =================================================================================
handleSideMenuInput PROC USES eax
    cmp ax, 4800h ; UP Arrow
    je MENU_UP
    cmp ax, 5000h ; DOWN Arrow
    je MENU_DOWN
    cmp ax, 1C0Dh ; ENTER
    je MENU_SELECT
    jmp MENU_INPUT_DONE

MENU_UP:
    call clearSideMenuCursor      ; 先清除舊位置
    dec sideMenuCursorIndex       ; 索引 -1
    cmp sideMenuCursorIndex, 0
    jge UPDATE_CURSOR
    mov sideMenuCursorIndex, 4    ; 循環回到最底
    jmp UPDATE_CURSOR

MENU_DOWN:
    call clearSideMenuCursor      
    inc sideMenuCursorIndex       ; 索引 +1
    cmp sideMenuCursorIndex, 4
    jle UPDATE_CURSOR
    mov sideMenuCursorIndex, 0    ; 循環回到最頂
    jmp UPDATE_CURSOR

UPDATE_CURSOR:
    call drawSideMenuCursor       ; 畫新位置
    jmp MENU_INPUT_DONE

MENU_SELECT:
    ; 確認選塔
    mov eax, sideMenuCursorIndex
    inc eax                       ; 索引 0-4 轉為 類型 1-5
    mov bl, al                    ; 將類型存入 BL
    call addTowerWithType         ; 執行蓋塔
    call restoreGraphicsAtPos     ; 蓋完後重繪地圖格
    call toggleMenuState          ; 關閉選單，切回移動模式
    jmp MENU_INPUT_DONE

MENU_INPUT_DONE:
    ret
handleSideMenuInput ENDP

; =================================================================================
; 處理一般遊戲輸入 (移動游標、刪除塔)
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
    sub blockPos.Y, blockHeight ; Y 減去一格高度
    mov bx, blockPosInit.Y
    cmp blockPos.Y, bx
    jge END_NORMAL_INPUT        ; 如果沒超出邊界，結束
    add blockPos.Y, blockHeight ; 如果超出，加回來 (取消移動)
    jmp END_NORMAL_INPUT

HANDLE_DOWN:
    add blockPos.Y, blockHeight
    mov bx, (blockHeight * 7)   ; 地圖高度限制 (7格 + InitY)
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
    mov bx, (blockWidth * 15)   ; 地圖寬度限制 (15格 + InitX)
    add bx, blockPosInit.X
    cmp blockPos.X, bx
    jbe END_NORMAL_INPUT
    sub blockPos.X, blockWidth
    jmp END_NORMAL_INPUT
    
HANDLE_X:
    call deleteTower          ; 執行拆塔邏輯
    call restoreGraphicsAtPos ; 重繪該格
    
END_NORMAL_INPUT:
    ret
handleNormalInput ENDP

; =================================================================================
; 繪製遊戲外框
; =================================================================================
outerBox PROC USES eax ecx
    mov ax, outerBoxPosInit.X
    mov outerBoxPos.X, ax
    mov ax, outerBoxPosInit.Y
    mov outerBoxPos.Y, ax
    
    ; 畫頂部線
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxTop, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    ; 畫中間身體 (迴圈)
    mov ecx, outerBoxHeight-2
L1: push ecx
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, outerBoxWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR outerBoxBody, outerBoxWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop ecx
    loop L1
    
    ; 畫底部線
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

; =================================================================================
; 繪製移動中的虛線游標 (Animated Cursor)
; 覆蓋在當前的地圖格子上，使用 WriteConsoleOutputAttribute 保留背景色
; =================================================================================
drawMovingDashedCursor PROC USES eax esi edi
    push DWORD PTR outerBoxPos
    mov ax, blockPos.X
    mov dx, blockPos.Y
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, dx
    
    ; 根據 dashAnimState 切換樣式 (0 或 1)
    mov esi, OFFSET dashStyle1
    cmp dashAnimState, 1
    jne USE_STYLE
    mov esi, OFFSET dashStyle2
USE_STYLE:
    ; 複製樣式字元到 tempBuffer
    ; 這裡手動複製頂部線條
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
    
    ; 寫入頂部線條
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR cursorAttr, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    
    ; 寫入中間兩側
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
    
    ; 寫入底部線條
    sub outerBoxPos.X, 4
    inc outerBoxPos.Y
    mov al, [esi+7]
    ; ... (複製剩餘字元) ...
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
; 檢查當前游標位置是否在地圖元件上
; =================================================================================
hasMapComponentAtCursor PROC USES ebx ecx esi
    ; 1. 將螢幕像素座標轉換為地圖索引 (Grid X, Y)
    movzx eax, blockPos.X
    sub eax, 7                  ; 扣除邊距
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax    ; EBX = Grid X
    
    movzx eax, blockPos.Y
    sub eax, 4                  ; 扣除邊距
    mov ecx, blockHeight
    xor edx, edx
    div ecx         ; EAX = Grid Y
    
    ; 2. 邊界檢查
    cmp ebx, MAP_WIDTH
    jge NO_MAP_COMPONENT
    cmp eax, MAP_HEIGHT
    jge NO_MAP_COMPONENT
    cmp ebx, 0
    jl NO_MAP_COMPONENT
    cmp eax, 0
    jl NO_MAP_COMPONENT
    
    ; 3. 計算一維陣列索引: Index = Y * Width + X
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    
    ; 4. 讀取地圖資料
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    cmp al, COMPONENT_EMPTY     ; 如果是空地 (0)
    je NO_MAP_COMPONENT
    
    mov eax, 1 ; 有元件
    ret
NO_MAP_COMPONENT:
    mov eax, 0 ; 無元件
    ret
hasMapComponentAtCursor ENDP

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
; 還原游標位置的圖形 (Anti-Flicker Clear)
; 在繪製新游標前，先將舊位置還原成原本的 地圖元件 或 塔
; =================================================================================
restoreGraphicsAtPos PROC USES eax ebx ecx esi edi
    push DWORD PTR outerBoxPos
    mov ax, prevBlockPos.X
    mov outerBoxPos.X, ax
    mov ax, prevBlockPos.Y
    mov outerBoxPos.Y, ax
    
    ; 1. 檢查該位置有沒有塔
    call getTowerTypeAtPos
    cmp eax, 0
    je RESTORE_MAP      ; 沒塔，還原地圖
    
    ; 有塔，根據類型重畫塔
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
    ; 2. 沒塔，計算地圖索引並還原路徑圖形
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
    
    ; 邊界檢查
    cmp ebx, MAP_WIDTH
    jge RESTORE_DONE
    cmp eax, MAP_HEIGHT
    jge RESTORE_DONE
    
    ; 取得元件 ID
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi] 
    
    ; 根據 ID 找到對應的 ASCII 圖形位址
    movzx eax, cl
    mov edx, 15 ; 每個元件 15 bytes
    mul edx
    mov esi, OFFSET componentChars
    add esi, eax
    
    ; 繪製元件
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

; =================================================================================
; 檢查座標上是否有塔，若有回傳類型 (Type 1-5)，無則回傳 0
; =================================================================================
getTowerTypeAtPos PROC USES ebx ecx esi
    mov ecx, 0
CHECK_LOOP:
    cmp ecx, towerCount
    jge NOT_FOUND
    ; 檢查 X
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2 ; WORD array
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, prevBlockPos.X 
    jne NEXT
    ; 檢查 Y
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, prevBlockPos.Y 
    jne NEXT
    ; 找到，回傳 Type
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
; 遊戲主迴圈 (Main Game Loop)
; =================================================================================
moveBlock PROC
START_MOVE:
    ; 1. 更新動畫與游標繪製
    call updateDashAnimation    
    call restoreGraphicsAtPos   ; 清除上一次的游標
    call drawMovingDashedCursor ; 畫這一次的游標
    
    ; 更新 "上一次座標" 為 "當前座標"
    mov ax, blockPos.X
    mov prevBlockPos.X, ax
    mov ax, blockPos.Y
    mov prevBlockPos.Y, ax

    ; 檢查選單狀態，若開啟選單則跳過部分繪製
    cmp menuState, 1
    je DRAW_MENU_STATE
    jmp AFTER_DRAW

DRAW_MENU_STATE:
    ; 可以在這裡加入選單特有的邏輯 (目前無)
AFTER_DRAW:

    ; =========================================================
    ; 戰鬥狀態處理 (Combat Phase)
    ; startWave: 1 = 戰鬥中, 0 = 準備期
    ; =========================================================
    cmp startWave, 1          
    jne SKIP_COMBAT_LOGIC     ; 如果是 0，跳過怪物更新
    
    ; --- 戰鬥中邏輯 (每一幀執行) ---
    call updateMonstersPositions      
    call removeMonsters  	 
    call drawMonsters
    
    ; [註] 需在 monsters.asm 實作: 若 monsterCount == 0, 設 startWave = 0

SKIP_COMBAT_LOGIC:	
    ; =========================================================
	
    mov eax, 50                 ; 延遲 50ms (控制遊戲速度)
    call Delay
    
    call ReadKey
    jz NO_KEY_PRESSED
    
    ; ---------------------------------------------------------
    ; [G鍵] 開始戰鬥 (僅在準備期有效)
    ; ---------------------------------------------------------
    .IF (al == 'g') || (al == 'G')
        .IF (startWave == 0) && (menuState == 0)
            ; 1. 生成怪物
            invoke createMonsters, cur_round
            ; 2. 切換狀態為戰鬥
            mov startWave, 1      
        .ENDIF
    .ENDIF

    ; ---------------------------------------------------------
    ; [F鍵] 開啟選單 (僅在準備期有效)
    ; ---------------------------------------------------------
    .IF ax == 2166h ; 'f'
        .IF startWave == 0
            call toggleMenuState
        .ENDIF
    .ENDIF
	
    ; 如果選單開啟中，輸入交給 SideMenu 處理
    cmp menuState, 1
    je HANDLE_MENU_INPUT_LABEL        
    
    ; 否則交給一般輸入處理 (移動)
    call handleNormalInput      
    jmp END_INPUT_CHECK

HANDLE_MENU_INPUT_LABEL:
    call handleSideMenuInput

NO_KEY_PRESSED:
END_INPUT_CHECK:

    ; ---------------------------------------------------------
    ; [ESC鍵] 暫停選單
    ; ---------------------------------------------------------
    .IF ax == 011Bh ; ESC 
        call showEscMenu
        
        .IF eax == 1  ; Continue
            ; 重畫整個畫面
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawAllTowers
            call drawSideMenu
        .ELSEIF eax == 2  ; Restart
            mov towerCount, 0
            mov startWave, 0      ; 重置狀態
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

    jmp START_MOVE ; 回到迴圈開頭
EXIT_MOVE:
    ret
moveBlock ENDP

; =================================================================================
; 新增塔到陣列中 (Build Tower)
; =================================================================================
addTowerWithType PROC USES eax ecx esi
    ; 1. 檢查是否重疊
    call checkTowerAtCurrentPosition
    cmp eax, 1
    je NO_ADD_TYPE ; 重疊，不蓋
    
    ; 2. 檢查地形限制 (不能蓋在路上)
    call canPlaceTowerAtCurrentPos
    cmp eax, 0
    je NO_ADD_TYPE ; 地形不符，不蓋
    
    ; 3. 檢查塔數上限
    mov eax, towerCount
    cmp eax, towerMax
    jge NO_ADD_TYPE
    
    ; 4. 寫入資料陣列
    mov ecx, eax
    ; 寫入 X
    mov esi, OFFSET towersPosX
    imul eax, 2
    add esi, eax
    mov ax, blockPos.X
    mov WORD PTR [esi], ax
    ; 寫入 Y
    mov esi, OFFSET towersPosY
    mov eax, ecx
    imul eax, 2
    add esi, eax
    mov ax, blockPos.Y
    mov WORD PTR [esi], ax
    ; 寫入 Type (BL 來自 handleSideMenuInput)
    mov esi, OFFSET towersType
    mov eax, ecx
    add esi, eax
    mov BYTE PTR [esi], bl
    
    inc towerCount
NO_ADD_TYPE:
    ret
addTowerWithType ENDP

; =================================================================================
; 檢查當前位置是否有塔 (Collision Check)
; =================================================================================
checkTowerAtCurrentPosition PROC USES ebx ecx esi
    mov ecx, 0
CHECK_POS_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_HERE
    ; Check X
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.X
    jne NEXT_CHECK_POS
    ; Check Y
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2
    add esi, ebx
    mov bx, WORD PTR [esi]
    cmp bx, blockPos.Y
    je TOWER_HERE ; 找到重疊
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

; =================================================================================
; 刪除塔 (Delete Tower)
; =================================================================================
deleteTower PROC USES eax ebx ecx esi
    cmp towerCount, 0
    je DELETE_DONE
    mov ecx, 0
CHECK_TOWER_LOOP:
    cmp ecx, towerCount
    jge DELETE_DONE
    call isTowerAtPositionSimple
    cmp eax, 1
    je DELETE_FOUND_TOWER ; 找到要刪的塔
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

; =================================================================================
; 移除陣列中指定索引的塔 (Remove from Array)
; 實作方式：將最後一個元素搬移到被刪除的位置，然後 Count - 1
; =================================================================================
removeTowerAtIndexSimple PROC USES eax ebx edx esi edi
    mov eax, ecx        ; 目標索引
    mov ebx, towerCount
    dec ebx             ; 最後一個索引
    cmp eax, ebx
    jge JUST_DECREASE_COUNT_SIMPLE ; 如果刪的是最後一個，直接減 Count
    
    ; --- 搬移陣列邏輯 (這裡實作的是陣列平移 shift left) ---
    ; 1. Shift X Array
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
    
    ; 2. Shift Y Array
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
    
    ; 3. Shift Type Array
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

; =================================================================================
; 繪製指定索引的塔
; =================================================================================
drawTower PROC USES eax ebx ecx edi esi
    ; 參數從堆疊取得 (stdcall convention 手動處理)
    ; [ESP+24] = Tower Index (因使用了 USES 保存了 5 個暫存器 + return address)
    mov edi, [esp+24]      

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

    ; 取得 Type 並呼叫對應繪圖函式
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
    call drawATower ; Default
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
    ret 4 ; 清除堆疊參數
drawTower ENDP

; =================================================================================
; 初始化地圖系統 (複製預設資料)
; =================================================================================
initMapSystem PROC USES eax ecx esi edi
    mov esi, OFFSET map1Data
    mov edi, OFFSET mapData
    mov ecx, (MAP_WIDTH * MAP_HEIGHT)
    rep movsb ; 快速記憶體複製
    ret
initMapSystem ENDP

; =================================================================================
; 檢查地形 (Terrain Check)
; =================================================================================
canPlaceTowerAtCurrentPos PROC USES ebx ecx esi
    ; 轉換螢幕座標 -> 地圖 Grid
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
    
    ; 邊界檢查
    cmp ebx, MAP_WIDTH
    jge CANNOT_PLACE
    cmp eax, MAP_HEIGHT
    jge CANNOT_PLACE
    
    ; 檢查地圖資料是否為 EMPTY (0)
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    cmp al, COMPONENT_EMPTY
    je CAN_PLACE ; 只有空地可以蓋塔
CANNOT_PLACE:
    mov eax, 0
    ret
CAN_PLACE:
    mov eax, 1
    ret
canPlaceTowerAtCurrentPos ENDP

; =================================================================================
; 繪製整個地圖
; =================================================================================
drawMapComponents PROC USES eax ebx ecx edx esi edi
    mov eax, 0 ; Y Counter
DRAW_MAP_Y_LOOP:
    cmp eax, MAP_HEIGHT
    jge DRAW_MAP_DONE
    mov ebx, 0 ; X Counter
DRAW_MAP_X_LOOP:
    cmp ebx, MAP_WIDTH
    jge NEXT_MAP_Y
    
    push eax
    push ebx
    ; 計算 Index 並取得元件 ID
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi]
    pop ebx
    pop eax
    call drawComponent ; 繪製單個元件 (會自動算座標)
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
    call calculateScreenPosition ; 計算 outerBoxPos
    pop ecx
    
    ; 取得元件圖形位址
    movzx eax, cl
    mov edx, 15                  
    mul edx
    mov esi, OFFSET componentChars
    add esi, eax
    
    ; 逐行繪製 (3行)
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
    ; 將 Grid (EAX, EBX) 轉為 螢幕像素座標 (outerBoxPos)
    push ebx
    push eax
    mov eax, ebx
    mov ecx, blockWidth
    mul ecx
    add eax, 7 ; Margin X
    mov outerBoxPos.X, ax
    pop eax
    push eax
    mov ecx, blockHeight
    mul ecx
    add eax, 4 ; Margin Y
    mov outerBoxPos.Y, ax
    pop eax
    pop ebx
    ret
calculateScreenPosition ENDP

; =================================================================================
; 各式防禦塔外觀繪製函式
; 使用 ASCII 組合出圖形，並透過 WriteConsoleOutputCharacter 輸出
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
; Row 3:  ^     (左下角三角形腳架)
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

; =================================================================================
; 迴圈繪製所有已建造的塔
; =================================================================================
drawAllTowers PROC USES ecx
    mov ecx, 0
L:
    cmp ecx, towerCount
    jge DONE
    push ecx
    call drawTower ; 傳遞 Index
    inc ecx
    jmp L
DONE:
    ret
drawAllTowers ENDP

INCLUDE monsters.asm

END main