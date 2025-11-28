INCLUDE Irvine32.inc

main EQU start@0

; 外框尺寸
outerBoxWidth = 84
outerBoxHeight = 26

; 方塊尺寸
blockWidth  = 5
blockHeight = 3

; 地圖系統常數
MAP_WIDTH = 16      ; 地圖格子寬度 (84/5 - 1 邊框 = 16格)
MAP_HEIGHT = 8      ; 地圖格子高度 (26/3 - 1 邊框 = 8格)

; 地圖元件類型常數
COMPONENT_EMPTY = 0     ; 空地 (可放塔)
COMPONENT_OUTLET = 1    ; 出口 (怪物出生點)
COMPONENT_EXIT = 2      ; 終點
COMPONENT_PATH_H = 3    ; 水平路徑
COMPONENT_PATH_V = 4    ; 垂直路徑
COMPONENT_CORNER_1 = 5  ; 轉角1
COMPONENT_CORNER_2 = 6  ; 轉角2
COMPONENT_CORNER_3 = 7  ; 轉角3
COMPONENT_CORNER_4 = 8  ; 轉角4

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
cursorAttributes WORD blockWidth DUP(0Fh)     ; 黑底白字 (游標位置)

hConsole HANDLE ?

; Tower 相關
towerMax EQU 30 ; tower 上限設定
towersPosX WORD towerMax DUP(?)  ; X位置
towersPosY WORD towerMax DUP(?)  ; Y位置
towersType BYTE towerMax DUP(?)  ; 類型
towerCount DWORD 0
tempBuffer BYTE blockWidth DUP(?)
useCursorColor DWORD 0  ; 0=使用正常顏色, 1=使用游標顏色
blinkCounter DWORD 0    ; 閃爍計數器
blinkState DWORD 0      ; 0=白底黑字, 1=黑底白字
BLINK_SPEED EQU 10      ; 閃爍速度 (每10幀切換一次，更快閃爍)

; 地圖系統變數
mapData BYTE (MAP_WIDTH * MAP_HEIGHT) DUP(0)  ; 地圖資料

; 地圖1的資料
map1Data BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
         BYTE 0,1,0,6,3,3,3,3,3,3,3,5,0,2,0,0
         BYTE 0,4,0,4,0,0,0,0,0,0,0,4,0,4,0,0
         BYTE 0,4,0,4,0,0,6,3,3,3,3,8,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,4,0,4,0,0,4,0,0,0,0,0,0,4,0,0
         BYTE 0,7,3,8,0,0,7,3,3,3,3,3,3,8,0,0
         BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; 元件字元資料
componentChars LABEL BYTE
; 元件0: 空地 (無字元)
component0 BYTE 5 DUP(20h)
           BYTE 5 DUP(20h) 
           BYTE 5 DUP(20h)
; 元件1: 怪物出口
component1 BYTE 5 DUP(20h)
           BYTE 20h, 3 DUP(0DCh), 20h
           BYTE 0DEh, 0DBh, 0DFh, 0DBh, 0DDh
; 元件2: 終點
component2 BYTE 5 DUP(20h)
           BYTE 20h, 3 DUP(0DCh), 20h
           BYTE 0DEh, 3 DUP(0B0h), 0DDh
; 元件3: 水平路徑
component3 BYTE 5 DUP(20h)
           BYTE 5 DUP(0B0h)
           BYTE 5 DUP(20h)
; 元件4: 垂直路徑
component4 BYTE 20h, 3 DUP(0B0h), 20h
           BYTE 20h, 3 DUP(0B0h), 20h
           BYTE 20h, 3 DUP(0B0h), 20h
; 元件5: 轉角1 (右上)
component5 BYTE 5 DUP(20h)
           BYTE 4 DUP(0B0h), 20h
           BYTE 20h, 3 DUP(0B0h), 20h
           
; 元件6: 轉角2 (左上)
component6 BYTE 5 DUP(20h)
           BYTE 20h, 4 DUP(0B0h)
           BYTE 20h, 3 DUP(0B0h), 20h
; 元件7: 轉角3 (左下)
component7 BYTE 20h, 3 DUP(0B0h), 20h
           BYTE 20h, 4 DUP(0B0h)
           BYTE 5 DUP(20h)
; 元件8: 轉角4 (右下)
component8 BYTE 20h, 3 DUP(0B0h), 20h
           BYTE 4 DUP(0B0h), 20h
           BYTE 5 DUP(20h)

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
drawBlock PROC USES eax esi
    ; 檢查游標位置是否有地圖元件
    call hasMapComponentAtCursor
    cmp eax, 1
    je SKIP_DRAW_CURSOR_FRAME     ; 如果有地圖元件，不繪製框框

    push DWORD PTR outerBoxPos
    mov ax, blockPos.X
    mov dx, blockPos.Y
    mov outerBoxPos.X, ax
    mov outerBoxPos.Y, dx

    ; 獲取閃爍顏色屬性
    call getBlinkColorAttributes
    
    ; 畫上 (使用閃爍顏色)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockTop, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 畫中 (使用閃爍顏色)
    mov cx, blockHeight-2
L2:
    push cx
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockBody, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    pop cx
    loop L2

    ; 畫下 (使用閃爍顏色)
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR BlockBottom, blockWidth, outerBoxPos, ADDR count
    pop DWORD PTR outerBoxPos

SKIP_DRAW_CURSOR_FRAME:
    ret
drawBlock ENDP

;------------------------------------------------
; 檢查游標位置是否有地圖元件 (不包括空地)
; 輸出: EAX = 1 有地圖元件, 0 空地
;------------------------------------------------
hasMapComponentAtCursor PROC USES ebx ecx esi
    ; 將像素座標轉換為地圖格子座標
    movzx eax, blockPos.X
    sub eax, 7          ; 減去初始偏移
    mov ebx, blockWidth
    xor edx, edx
    div ebx             ; EAX = 格子X座標
    mov ebx, eax        ; 保存X座標
    
    movzx eax, blockPos.Y
    sub eax, 4          ; 減去初始偏移
    mov ecx, blockHeight
    xor edx, edx
    div ecx             ; EAX = 格子Y座標
    
    ; 檢查座標是否在有效範圍內
    cmp ebx, MAP_WIDTH
    jge NO_MAP_COMPONENT
    cmp eax, MAP_HEIGHT
    jge NO_MAP_COMPONENT
    cmp ebx, 0
    jl NO_MAP_COMPONENT
    cmp eax, 0
    jl NO_MAP_COMPONENT
    
    ; 計算地圖資料的索引
    mov ecx, MAP_WIDTH
    mul ecx             ; EAX = Y * MAP_WIDTH
    add eax, ebx        ; EAX = Y * MAP_WIDTH + X
    
    ; 取得地圖資料
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    
    ; 檢查是否為空地
    cmp al, COMPONENT_EMPTY
    je NO_MAP_COMPONENT
    
    ; 有地圖元件
    mov eax, 1
    ret
    
NO_MAP_COMPONENT:
    mov eax, 0
    ret
hasMapComponentAtCursor ENDP

;------------------------------------------------
; 在地圖元件上繪製游標反白效果
;------------------------------------------------
drawCursorOnComponent PROC USES eax ebx ecx edx esi edi
    ; 將像素座標轉換為地圖格子座標
    movzx eax, blockPos.X
    sub eax, 7          ; 減去初始偏移
    mov ebx, blockWidth
    xor edx, edx
    div ebx             ; EAX = 格子X座標
    mov ebx, eax        ; 保存X座標
    
    movzx eax, blockPos.Y
    sub eax, 4          ; 減去初始偏移
    mov ecx, blockHeight
    xor edx, edx
    div ecx             ; EAX = 格子Y座標
    
    ; 檢查座標是否在有效範圍內
    cmp ebx, MAP_WIDTH
    jge SKIP_CURSOR_HIGHLIGHT
    cmp eax, MAP_HEIGHT
    jge SKIP_CURSOR_HIGHLIGHT
    cmp ebx, 0
    jl SKIP_CURSOR_HIGHLIGHT
    cmp eax, 0
    jl SKIP_CURSOR_HIGHLIGHT
    
    ; 計算地圖資料的索引
    mov ecx, MAP_WIDTH
    mul ecx             ; EAX = Y * MAP_WIDTH
    add eax, ebx        ; EAX = Y * MAP_WIDTH + X
    
    ; 取得地圖資料
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi]  ; 取得元件類型
    
    ; 如果不是空地，在元件上繪製反白效果
    cmp cl, COMPONENT_EMPTY
    je SKIP_CURSOR_HIGHLIGHT
    
    ; 恢復格子座標到 EAX(Y), EBX(X)
    movzx eax, blockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx             ; EAX = Y座標
    
    ; 計算螢幕座標
    call calculateScreenPosition
    
    ; 獲取閃爍顏色屬性
    call getBlinkColorAttributes
    
    ; 在元件上繪製反白效果 (只改變屬性，不改變字元)
    mov ecx, blockHeight
CURSOR_HIGHLIGHT_Y_LOOP:
    push ecx
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    inc outerBoxPos.Y
    pop ecx
    loop CURSOR_HIGHLIGHT_Y_LOOP
    
SKIP_CURSOR_HIGHLIGHT:
    ret
drawCursorOnComponent ENDP

;------------------------------------------------
; 移動方塊 (修改版本，加入預設處理)
;------------------------------------------------
moveBlock PROC
START_MOVE:
    ; 更新閃爍狀態
    call updateBlinkState
    
    call Clrscr
    call outerBox
    call drawMapComponents  ; 繪製地圖元件
    call drawBlock
    call drawCursorOnComponent  ; 在地圖元件上繪製游標反白效果
    call drawAllTowers

    ; 添加短暫延遲使閃爍可見
    mov eax, 50
    call Delay
    
    ; 檢查是否有按鍵輸入（非阻塞）
    call ReadKey
    jz NO_KEY_PRESSED  ; 如果沒有按鍵，跳過按鍵處理
    
    ; 有按鍵輸入，處理按鍵

    ; 檢查放置Tower的鍵
    .IF ax == 1e61h      ; a鍵
        mov bl, 1
        call addTowerWithType
    .ELSEIF ax == 3062h  ; b鍵
        mov bl, 2
        call addTowerWithType
    .ELSEIF ax == 2e63h  ; c鍵
        mov bl, 3
        call addTowerWithType
    .ELSEIF ax == 2064h  ; d鍵
        mov bl, 4
        call addTowerWithType
    .ELSEIF ax == 1265h  ; e鍵
        mov bl, 5
        call addTowerWithType
    .ELSEIF ax == 2d78h  ; x鍵 - 刪除塔
        call deleteTower
    .ENDIF
    
        ; 方向鍵檢測
    .IF ax == 4800h ; UP
        sub blockPos.Y, blockHeight
        mov bx, blockPosInit.Y
        cmp blockPos.Y, bx
        jge END_MOVE
        add blockPos.Y, blockHeight
    .ELSEIF ax == 5000h ; DOWN
        add blockPos.Y, blockHeight
        mov bx, (blockHeight * 7)
        add bx, blockPosInit.Y
        cmp blockPos.Y, bx
        jbe END_MOVE
        sub blockPos.Y, blockHeight
    .ELSEIF ax == 4B00h ; LEFT
        sub blockPos.X, blockWidth
        mov bx, blockPosInit.X
        cmp blockPos.X, bx
        jae END_MOVE
        add blockPos.X, blockWidth
    .ELSEIF ax == 4D00h ; RIGHT
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

NO_KEY_PRESSED:
END_MOVE:
    jmp START_MOVE
EXIT_MOVE:
    ret
moveBlock ENDP

;------------------------------------------------
; 添加Tower (舊版本，保留相容性)
;------------------------------------------------
addTower PROC USES eax ebx esi
    mov bl, 1  ; 預設類型
    call addTowerWithType
    ret
addTower ENDP

;------------------------------------------------
; 添加指定類型的Tower
;------------------------------------------------
addTowerWithType PROC USES eax ecx esi
    ; bl 包含塔的類型 (1-5)
    
    ; 先檢查當前位置是否已有塔
    call checkTowerAtCurrentPosition
    cmp eax, 1
    je NO_ADD_TYPE      ; 如果已有塔，不放置
    
    ; 檢查是否可以在當前位置放置塔 (地圖限制)
    call canPlaceTowerAtCurrentPos
    cmp eax, 0
    je NO_ADD_TYPE      ; 如果地圖不允許，不放置
    
    mov eax, towerCount
    cmp eax, towerMax
    jge NO_ADD_TYPE
    
    ; 保存當前索引
    mov ecx, eax
    
    ; 設定 X 座標
    mov esi, OFFSET towersPosX
    imul eax, 2  ; WORD 大小
    add esi, eax
    mov ax, blockPos.X
    mov WORD PTR [esi], ax
    
    ; 設定 Y 座標
    mov esi, OFFSET towersPosY
    mov eax, ecx
    imul eax, 2  ; WORD 大小
    add esi, eax
    mov ax, blockPos.Y
    mov WORD PTR [esi], ax
    
    ; 設定類型
    mov esi, OFFSET towersType
    mov eax, ecx
    add esi, eax  ; BYTE 大小
    mov BYTE PTR [esi], bl
    
    inc towerCount
NO_ADD_TYPE:
    ret
addTowerWithType ENDP

;------------------------------------------------
; 檢查當前位置是否已有塔
;------------------------------------------------
checkTowerAtCurrentPosition PROC USES ebx ecx esi
    mov ecx, 0          ; 索引計數器
    
CHECK_POSITION_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_AT_POSITION
    
    ; 獲取塔的X座標
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2         ; WORD大小
    add esi, ebx
    mov bx, WORD PTR [esi]
    
    ; 比較X座標
    cmp bx, blockPos.X
    jne NEXT_TOWER_CHECK
    
    ; 獲取塔的Y座標
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2         ; WORD大小
    add esi, ebx
    mov bx, WORD PTR [esi]
    
    ; 比較Y座標
    cmp bx, blockPos.Y
    je TOWER_FOUND_AT_POSITION
    
NEXT_TOWER_CHECK:
    inc ecx
    jmp CHECK_POSITION_LOOP
    
TOWER_FOUND_AT_POSITION:
    mov eax, 1          ; 找到塔
    ret
    
NO_TOWER_AT_POSITION:
    mov eax, 0          ; 沒有找到塔
    ret
checkTowerAtCurrentPosition ENDP

;------------------------------------------------
; 刪除塔功能
;------------------------------------------------
deleteTower PROC USES eax ebx ecx esi
    ; 先檢查是否有塔
    cmp towerCount, 0
    je NO_TOWER_FOUND
    
    mov ecx, 0          ; 索引計數器
    
CHECK_TOWER_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_FOUND
    
    ; 檢查當前塔是否與block位置重疊
    call isTowerAtPositionSimple
    cmp eax, 1          ; 如果找到重疊的塔
    je DELETE_FOUND_TOWER
    
    inc ecx
    jmp CHECK_TOWER_LOOP
    
DELETE_FOUND_TOWER:
    ; 刪除索引為ecx的塔
    call removeTowerAtIndexSimple
    jmp DELETE_DONE
    
NO_TOWER_FOUND:
    ; 沒有找到塔，什麼都不做
    
DELETE_DONE:
    ret
deleteTower ENDP

;------------------------------------------------
; 檢查指定索引的塔是否與當前block位置重疊 (簡化版)
;------------------------------------------------
isTowerAtPositionSimple PROC USES ebx esi
    ; 使用ecx作為塔索引
    
    ; 獲取塔的X座標
    mov esi, OFFSET towersPosX
    mov ebx, ecx
    imul ebx, 2         ; WORD大小
    add esi, ebx
    mov bx, WORD PTR [esi]
    
    ; 比較X座標
    cmp bx, blockPos.X
    jne NOT_MATCH_SIMPLE
    
    ; 獲取塔的Y座標
    mov esi, OFFSET towersPosY
    mov ebx, ecx
    imul ebx, 2         ; WORD大小
    add esi, ebx
    mov bx, WORD PTR [esi]
    
    ; 比較Y座標
    cmp bx, blockPos.Y
    jne NOT_MATCH_SIMPLE
    
    ; 位置匹配
    mov eax, 1
    ret
    
NOT_MATCH_SIMPLE:
    mov eax, 0
    ret
isTowerAtPositionSimple ENDP

;------------------------------------------------
; 移除指定索引的塔 (簡化版)
;------------------------------------------------
removeTowerAtIndexSimple PROC USES eax ebx edx esi edi
    ; 使用ecx作為要刪除的塔索引
    mov eax, ecx        ; 獲取要刪除的索引（使用ecx）
    mov ebx, towerCount
    dec ebx             ; 最後一個塔的索引
    
    ; 如果要刪除的不是最後一個塔，需要移動數據
    cmp eax, ebx
    jge JUST_DECREASE_COUNT_SIMPLE
    
    ; 保存要刪除的索引
    mov edx, eax
    
    ; 移動X座標數組
    mov esi, OFFSET towersPosX
    mov eax, edx
    imul eax, 2         ; 起始位置
    add esi, eax
    mov edi, esi
    add esi, 2          ; 下一個位置
    mov eax, ebx        ; 最後索引
    sub eax, edx        ; 需要移動的元素數量
    
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
    ; 移動Y座標數組
    mov esi, OFFSET towersPosY
    mov eax, edx        ; 恢復索引
    imul eax, 2         ; 起始位置
    add esi, eax
    mov edi, esi
    add esi, 2          ; 下一個位置
    mov eax, ebx        ; 最後索引
    sub eax, edx        ; 需要移動的元素數量
    
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
    ; 移動類型數組
    mov esi, OFFSET towersType
    mov eax, edx        ; 恢復索引
    add esi, eax        ; 起始位置
    mov edi, esi
    inc esi             ; 下一個位置
    mov eax, ebx        ; 最後索引
    sub eax, edx        ; 需要移動的元素數量
    
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

    ; 檢查是否與游標位置重疊
    call checkIfCursorOverlapsTower
    
    ; 根據類型畫不同樣式的塔
    .IF bl == 1      ; a鍵
        call drawATower
    .ELSEIF bl == 2  ; b鍵
        call drawBTower
    .ELSEIF bl == 3  ; c鍵
        call drawCTower
    .ELSEIF bl == 4  ; d鍵
        call drawDTower
    .ELSEIF bl == 5  ; e鍵
        call drawETower
    .ELSE            ; 預設基礎塔
        call drawATower
    .ENDIF
    
    pop DWORD PTR outerBoxPos
    ret 4  ; 清除參數
drawTower ENDP

;------------------------------------------------
; 檢查游標是否與當前塔位置重疊
;------------------------------------------------
checkIfCursorOverlapsTower PROC
    ; 比較 X 座標
    mov ax, outerBoxPos.X
    cmp ax, blockPos.X
    jne NO_OVERLAP_TOWER
    
    ; 比較 Y 座標
    mov ax, outerBoxPos.Y
    cmp ax, blockPos.Y
    jne NO_OVERLAP_TOWER
    
    ; 位置重疊，設定使用游標顏色
    mov useCursorColor, 1
    ret
    
NO_OVERLAP_TOWER:
    ; 位置不重疊，使用正常顏色
    mov useCursorColor, 0
    ret
checkIfCursorOverlapsTower ENDP

;------------------------------------------------
; 取得適當的顏色屬性 (返回在 ESI)
;------------------------------------------------
getTowerColorAttributes PROC
    cmp useCursorColor, 1
    je USE_CURSOR_COLOR_TOWER
    
    ; 使用正常顏色
    mov esi, OFFSET blockAttributes
    ret
    
USE_CURSOR_COLOR_TOWER:
    ; 使用閃爍顏色 - 根據閃爍狀態選擇
    mov eax, blinkState
    cmp eax, 0
    je USE_NORMAL_BLINK
    
    ; 閃爍狀態1: 黑底白字
    mov esi, OFFSET cursorAttributes
    ret
    
USE_NORMAL_BLINK:
    ; 閃爍狀態0: 白底黑字
    mov esi, OFFSET blockAttributes
    ret
getTowerColorAttributes ENDP

;------------------------------------------------
; 更新閃爍狀態
;------------------------------------------------
updateBlinkState PROC
    inc blinkCounter
    mov eax, blinkCounter
    cmp eax, BLINK_SPEED
    jl NO_BLINK_CHANGE
    
    ; 重置計數器並切換狀態
    mov blinkCounter, 0
    mov eax, blinkState
    xor eax, 1          ; 0變1, 1變0
    mov blinkState, eax
    
NO_BLINK_CHANGE:
    ret
updateBlinkState ENDP

;------------------------------------------------
; 獲取游標區塊的閃爍顏色屬性
;------------------------------------------------
getBlinkColorAttributes PROC
    mov eax, blinkState
    cmp eax, 0
    je USE_NORMAL_CURSOR_COLOR
    
    ; 閃爍狀態1: 黑底白字
    mov esi, OFFSET cursorAttributes
    ret
    
USE_NORMAL_CURSOR_COLOR:
    ; 閃爍狀態0: 白底黑字
    mov esi, OFFSET blockAttributes
    ret
getBlinkColorAttributes ENDP

;------------------------------------------------
; 初始化地圖系統
;------------------------------------------------
initMapSystem PROC USES eax ecx esi edi
    ; 載入地圖1的資料
    mov esi, OFFSET map1Data
    mov edi, OFFSET mapData
    mov ecx, (MAP_WIDTH * MAP_HEIGHT)
    rep movsb   
    ret
initMapSystem ENDP

;------------------------------------------------
; 檢查指定位置是否可以放置塔
; 輸入: blockPos.X, blockPos.Y (游標位置)
; 輸出: EAX = 1 可放置, 0 不可放置
;------------------------------------------------
canPlaceTowerAtCurrentPos PROC USES ebx ecx esi
    ; 將像素座標轉換為地圖格子座標
    movzx eax, blockPos.X
    sub eax, 7          ; 減去初始偏移
    mov ebx, blockWidth
    xor edx, edx
    div ebx             ; EAX = 格子X座標
    mov ebx, eax        ; 保存X座標
    
    movzx eax, blockPos.Y
    sub eax, 4          ; 減去初始偏移
    mov ecx, blockHeight
    xor edx, edx
    div ecx             ; EAX = 格子Y座標
    
    ; 檢查座標是否在有效範圍內
    cmp ebx, MAP_WIDTH
    jge CANNOT_PLACE
    cmp eax, MAP_HEIGHT
    jge CANNOT_PLACE
    cmp ebx, 0
    jl CANNOT_PLACE
    cmp eax, 0
    jl CANNOT_PLACE
    
    ; 計算地圖資料的索引
    mov ecx, MAP_WIDTH
    mul ecx             ; EAX = Y * MAP_WIDTH
    add eax, ebx        ; EAX = Y * MAP_WIDTH + X
    
    ; 取得地圖資料
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    
    ; 檢查格子類型 (只有空地才能放塔)
    cmp al, COMPONENT_EMPTY
    je CAN_PLACE
    
CANNOT_PLACE:
    mov eax, 0
    ret
    
CAN_PLACE:
    mov eax, 1
    ret
canPlaceTowerAtCurrentPos ENDP

;------------------------------------------------
; 繪製地圖元件
;------------------------------------------------
drawMapComponents PROC USES eax ebx ecx edx esi edi
    mov eax, 0          ; Y座標
    
DRAW_MAP_Y_LOOP:
    cmp eax, MAP_HEIGHT
    jge DRAW_MAP_DONE
    
    mov ebx, 0          ; X座標
    
DRAW_MAP_X_LOOP:
    cmp ebx, MAP_WIDTH
    jge NEXT_MAP_Y
    
    ; 計算當前格子的資料索引
    push eax
    push ebx
    mov ecx, MAP_WIDTH
    mul ecx             ; EAX = Y * MAP_WIDTH
    add eax, ebx        ; EAX = Y * MAP_WIDTH + X
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi]  ; 取得元件類型
    pop ebx
    pop eax
    
    ; 如果不是空地，繪製元件
    cmp cl, COMPONENT_EMPTY
    je NEXT_MAP_X
    
    ; 繪製元件
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

;------------------------------------------------
; 繪製單個元件
; 輸入: EAX=Y座標, EBX=X座標, CL=元件類型
;------------------------------------------------
drawComponent PROC USES eax ebx ecx edx esi edi
    ; 計算螢幕座標
    push ecx            ; 保存元件類型
    call calculateScreenPosition
    pop ecx             ; 恢復元件類型
    
    ; 計算元件字元的起始位置
    movzx eax, cl       ; 元件類型
    mov edx, 15         ; 每個元件15個字元 (5x3)
    mul edx
    mov esi, OFFSET componentChars
    add esi, eax        ; ESI指向元件字元
    
    ; 繪製3行
    mov ecx, blockHeight
DRAW_COMPONENT_Y_LOOP:
    push ecx
    
    ; 輸出一行字元到螢幕
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, blockWidth, outerBoxPos, ADDR count
    
    ; 設定白底黑字屬性
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, outerBoxPos, ADDR cellsWritten
    
    ; 移動到下一行字元位置
    add esi, blockWidth
    inc outerBoxPos.Y
    pop ecx
    loop DRAW_COMPONENT_Y_LOOP
    ret
drawComponent ENDP

;------------------------------------------------
; 計算螢幕座標 (根據 EAX=Y, EBX=X)
;------------------------------------------------
calculateScreenPosition PROC
    push ebx
    push eax
    
    ; 計算螢幕X座標
    mov eax, ebx
    mov ecx, blockWidth
    mul ecx
    add eax, 7          ; 加上初始偏移
    mov outerBoxPos.X, ax
    
    ; 計算螢幕Y座標
    pop eax
    push eax
    mov ecx, blockHeight
    mul ecx
    add eax, 4          ; 加上初始偏移
    mov outerBoxPos.Y, ax
    
    pop eax
    pop ebx
    ret
calculateScreenPosition ENDP

;------------------------------------------------
; 檢查游標位置是否有地圖元件或塔
; 輸出: EAX = 1 有元件或塔, 0 空地
;------------------------------------------------
hasComponentOrTowerAtCursor PROC USES ebx ecx esi
    ; 先檢查是否有塔
    call checkTowerAtCurrentPosition
    cmp eax, 1
    je HAS_SOMETHING
    
    ; 檢查是否有地圖元件
    call canPlaceTowerAtCurrentPos
    cmp eax, 0          ; 如果不能放塔，表示有元件
    je HAS_SOMETHING
    
    ; 空地
    mov eax, 0
    ret
    
HAS_SOMETHING:
    mov eax, 1
    ret
hasComponentOrTowerAtCursor ENDP

;------------------------------------------------
; 繪製a鍵
;------------------------------------------------
drawATower PROC USES esi
    call getTowerColorAttributes
    
    ; 頂：█████
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0DBh    ; █
    mov tempBuffer+1, 0DBh  ; █
    mov tempBuffer+2, 0DBh  ; █
    mov tempBuffer+3, 0DBh  ; █
    mov tempBuffer+4, 0DBh  ; █
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 中：█ ● █
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0DBh    ; █
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 07h   ; ●
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 0DBh  ; █
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 底：█████
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0DBh    ; █
    mov tempBuffer+1, 0DBh  ; █
    mov tempBuffer+2, 0DBh  ; █
    mov tempBuffer+3, 0DBh  ; █
    mov tempBuffer+4, 0DBh  ; █
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawATower ENDP

;------------------------------------------------
; 繪製b鍵
;------------------------------------------------
drawBTower PROC USES esi
    call getTowerColorAttributes
    
    ; 頂：▲▲▲▲▲
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Eh     ; ▲
    mov tempBuffer+1, 1Eh   ; ▲
    mov tempBuffer+2, 1Eh   ; ▲
    mov tempBuffer+3, 1Eh   ; ▲
    mov tempBuffer+4, 1Eh   ; ▲
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 中：║ ♦ ║
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0BAh    ; ║
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 04h   ; ♦
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 0BAh  ; ║
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 底：═════
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0CDh    ; ═
    mov tempBuffer+1, 0CDh  ; ═
    mov tempBuffer+2, 0CDh  ; ═
    mov tempBuffer+3, 0CDh  ; ═
    mov tempBuffer+4, 0CDh  ; ═
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawBTower ENDP

;------------------------------------------------
; 繪製c鍵
;------------------------------------------------
drawCTower PROC USES esi
    call getTowerColorAttributes
    
    ; 頂： ╔═╗ 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, ' '
    mov tempBuffer+1, 0C9h  ; ╔
    mov tempBuffer+2, 0CDh  ; ═
    mov tempBuffer+3, 0BBh  ; ╗
    mov tempBuffer+4, ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 中：►♠ ◄
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 10h     ; ►
    mov tempBuffer+1, 06h   ; ♠
    mov tempBuffer+2, ' '
    mov tempBuffer+3, 06h   ; ♠
    mov tempBuffer+4, 11h   ; ◄
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 底： ╚═╝ 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, ' '
    mov tempBuffer+1, 0C8h  ; ╚
    mov tempBuffer+2, 0CDh  ; ═
    mov tempBuffer+3, 0BCh  ; ╝
    mov tempBuffer+4, ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawCTower ENDP

;------------------------------------------------
; 繪製d鍵
;------------------------------------------------
drawDTower PROC USES esi
    call getTowerColorAttributes
    
    ; 頂：※※※※※
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 15h     ; ※
    mov tempBuffer+1, 15h   ; ※
    mov tempBuffer+2, 15h   ; ※
    mov tempBuffer+3, 15h   ; ※
    mov tempBuffer+4, 15h   ; ※
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 中：~ ☼ ~
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 7Eh     ; ~
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 0Fh   ; ☼
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 7Eh   ; ~
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 底：∩∩∩∩∩
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0E9h    ; ∩
    mov tempBuffer+1, 0E9h  ; ∩
    mov tempBuffer+2, 0E9h  ; ∩
    mov tempBuffer+3, 0E9h  ; ∩
    mov tempBuffer+4, 0E9h  ; ∩
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawDTower ENDP

;------------------------------------------------
; 繪製e鍵
;------------------------------------------------
drawETower PROC USES esi
    call getTowerColorAttributes
    
    ; 頂：♫♪♫♪♫
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 0Eh     ; ♫
    mov tempBuffer+1, 0Dh   ; ♪
    mov tempBuffer+2, 0Eh   ; ♫
    mov tempBuffer+3, 0Dh   ; ♪
    mov tempBuffer+4, 0Eh   ; ♫
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 中：◄ ♥ ►
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 11h     ; ◄
    mov tempBuffer+1, ' '
    mov tempBuffer+2, 03h   ; ♥
    mov tempBuffer+3, ' '
    mov tempBuffer+4, 10h   ; ►
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y

    ; 底：▼▼▼▼▼
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Fh     ; ▼
    mov tempBuffer+1, 1Fh   ; ▼
    mov tempBuffer+2, 1Fh   ; ▼
    mov tempBuffer+3, 1Fh   ; ▼
    mov tempBuffer+4, 1Fh   ; ▼
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    ret
drawETower ENDP

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

    ; 初始化地圖系統
    call initMapSystem
    
    call initBlock
    call moveBlock
    call Clrscr
    exit
main ENDP

END main
