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
showGameOver PROTO          ; 顯示 Game Over 畫面
showYouWin PROTO            ; 顯示 YOU WIN 畫面 (cur_round == 21)
endGameMenu PROTO           ; 顯示結束遊戲選單 (Restart/How to Play/End Game)
drawBigNumber PROTO :DWORD, :DWORD, :DWORD ; 繪製大數字 (數字, X座標, Y座標)
drawBigLetter PROTO :DWORD, :DWORD, :DWORD ; 繪製大字母 (字母M/R/L, X座標, Y座標)
drawString PROTO :DWORD, :DWORD, :DWORD ; 繪製字串 (字串指標, X座標, Y座標)
drawGameStats PROTO         ; 繪製遊戲頂部資訊欄 (金錢、生命、回合)
initConsoleWindow PROTO     ; 初始化視窗大小與緩衝區
outerBox PROTO              ; 繪製遊戲主外框
initBlock PROTO             ; 初始化游標位置
drawMovingDashedCursor PROTO; 繪製移動中的虛線框 (游標)
drawAttackRangeOverlay PROTO :DWORD
hasMapComponentAtCursor PROTO ; 檢查游標位置是否有地圖路徑元件
towerCombatSystem PROTO
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
restoreGraphicsAtMonPos PROTO
ctrlDraw PROTO

; =================================================================================
; 引入常數定義 (Constants)
; =================================================================================
INCLUDE constants.inc

; =================================================================================
; 資料段 (Data Segment)
; =================================================================================
INCLUDE data.inc


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

GAME_RESTART:
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
    
    ; 檢查是否遊戲結束或勝利
    .IF cur_round == 21
        ; 玩家贏了！
        call showYouWin
        cmp eax, 999    ; 檢查是否要重新開始
        je GAME_RESTART
    .ELSEIF gameOver == 1
        ; 玩家失敗
        call showGameOver
        cmp eax, 999    ; 檢查是否要重新開始
        je GAME_RESTART
    .ENDIF
    
    ; 7. 結束程式
GAME_EXIT:
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
    ; 設定白底黑字
    mov eax, black + (white * 16)
    call SetTextColor
    
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
    mov dh, 14
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET helpLine7
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
; 顯示 Game Over 畫面
; =================================================================================
showGameOver PROC USES edx
    call Clrscr
    
    ; 設定顏色為紅底白字 (0x4F)
    mov eax, red + (white * 16)
    call SetTextColor
    
    ; 繪製 GAME OVER 使用 pixel art
    mov edx, OFFSET gameOverText
    INVOKE drawString, edx, 35, 10
    
    ; 恢復預設顏色
    mov eax, white + (black * 16)
    call SetTextColor
    
    ; 顯示結束遊戲選單並返回其結果
    mov eax, 0  ; 參數: 0 表示 GameOver 畫面
    call endGameMenu
    ; eax 已包含 endGameMenu 的返回值 (999=restart, 0=exit)
    
    ret
showGameOver ENDP

; =================================================================================
; 顯示 YOU WIN 畫面 (當 cur_round == 21 時)
; =================================================================================
showYouWin PROC USES edx
    call Clrscr
    
    ; 設定顏色為黃底黑字
    mov eax, black + (yellow * 16)
    call SetTextColor
    
    ; 繪製 YOU WIN 使用 pixel art
    mov edx, OFFSET youWinText
    INVOKE drawString, edx, 35, 10
    
    ; 恢復預設顏色
    mov eax, white + (black * 16)
    call SetTextColor
    
    ; 顯示結束遊戲選單並返回其結果
    mov eax, 1  ; 參數: 1 表示 YouWin 畫面
    call endGameMenu
    ; eax 已包含 endGameMenu 的返回值 (999=restart, 0=exit)
    
    ret
showYouWin ENDP

; =================================================================================
; 結束遊戲選單 (Restart / How to Play / End Game)
; 不含 Continue 選項
; =================================================================================
endGameMenu PROC USES ebx ecx edx
    LOCAL oldCursor:BYTE
    LOCAL keyCode:WORD
    LOCAL endMenuCursor:BYTE
    LOCAL isWinScreen:BYTE  ; 0=GameOver, 1=YouWin
    
    ; 從參數判斷是哪個畫面 (透過 eax 傳入)
    ; 呼叫前: eax=0 表示 GameOver, eax=1 表示 YouWin
    mov isWinScreen, al
    
REDRAW_END_MENU:
    mov endMenuCursor, 0
    
    ; 設定選單顏色為白底黑字
    mov eax, black + (white * 16)
    call SetTextColor
    
    ; 繪製選單選項
    mov dh, 18
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET endMenuTitle
    call WriteString
    
    mov dh, 20
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET endMenuOption1
    call WriteString
    
    mov dh, 21
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET endMenuOption2
    call WriteString
    
    mov dh, 22
    mov dl, 28
    call Gotoxy
    mov edx, OFFSET endMenuOption3
    call WriteString
    
    mov dh, 24
    mov dl, 18
    call Gotoxy
    mov edx, OFFSET menuPrompt
    call WriteString
    
    ; 繪製初始箭頭
    mov dh, 20
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET menuArrow
    call WriteString
    
END_MENU_WAIT:
    mov eax, 50
    call Delay
    call ReadKey
    jz END_MENU_WAIT
    
    mov keyCode, ax
    movzx eax, endMenuCursor
    mov oldCursor, al
    
    mov ax, keyCode
    cmp ax, 4800h       ; Up Arrow
    je END_MENU_UP
    cmp ax, 5000h       ; Down Arrow
    je END_MENU_DOWN
    cmp al, 13          ; Enter
    je END_MENU_SELECT
    jmp END_MENU_WAIT
    
END_MENU_UP:
    movzx eax, endMenuCursor
    cmp eax, 0
    je END_MENU_WAIT
    dec endMenuCursor
    call FlushKeyBuffer
    jmp END_UPDATE_CURSOR
    
END_MENU_DOWN:
    movzx eax, endMenuCursor
    cmp eax, 2          ; 只有3個選項 (0-2)
    jge END_MENU_WAIT
    inc endMenuCursor
    call FlushKeyBuffer
    jmp END_UPDATE_CURSOR
    
END_UPDATE_CURSOR:
    ; 清除舊箭頭
    movzx eax, oldCursor
    add al, 20
    mov dh, al
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET twoSpaces
    call WriteString
    
    ; 繪製新箭頭
    movzx eax, endMenuCursor
    add al, 20
    mov dh, al
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET menuArrow
    call WriteString
    jmp END_MENU_WAIT
    
END_MENU_SELECT:
    movzx eax, endMenuCursor
    cmp eax, 0
    je RESTART_GAME
    cmp eax, 1
    je SHOW_HELP_FROM_END
    cmp eax, 2
    je EXIT_GAME_FROM_END
    
RESTART_GAME:
    ; 恢復預設顏色
    mov eax, white + (black * 16)
    call SetTextColor
    
    ; 重新開始遊戲，重置所有變數
    mov life, 10
    mov money, 50
    mov cur_round, 1
    mov gameOver, 0
    mov towerCount, 0
    mov startWave, 0
    mov menuState, 0
    
    ; 清空塔陣列
    mov ecx, towerMax
    xor eax, eax
    lea edi, towersPosX
CLEAR_TOWERS_X:
    mov WORD PTR [edi], ax
    add edi, 2
    loop CLEAR_TOWERS_X
    
    mov ecx, towerMax
    lea edi, towersPosY
CLEAR_TOWERS_Y:
    mov WORD PTR [edi], ax
    add edi, 2
    loop CLEAR_TOWERS_Y
    
    mov ecx, towerMax
    lea edi, towersType
CLEAR_TOWERS_TYPE:
    mov BYTE PTR [edi], 0
    inc edi
    loop CLEAR_TOWERS_TYPE
    
    ; 重新初始化地圖
    call initMapSystem
    call Clrscr
    
    ; 不要直接返回，應該跳出到主程式重新開始
    ; 設定特殊返回值表示要重啟
    mov eax, 999  ; 特殊代碼表示重啟
    ret
    
SHOW_HELP_FROM_END:
    call showHowToPlay
    
    ; 返回選單前清空螢幕並重新繪製標題
    call Clrscr
    
    ; 根據 isWinScreen 重新繪製對應的標題
    movzx eax, isWinScreen
    cmp eax, 1
    je REDRAW_WIN_TITLE
    
REDRAW_GAMEOVER_TITLE:
    ; 設定顏色為紅底白字
    mov eax, red + (white * 16)
    call SetTextColor
    
    ; 繪製 GAME OVER
    mov edx, OFFSET gameOverText
    INVOKE drawString, edx, 35, 10
    jmp REDRAW_END_MENU
    
REDRAW_WIN_TITLE:
    ; 設定顏色為黃底黑字
    mov eax, black + (yellow * 16)
    call SetTextColor
    
    ; 繪製 YOU WIN
    mov edx, OFFSET youWinText
    INVOKE drawString, edx, 35, 10
    jmp REDRAW_END_MENU
    
EXIT_GAME_FROM_END:
    ; 恢復預設顏色
    mov eax, white + (black * 16)
    call SetTextColor
    mov gameOver, 1
    mov eax, 0  ; 正常退出代碼
    ret
    
endGameMenu ENDP

; =================================================================================
; 繪製大數字 (3x3 ASCII Art)
; 參數: num (DWORD) - 要顯示的數字 (0-99)
;       posX (DWORD) - X 座標
;       posY (DWORD) - Y 座標
; =================================================================================
drawBigNumber PROC USES eax ebx ecx edx esi, num:DWORD, posX:DWORD, posY:DWORD
    LOCAL digit1:DWORD, digit2:DWORD
    LOCAL drawPos:COORD
    
    ; 分解數字為個位和十位
    mov eax, num
    mov ebx, 10
    xor edx, edx
    div ebx
    mov digit1, eax     ; 十位
    mov digit2, edx     ; 個位
    
    ; 顯示十位數字
    mov eax, digit1
    imul eax, 9         ; 每個數字 9 bytes (3x3)
    lea esi, bigNum0[eax]
    
    mov ax, WORD PTR posX
    mov drawPos.X, ax
    mov ax, WORD PTR posY
    mov drawPos.Y, ax
    
    ; 第1行 (十位)
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 3, drawPos, ADDR cellsWritten
    
    ; 第2行
    add esi, 3
    inc drawPos.Y
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 3, drawPos, ADDR cellsWritten
    
    ; 第3行
    add esi, 3
    inc drawPos.Y
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 3, drawPos, ADDR cellsWritten
    
    ; 顯示個位數字 (往右移4格: 3個字元+1空格)
    mov eax, digit2
    imul eax, 9
    lea esi, bigNum0[eax]
    
    mov ax, WORD PTR posX
    add ax, 4           ; 十位3個字元 + 1空格
    mov drawPos.X, ax
    mov ax, WORD PTR posY
    mov drawPos.Y, ax
    
    ; 第1行 (個位)
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 3, drawPos, ADDR cellsWritten
    
    ; 第2行
    add esi, 3
    inc drawPos.Y
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 3, drawPos, ADDR cellsWritten
    
    ; 第3行
    add esi, 3
    inc drawPos.Y
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 3, drawPos, ADDR cellsWritten
    
    ret
drawBigNumber ENDP

; =================================================================================
; 繪製大字母 (5x3 ASCII Art) - M, R, L
; 參數: letter (DWORD) - 字母 ('M'=77, 'R'=82, 'L'=76)
;       posX (DWORD) - X 座標
;       posY (DWORD) - Y 座標
; =================================================================================
drawBigLetter PROC USES eax ebx ecx edx esi, letter:DWORD, posX:DWORD, posY:DWORD
    LOCAL drawPos:COORD
    
    ; 根據字母選擇對應圖形
    mov eax, letter
    .IF eax == 'M'
        lea esi, bigLetterM
    .ELSEIF eax == 'R'
        lea esi, bigLetterR
    .ELSEIF eax == 'L'
        lea esi, bigLetterL
    .ELSEIF eax == 'A'
        lea esi, bigLetterA
    .ELSEIF eax == 'B'
        lea esi, bigLetterB
    .ELSEIF eax == 'C'
        lea esi, bigLetterC
    .ELSEIF eax == 'D'
        lea esi, bigLetterD
    .ELSEIF eax == 'E'
        lea esi, bigLetterE
    .ELSEIF eax == 'F'
        lea esi, bigLetterF
    .ELSEIF eax == 'G'
        lea esi, bigLetterG
    .ELSEIF eax == 'H'
        lea esi, bigLetterH
    .ELSEIF eax == 'I'
        lea esi, bigLetterI
    .ELSEIF eax == 'J'
        lea esi, bigLetterJ
    .ELSEIF eax == 'K'
        lea esi, bigLetterK
    .ELSEIF eax == 'N'
        lea esi, bigLetterN
    .ELSEIF eax == 'O'
        lea esi, bigLetterO
    .ELSEIF eax == 'P'
        lea esi, bigLetterP
    .ELSEIF eax == 'Q'
        lea esi, bigLetterQ
    .ELSEIF eax == 'S'
        lea esi, bigLetterS
    .ELSEIF eax == 'T'
        lea esi, bigLetterT
    .ELSEIF eax == 'U'
        lea esi, bigLetterU
    .ELSEIF eax == 'V'
        lea esi, bigLetterV
    .ELSEIF eax == 'W'
        lea esi, bigLetterW
    .ELSEIF eax == 'X'
        lea esi, bigLetterX
    .ELSEIF eax == 'Y'
        lea esi, bigLetterY
    .ELSEIF eax == 'Z'
        lea esi, bigLetterZ
    .ELSE
        ret  ; 無效字母
    .ENDIF
    
    mov ax, WORD PTR posX
    mov drawPos.X, ax
    mov ax, WORD PTR posY
    mov drawPos.Y, ax
    
    ; 第1行 (5個字元)
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 5, drawPos, ADDR cellsWritten
    
    ; 第2行
    add esi, 5
    inc drawPos.Y
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 5, drawPos, ADDR cellsWritten
    
    ; 第3行
    add esi, 5
    inc drawPos.Y
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, 5, drawPos, ADDR cellsWritten
    
    ret
drawBigLetter ENDP

; =================================================================================
; 繪製遊戲頂部資訊欄 (M: 金錢, L: 生命值, R: 回合數)
; 格式: M: XX  L: XX  R: XX
; 位置: 畫面最上方三行
; =================================================================================
drawGameStats PROC USES eax ebx ecx edx
    LOCAL startX:DWORD
    
    mov startX, 10  ; 起始X座標
    
    ; ===== M: 金錢 =====
    ; 繪製字母 M
    INVOKE drawBigLetter, 'M', startX, 0
    
    ; 繪製冒號和數字 (M後面+6, 冒號+1, 數字+2)
    mov eax, startX
    add eax, 7      ; 5(M寬度) + 1(空格) + 1(冒號位置)
    mov dh, 1       ; Y座標第2行(置中)
    mov dl, al
    call Gotoxy
    
    ; 繪製金錢數字
    mov eax, startX
    add eax, 6      ; 字母後縮小間距
    INVOKE drawBigNumber, money, eax, 0
    
    ; ===== L: 生命值 =====
    mov eax, startX
    add eax, 25     ; 加大區段間距
    mov startX, eax
    
    ; 繪製字母 L
    INVOKE drawBigLetter, 'L', startX, 0
    
    ; 繪製冒號
    mov eax, startX
    add eax, 7
    mov dh, 1
    mov dl, al
    call Gotoxy
    
    ; 繪製生命值數字
    mov eax, startX
    add eax, 6      ; 字母後縮小間距
    INVOKE drawBigNumber, life, eax, 0
    
    ; ===== R: 回合數 =====
    mov eax, startX
    add eax, 25     ; 加大區段間距
    mov startX, eax
    
    ; 繪製字母 R
    INVOKE drawBigLetter, 'R', startX, 0
    
    ; 繪製冒號
    mov eax, startX
    add eax, 7
    mov dh, 1
    mov dl, al
    call Gotoxy
    
    ; 繪製回合數字
    mov eax, startX
    add eax, 6      ; 字母後縮小間距
    INVOKE drawBigNumber, cur_round, eax, 0
    
    ret
drawGameStats ENDP

; =================================================================================
; 繪製字串 (使用 pixel art 字母和數字)
; 參數: pStr - 字串指標 (以 0 結尾)
;       startX - 起始 X 座標
;       startY - 起始 Y 座標
; 規則: 字母/數字之間 1 個空格
;       字串中的空格字元渲染為 3 個空格
; =================================================================================
drawString PROC USES eax ebx ecx edx esi, pStr:DWORD, startX:DWORD, startY:DWORD
    LOCAL currentX:DWORD
    
    mov esi, pStr
    mov eax, startX
    mov currentX, eax
    
DRAW_CHAR_LOOP:
    ; 讀取當前字元
    movzx eax, BYTE PTR [esi]
    test al, al
    jz DRAW_STRING_END  ; 遇到 0 結束
    
    ; 檢查是否為空格
    cmp al, ' '
    je HANDLE_SPACE
    
    ; 檢查是否為數字 (0-9)
    cmp al, '0'
    jl HANDLE_LETTER
    cmp al, '9'
    jg HANDLE_LETTER
    
    ; 繪製數字 (單一數字)
    sub al, '0'         ; 轉換為 0-9
    movzx eax, al
    INVOKE drawBigNumber, eax, currentX, startY
    add currentX, 4     ; 數字寬度3 + 間距1
    jmp NEXT_CHAR
    
HANDLE_LETTER:
    ; 繪製字母
    movzx eax, BYTE PTR [esi]
    INVOKE drawBigLetter, eax, currentX, startY
    add currentX, 6     ; 字母寬度5 + 間距1
    jmp NEXT_CHAR
    
HANDLE_SPACE:
    ; 字串中的空格 = 3 個空格
    add currentX, 3
    
NEXT_CHAR:
    inc esi
    jmp DRAW_CHAR_LOOP
    
DRAW_STRING_END:
    ret
drawString ENDP

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
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 12, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameA, 12, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
    ; ... (重複結構針對不同塔名) ...
SHOW_NAME_B:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 12, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameB, 12, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_C:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 12, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameC, 12, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_D:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 12, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameD, 12, sideMenuCursorPos, ADDR count
    jmp SKIP_NAME
SHOW_NAME_E:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR attrMenuName, 12, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR strNameE, 12, sideMenuCursorPos, ADDR count
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
    ; 覆蓋名稱（包含價格，需要 12 個字元）
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR outerAttributes, 12, sideMenuCursorPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR emptyLine, 12, sideMenuCursorPos, ADDR count
    ret
clearSideMenuCursor ENDP

; =================================================================================
; 切換選單狀態 - [修正版]
; 修正：關閉選單時補畫怪物。
; =================================================================================
toggleMenuState PROC
    mov eax, menuState
    xor eax, 1          
    mov menuState, eax
    
    cmp eax, 1
    je SWITCH_TO_MENU   
    
    ; --- 關閉選單時 (清除範圍) ---
    call clearSideMenuCursor 
    call drawMapComponents  ; 清除範圍
    call drawAllTowers      ; 補畫塔
    call drawMonsters       ; <--- [新增] 補畫怪物
    jmp TOGGLE_DONE

SWITCH_TO_MENU:
    call drawSideMenuCursor
    INVOKE drawAttackRangeOverlay, 1
TOGGLE_DONE:
    ret
toggleMenuState ENDP

; =================================================================================
; 處理側邊選單輸入 - [修正版]
; 修正：在清除舊範圍後，補畫怪物 (drawMonsters)，防止怪物消失。
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
    call clearSideMenuCursor
    ; [清除畫面]
    call drawMapComponents ; 畫地圖 (會蓋掉紅色範圍，但也蓋掉怪物)
    call drawAllTowers     ; 畫塔
    call drawMonsters      ; <--- [新增] 把怪物畫回來！
    
    dec sideMenuCursorIndex       
    cmp sideMenuCursorIndex, 0
    jge UPDATE_CURSOR
    mov sideMenuCursorIndex, 4    
    jmp UPDATE_CURSOR

MENU_DOWN:
    call clearSideMenuCursor 
    ; [清除畫面]
    call drawMapComponents
    call drawAllTowers
    call drawMonsters      ; <--- [新增] 把怪物畫回來！
    
    inc sideMenuCursorIndex       
    cmp sideMenuCursorIndex, 4
    jle UPDATE_CURSOR
    mov sideMenuCursorIndex, 0    
    jmp UPDATE_CURSOR

UPDATE_CURSOR:
    call drawSideMenuCursor
    ; 畫出新範圍
    INVOKE drawAttackRangeOverlay, 1
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
; 繪製攻擊範圍覆蓋層 - [空心正圓版]
; 整合了標準畫圓演算法，僅顯示範圍邊緣的圓圈
; =================================================================================
drawAttackRangeOverlay PROC USES eax ebx ecx edx esi edi, logicType:DWORD
    LOCAL rangeSq:DWORD              ; 攻擊範圍半徑平方
    LOCAL rangeLimitMin:DWORD        ; 空心圓的內圈界線
    LOCAL cursorGridX:DWORD          ; 圓心 X
    LOCAL cursorGridY:DWORD          ; 圓心 Y
    LOCAL currentGridX:DWORD         ; 當前掃描 X
    LOCAL currentGridY:DWORD         ; 當前掃描 Y
    LOCAL pixelDistSq:DWORD          ; 計算出的距離平方
    LOCAL screenPos:COORD            ; 螢幕繪圖座標
    LOCAL attrBuffer[32]:WORD        ; 顏色屬性緩衝區
    LOCAL charBuffer[32]:BYTE        ; 字元緩衝區

    ; ---------------------------------------------------------
    ; 1. 準備繪圖樣式 (紅底紅字 = 0044h，文字為空白)
    ; ---------------------------------------------------------
    lea edi, attrBuffer
    mov ecx, 32
    mov ax, 0044h      ; 紅色背景
    rep stosw          

    lea edi, charBuffer
    mov ecx, 32
    mov al, 20h        ; 空白字元 (蓋掉底下的地圖符號，讓線條更乾淨)
    rep stosb

    ; ---------------------------------------------------------
    ; 2. 取得塔的攻擊範圍並設定「厚度」
    ; ---------------------------------------------------------
    mov eax, sideMenuCursorIndex
    mov esi, OFFSET towerRangeSq     
    imul eax, 4
    mov eax, DWORD PTR [esi+eax]
    mov rangeSq, eax

    ; 設定圓圈厚度 (Threshold)
    ; 數值越大圈圈越粗。因為座標乘了5倍，約 150~200 適合 1 格寬度
    sub eax, 250       
    mov rangeLimitMin, eax

    ; ---------------------------------------------------------
    ; 3. 計算圓心 (游標所在的 Grid 座標)
    ; ---------------------------------------------------------
    movzx eax, blockPos.X
    sub eax, 7                       
    mov ebx, blockWidth              
    xor edx, edx
    div ebx
    mov cursorGridX, eax

    movzx eax, blockPos.Y
    sub eax, 4                       
    mov ebx, blockHeight             
    xor edx, edx
    div ebx
    mov cursorGridY, eax

    ; ---------------------------------------------------------
    ; 4. 掃描整個地圖 Grid (15x7)
    ; ---------------------------------------------------------
    mov currentGridY, 0 
ROW_LOOP:
    mov eax, currentGridY
    cmp eax, MAP_HEIGHT
    jge DONE_OVERLAY
    
    mov currentGridX, 0 
COL_LOOP:
    mov eax, currentGridX
    cmp eax, MAP_WIDTH
    jge NEXT_ROW

    ; ---------------------------------------------------------
    ; 5. 計算距離平方 (畫圓核心演算法)
    ; Formula: DistSq = (dx * 5)^2 + (dy * 5)^2
    ; ---------------------------------------------------------
    
    ; --- 計算 X 距離 ---
    mov eax, currentGridX
    sub eax, cursorGridX
    imul eax, blockWidth    ; 乘以 5
    imul eax, eax           ; 平方
    mov pixelDistSq, eax
    
    ; --- 計算 Y 距離 ---
    mov eax, currentGridY
    sub eax, cursorGridY
    imul eax, blockWidth    ; ★ 關鍵：Y軸也乘 5 (而非3)，強制視覺為正圓
    imul eax, eax           ; 平方
    add pixelDistSq, eax    ; 相加

    ; ---------------------------------------------------------
    ; 6. 空心圓判斷邏輯
    ; 條件：RangeLimitMin <= DistSq <= RangeSq
    ; ---------------------------------------------------------
    
    mov eax, pixelDistSq
    
    ; 檢查 1: 是否超出外圈？ ( > RangeSq )
    cmp eax, rangeSq
    jg NEXT_COL             ; 太遠了，不畫
    
    ; 檢查 2: 是否在內圈裡面？ ( < RangeLimitMin )
    cmp eax, rangeLimitMin
    jl NEXT_COL             ; 太近了(在圓心)，不畫 -> 形成空心效果

    ; ---------------------------------------------------------
    ; 7. 符合條件，執行繪製
    ; ---------------------------------------------------------
    ; 計算螢幕座標 X
    mov eax, currentGridX
    imul eax, blockWidth
    add eax, 7
    mov screenPos.X, ax
    
    ; 計算螢幕座標 Y
    mov eax, currentGridY
    imul eax, blockHeight
    add eax, 4
    mov screenPos.Y, ax

    ; 填滿這一個 Block
    mov edi, blockHeight 
COLOR_FILL_LOOP:
    push edi
    
    ; 寫入紅色屬性
    lea esi, attrBuffer
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, screenPos, ADDR cellsWritten
    
    ; 寫入空白字元 (消除雜訊)
    lea esi, charBuffer
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, blockWidth, screenPos, ADDR cellsWritten
    
    inc screenPos.Y
    pop edi
    dec edi
    cmp edi, 0
    jg COLOR_FILL_LOOP

NEXT_COL:
    inc currentGridX
    jmp COL_LOOP
NEXT_ROW:
    inc currentGridY
    jmp ROW_LOOP

DONE_OVERLAY:
    ret
drawAttackRangeOverlay ENDP


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
    ; =========================================================
    ; [新增修正] 補畫怪物
    ; 防止游標還原地圖或塔時，把原本站在那裡的怪物「蓋掉」
    ; 這裡會檢查所有活著的怪物並重畫，確保圖層順序正確 (怪物在塔/地圖之上)
    ; =========================================================
    call drawMonsters

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
    ; 1. 更新動畫計時器
    call updateDashAnimation    
    
    ; 2. [清除舊游標] 
    ; 先把「上一次」游標所在的位置還原成原本的地圖/塔
    call restoreGraphicsAtPos   
    
    ; 3. [範圍顯示邏輯] 
    ; 因為 restoreGraphicsAtPos 會把游標下的紅色範圍還原成綠色/路徑
    ; 所以如果選單開啟中，我們必須補畫一次範圍，確保游標底下也是紅色的
    cmp menuState, 1
    jne SKIP_RANGE_DRAW

    ; 直接畫紅色 (參數 1 已無意義，但保留以符合 PROTO)
    INVOKE drawAttackRangeOverlay, 1
    
SKIP_RANGE_DRAW:

    ; 4. [畫新游標] 畫出「這一次」的虛線框
    call drawMovingDashedCursor

    ; =========================================================
    ; 更新 prevBlockPos
    ; =========================================================
    mov ax, blockPos.X
    mov prevBlockPos.X, ax
    mov ax, blockPos.Y
    mov prevBlockPos.Y, ax

    ; 繪製頂部狀態欄
    call drawGameStats

    ; =========================================================
    ; 戰鬥狀態處理
    ; =========================================================
    cmp startWave, 1          
    jne SKIP_COMBAT_LOGIC     
    
    call ctrlDraw
    call towerCombatSystem

SKIP_COMBAT_LOGIC:	
    ; 生命值與勝利檢測
    .IF life == 0
        mov gameOver, 1   
        ret               
    .ENDIF
    .IF cur_round >= 21
        ret               
    .ENDIF
	
    ; 延遲與讀取輸入
    mov eax, 50                 
    call Delay
    call ReadKey
    jz NO_KEY_PRESSED
    
    ; ---------------------------------------------------------
    ; [Debug 快捷鍵] (省略，保持原樣)
    ; ---------------------------------------------------------
    .IF ax == 0221h    ; 1: life--
        .IF life > 0
            dec life
        .ENDIF
    .ELSEIF ax == 0340h    ; @: life++
        inc life
    .ELSEIF ax == 0423h    ; #: money--
        .IF money > 0
            dec money
        .ENDIF
    .ELSEIF ax == 0524h    ; $: money++
        inc money
    .ELSEIF ax == 0625h    ; %: round--
        .IF cur_round > 1
            dec cur_round
        .ENDIF
    .ELSEIF ax == 075Eh    ; ^: round++
        inc cur_round
    .ENDIF
    
    ; [G鍵] 開始戰鬥
    .IF (al == 'g') || (al == 'G')
        .IF (startWave == 0) && (menuState == 0)
            invoke createMonsters, cur_round
            mov startWave, 1      
        .ENDIF
    .ENDIF

    ; [F鍵] 開啟/關閉選單
    .IF ax == 2166h ; 'f'
        .IF startWave == 0
            call toggleMenuState
            jmp START_MOVE 
        .ENDIF
    .ENDIF
    
    ; =========================================================
    ; [輸入處理修正] 
    ; =========================================================
    
    ; 1. 如果選單開啟，處理選塔
    cmp menuState, 1
    jne CHECK_NORMAL_INPUT
    
    call handleSideMenuInput
    ; 選單開啟時，不跳轉到一般輸入，也不執行移動邏輯 -> 鎖定游標
    jmp END_INPUT_CHECK

CHECK_NORMAL_INPUT:
    ; 2. 正常模式：可以移動
    call handleNormalInput      
    jmp END_INPUT_CHECK

NO_KEY_PRESSED:
END_INPUT_CHECK:

    ; [ESC鍵] (省略，保持原樣)
    .IF ax == 011Bh 
        call showEscMenu
        .IF eax == 1  ; Continue
            INVOKE SetConsoleTextAttribute, outputHandle, 0F0h 
            call Clrscr
            call outerBox
            call drawMapComponents
            call drawAllTowers
            call drawSideMenu
        .ELSEIF eax == 2  ; Restart
            mov life, 10
            mov money, 50
            mov cur_round, 1
            mov gameOver, 0
            mov towerCount, 0
            mov startWave, 0
            mov menuState, 0
            
            ; 清空塔
            push ecx
            push edi
            push eax
            mov ecx, towerMax
            xor eax, eax
            lea edi, towersPosX
            CLEAR_ESC_TOWERS_X: mov WORD PTR [edi], ax
            add edi, 2
            loop CLEAR_ESC_TOWERS_X
            mov ecx, towerMax
            lea edi, towersPosY
            CLEAR_ESC_TOWERS_Y: mov WORD PTR [edi], ax
            add edi, 2
            loop CLEAR_ESC_TOWERS_Y
            mov ecx, towerMax
            lea edi, towersType
            CLEAR_ESC_TOWERS_TYPE: mov BYTE PTR [edi], 0
            inc edi
            loop CLEAR_ESC_TOWERS_TYPE
            pop eax
            pop edi
            pop ecx
            
            call initMapSystem
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
    
    ; 4. 檢查金錢是否足夠
    mov eax, 0
    mov al, bl              ; bl 包含塔的類型 (1-5)
    dec eax                 ; 轉換為陣列索引 (0-4)
    mov esi, OFFSET towerCosts
    imul eax, 4             ; DWORD = 4 bytes
    add esi, eax
    mov eax, DWORD PTR [esi] ; 取得此塔的價格
    cmp money, eax          ; 比較現有金錢與價格
    jl NO_ADD_TYPE          ; 金錢不足，無法建造
    
    ; 5. 扣除金錢
    sub money, eax
    
    ; 6. 寫入資料陣列
    mov ecx, towerCount     ; 使用 towerCount 作為索引
    ; 寫入 X
    mov esi, OFFSET towersPosX
    mov eax, ecx            ; 使用 ecx (towerCount) 而不是被修改的 eax
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
    ; 取得被刪除塔的類型並計算歸還金錢
    mov esi, OFFSET towersType
    add esi, ecx                ; ecx 是塔的索引
    mov al, BYTE PTR [esi]      ; 取得塔類型 (1-5)
    mov ebx, 0
    mov bl, al
    dec ebx                     ; 轉換為陣列索引 (0-4)
    mov esi, OFFSET towerCosts
    imul ebx, 4                 ; DWORD = 4 bytes
    add esi, ebx
    mov eax, DWORD PTR [esi]    ; 取得原價格
    shr eax, 1                  ; 除以 2 (一半價格)
    add money, eax              ; 歸還一半金錢
    
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