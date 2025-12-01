; =================================================================================
; monster2.asm - 簡化版怪物系統
; =================================================================================
; 設計原則：
; 1. 三種怪物 (A, B, C) - 速度和血量不同
; 2. 五個回合，每回合固定生成特定怪物
; 3. 怪物沿著地圖路徑移動到終點後消失
; 4. 使用簡單的路徑追蹤演算法
; =================================================================================

; ------------------------------------------------
; 函式原型宣告
; ------------------------------------------------
createMonsters PROTO :DWORD
drawMonsters PROTO
updateMonstersPositions PROTO
removeMonsters PROTO

; ------------------------------------------------
; 常數定義
; ------------------------------------------------
MONSTER_WIDTH = 5
MONSTER_HEIGHT = 3
MAX_MONSTERS = 10           ; 單回合最多 10 隻怪物

; 怪物類型
MONSTER_TYPE_A = 1          ; 普通怪 - 慢速
MONSTER_TYPE_B = 2          ; 快速怪
MONSTER_TYPE_C = 3          ; 坦克怪 - 高血量

.data

; ------------------------------------------------
; 怪物結構定義 (16 bytes 對齊以避免記憶體問題)
; ------------------------------------------------
Monster STRUCT
    isActive    BYTE 0      ; 是否存活 (0=死亡/不存在, 1=存活)
    monType     BYTE 0      ; 怪物類型 (1=A, 2=B, 3=C)
    hp          WORD 0      ; 當前血量
    speed       BYTE 0      ; 移動速度 (每次移動多少像素)
    direction   BYTE 0      ; 當前移動方向 (0=上, 1=下, 2=左, 3=右)
    xPos        WORD 0      ; X 座標 (螢幕座標)
    yPos        WORD 0      ; Y 座標 (螢幕座標)
    gridX       WORD 0      ; Grid X 座標
    gridY       WORD 0      ; Grid Y 座標
    moveCounter BYTE 0      ; 移動計數器
    padding     BYTE 0      ; 對齊用
Monster ENDS

; 怪物陣列
monsters Monster MAX_MONSTERS DUP(<>)

; ------------------------------------------------
; 怪物屬性表 (每種怪物的初始屬性)
; ------------------------------------------------
; 格式: HP(WORD), Speed(BYTE), 3個填充BYTE
monsterStats LABEL BYTE
    ; 怪物 A
    WORD 20         ; HP
    BYTE 1          ; Speed
    BYTE 0, 0, 0    ; Padding
    ; 怪物 B  
    WORD 15
    BYTE 2
    BYTE 0, 0, 0
    ; 怪物 C
    WORD 40
    BYTE 1
    BYTE 0, 0, 0

; ------------------------------------------------
; 怪物圖像 (5x3 = 15 bytes per monster)
; ------------------------------------------------
monsterGraphics LABEL BYTE
    ; 怪物 A - 普通
    BYTE ' ', 'A', 'A', 'A', ' '
    BYTE '(', '-', 'o', '-', ')'
    BYTE ' ', '/', ' ', '\', ' '
    
    ; 怪物 B - 快速
    BYTE ' ', 'B', 'B', 'B', ' '
    BYTE '<', '=', '*', '=', '>'
    BYTE ' ', '>', ' ', '<', ' '
    
    ; 怪物 C - 坦克
    BYTE ' ', 'C', 'C', 'C', ' '
    BYTE '[', '=', '#', '=', ']'
    BYTE ' ', '|', ' ', '|', ' '

; ------------------------------------------------
; 回合配置 - 每回合生成哪些怪物
; ------------------------------------------------
roundConfig LABEL BYTE
    ; Round 1: 3隻 A
    BYTE 3
    BYTE MONSTER_TYPE_A, MONSTER_TYPE_A, MONSTER_TYPE_A
    BYTE 0, 0, 0, 0  ; 填充到 8 bytes
    
    ; Round 2: 2隻 A, 1隻 B
    BYTE 3
    BYTE MONSTER_TYPE_A, MONSTER_TYPE_A, MONSTER_TYPE_B
    BYTE 0, 0, 0, 0
    
    ; Round 3: 2隻 B, 1隻 C
    BYTE 3
    BYTE MONSTER_TYPE_B, MONSTER_TYPE_B, MONSTER_TYPE_C
    BYTE 0, 0, 0, 0
    
    ; Round 4: 3隻 B, 1隻 C
    BYTE 4
    BYTE MONSTER_TYPE_B, MONSTER_TYPE_B, MONSTER_TYPE_B, MONSTER_TYPE_C
    BYTE 0, 0, 0
    
    ; Round 5: 2隻 C, 2隻 B
    BYTE 4
    BYTE MONSTER_TYPE_C, MONSTER_TYPE_C, MONSTER_TYPE_B, MONSTER_TYPE_B
    BYTE 0, 0, 0

; ------------------------------------------------
; 移動方向常數
; ------------------------------------------------
DIR_UP      EQU 0
DIR_DOWN    EQU 1
DIR_LEFT    EQU 2
DIR_RIGHT   EQU 3

; ------------------------------------------------
; 繪圖用暫存變數
; ------------------------------------------------
drawPos         COORD <>
drawBuffer      BYTE MONSTER_WIDTH DUP(?)
drawCount       DWORD 0
monsterColor    WORD MONSTER_WIDTH DUP(0Ch)  ; 紅色怪物

; 背景恢復用緩衝區
bgBuffer        BYTE 15 DUP(?)               ; 5x3 背景字元緩衝
bgAttrBuffer    WORD 15 DUP(?)               ; 5x3 背景屬性緩衝

.code

; =================================================================================
; createMonsters - 根據回合數創建怪物
; 參數: roundNum (DWORD) - 回合編號 (1-5)
; =================================================================================
createMonsters PROC USES eax ebx ecx edx esi edi, roundNum:DWORD
    
    ; 清空所有怪物
    mov ecx, MAX_MONSTERS
    lea edi, monsters
    xor eax, eax
ClearLoop:
    mov (Monster PTR [edi]).isActive, al
    add edi, SIZEOF Monster
    loop ClearLoop
    
    ; 取得回合配置
    mov eax, roundNum
    cmp eax, 1
    jl CreateDone
    cmp eax, 5
    jg CreateDone
    
    ; 計算配置位址: (roundNum - 1) * 8
    dec eax
    mov ebx, 8
    mul ebx
    lea esi, roundConfig[eax]
    
    ; 讀取怪物數量
    movzx ecx, BYTE PTR [esi]
    inc esi
    
    ; 創建怪物
    xor ebx, ebx            ; 怪物陣列索引
CreateLoop:
    cmp ebx, MAX_MONSTERS
    jge CreateDone
    cmp ecx, 0
    jle CreateDone
    
    ; 取得怪物類型
    movzx eax, BYTE PTR [esi]
    cmp eax, 0
    je CreateDone
    
    ; 計算怪物結構位址
    push eax
    mov eax, SIZEOF Monster
    push edx
    mul ebx
    pop edx
    lea edi, monsters[eax]
    pop eax
    
    ; 設定怪物屬性
    mov (Monster PTR [edi]).isActive, 1
    mov (Monster PTR [edi]).monType, al
    mov (Monster PTR [edi]).moveCounter, 0
    mov (Monster PTR [edi]).direction, DIR_DOWN  ; 初始向下
    
    ; 設定初始 Grid 座標 (起點: 列1,行1)
    mov (Monster PTR [edi]).gridX, 1  ; 列(column)
    mov (Monster PTR [edi]).gridY, 1  ; 行(row)
    
    ; 從屬性表讀取 HP 和 Speed
    push esi
    dec eax
    mov esi, 6              ; 每個entry 6 bytes
    push edx
    mul esi
    pop edx
    lea esi, monsterStats[eax]
    
    mov ax, WORD PTR [esi]
    mov (Monster PTR [edi]).hp, ax
    mov al, BYTE PTR [esi+2]
    mov (Monster PTR [edi]).speed, al
    pop esi
    
    ; 計算初始螢幕座標
    ; Screen X = 7 + gridX * 5
    mov ax, (Monster PTR [edi]).gridX
    mov cx, 5
    push edx
    mul cx
    pop edx
    add ax, 7
    mov (Monster PTR [edi]).xPos, ax
    
    ; Screen Y = 4 + gridY * 3
    mov ax, (Monster PTR [edi]).gridY
    mov cx, 3
    push edx
    mul cx
    pop edx
    add ax, 4
    mov (Monster PTR [edi]).yPos, ax
    
    ; 下一隻怪物
    inc esi
    inc ebx
    dec ecx
    jmp CreateLoop
    
CreateDone:
    ret
createMonsters ENDP

; =================================================================================
; drawMonsters - 繪製所有存活的怪物
; (注意：背景恢復已在 updateMonstersPositions 中處理)
; =================================================================================
drawMonsters PROC USES eax ebx ecx edx esi edi
    
    ; 繪製所有怪物
    xor ebx, ebx            ; 怪物索引
DrawLoop:
    cmp ebx, MAX_MONSTERS
    jge DrawDone
    
    ; 計算怪物結構位址
    mov eax, SIZEOF Monster
    push edx
    mul ebx
    pop edx
    lea edi, monsters[eax]
    
    ; 檢查是否存活
    cmp (Monster PTR [edi]).isActive, 0
    je NextMonster
    
    ; 取得怪物類型和位置
    movzx eax, (Monster PTR [edi]).monType
    cmp eax, 0
    je NextMonster
    cmp eax, 3
    jg NextMonster
    
    ; 設定繪製座標
    mov ax, (Monster PTR [edi]).xPos
    mov drawPos.x, ax
    mov ax, (Monster PTR [edi]).yPos
    mov drawPos.y, ax
    
    ; 取得圖像位址
    movzx eax, (Monster PTR [edi]).monType
    dec eax
    mov ecx, 15
    push edx
    mul ecx
    pop edx
    lea esi, monsterGraphics[eax]
    
    ; 繪製 3 行
    mov ecx, MONSTER_HEIGHT
DrawRowLoop:
    push ecx
    
    ; 複製一行到緩衝區
    push edi
    push esi
    lea edi, drawBuffer
    mov ecx, MONSTER_WIDTH
    cld
    rep movsb
    pop esi
    pop edi
    
    ; 寫入顏色
    INVOKE WriteConsoleOutputAttribute, outputHandle, 
        ADDR monsterColor, MONSTER_WIDTH, drawPos, ADDR drawCount
    
    ; 寫入字元
    INVOKE WriteConsoleOutputCharacter, outputHandle,
        ADDR drawBuffer, MONSTER_WIDTH, drawPos, ADDR drawCount
    
    ; 下一行
    add esi, MONSTER_WIDTH
    inc drawPos.y
    
    pop ecx
    loop DrawRowLoop
    
NextMonster:
    inc ebx
    jmp DrawLoop
    
DrawDone:
    ret
drawMonsters ENDP

; =================================================================================
; restoreAllMonsterBackgrounds - 恢復所有怪物位置的地圖背景
; =================================================================================
restoreAllMonsterBackgrounds PROC USES eax ebx ecx edx esi edi
    
    xor ebx, ebx
RestoreLoop:
    cmp ebx, MAX_MONSTERS
    jge RestoreDone
    
    ; 計算怪物結構位址
    mov eax, SIZEOF Monster
    push edx
    mul ebx
    pop edx
    lea edi, monsters[eax]
    
    ; 只恢復存活怪物的位置
    cmp (Monster PTR [edi]).isActive, 0
    je NextRestore
    
    ; 恢復該怪物位置的地圖
    push ebx
    movzx eax, (Monster PTR [edi]).gridX
    movzx ebx, (Monster PTR [edi]).gridY
    call drawMapAtGrid
    pop ebx
    
NextRestore:
    inc ebx
    jmp RestoreLoop
    
RestoreDone:
    ret
restoreAllMonsterBackgrounds ENDP

; =================================================================================
; drawMapAtGrid - 在指定 Grid 座標重繪地圖元件
; 輸入: EAX = gridX, EBX = gridY
; =================================================================================
drawMapAtGrid PROC USES eax ebx ecx edx esi edi
    
    ; 保存 gridX 和 gridY
    push eax            ; gridX
    push ebx            ; gridY
    
    ; 計算 mapData 索引: index = gridY * MAP_WIDTH + gridX
    mov eax, ebx        ; gridY
    mov ecx, MAP_WIDTH
    push edx
    mul ecx
    pop edx
    pop ebx             ; 取回 gridY (不需要了)
    pop ecx             ; 取回 gridX
    add eax, ecx        ; EAX = index
    
    ; 讀取地圖元件類型
    lea esi, mapData
    add esi, eax
    movzx eax, BYTE PTR [esi]
    
    ; 取得元件圖像位址 (每個元件 15 bytes)
    push ecx            ; 保存 gridX
    push ebx            ; 保存 gridY
    mov ecx, 15
    push edx
    mul ecx
    pop edx
    lea esi, componentChars[eax]
    
    ; 計算螢幕座標
    pop ebx             ; gridY
    pop eax             ; gridX
    
    ; Screen X = 7 + gridX * 5
    push ebx
    mov ebx, 5
    push edx
    mul ebx
    pop edx
    add eax, 7
    mov drawPos.x, ax
    pop ebx
    
    ; Screen Y = 4 + gridY * 3
    mov eax, ebx        ; gridY
    mov ecx, 3
    push edx
    mul ecx
    pop edx
    add eax, 4
    mov drawPos.y, ax
    
    ; 繪製 3 行
    mov ecx, MONSTER_HEIGHT
DrawMapRowLoop:
    push ecx
    
    ; 複製一行
    push esi
    lea edi, drawBuffer
    mov ecx, MONSTER_WIDTH
    cld
    rep movsb
    pop esi
    
    ; 寫入顏色 (白底黑字)
    INVOKE WriteConsoleOutputAttribute, outputHandle,
        ADDR blockAttributes, MONSTER_WIDTH, drawPos, ADDR drawCount
    
    ; 寫入字元
    INVOKE WriteConsoleOutputCharacter, outputHandle,
        ADDR drawBuffer, MONSTER_WIDTH, drawPos, ADDR drawCount
    
    ; 下一行
    add esi, MONSTER_WIDTH
    inc drawPos.y
    
    pop ecx
    loop DrawMapRowLoop
    
    ret
drawMapAtGrid ENDP

; =================================================================================
; updateMonstersPositions - 根據地圖元件更新怪物位置
; =================================================================================
updateMonstersPositions PROC USES eax ebx ecx edx esi edi
    
    ; 首先恢復所有怪物當前位置的背景（在移動之前）
    call restoreAllMonsterBackgrounds
    
    xor ebx, ebx            ; 怪物索引
UpdateLoop:
    cmp ebx, MAX_MONSTERS
    jge UpdateDone
    
    ; 計算怪物結構位址
    mov eax, SIZEOF Monster
    push edx
    mul ebx
    pop edx
    lea edi, monsters[eax]
    
    ; 檢查是否存活
    cmp (Monster PTR [edi]).isActive, 0
    je NextUpdate
    
    ; 移動計數器 +1
    inc (Monster PTR [edi]).moveCounter
    movzx eax, (Monster PTR [edi]).speed
    cmp (Monster PTR [edi]).moveCounter, al
    jl NextUpdate
    
    ; 重置計數器
    mov (Monster PTR [edi]).moveCounter, 0
    
    ; 讀取當前位置 (gridX=列col, gridY=行row)
    movzx edx, (Monster PTR [edi]).gridX  ; 列(col)
    movzx ecx, (Monster PTR [edi]).gridY  ; 行(row)
    
    ; 計算 mapData 索引 = row * MAP_WIDTH + col
    mov eax, ecx        ; 行
    push edx
    mov edx, MAP_WIDTH  ; 16
    mul edx             ; eax = row * 16
    pop edx
    add eax, edx        ; EAX = row*16 + col
    
    lea esi, mapData
    movzx eax, BYTE PTR [esi+eax]
    
    ; 檢查是否到達終點
    cmp eax, COMPONENT_EXIT
    je ReachEnd
    
    ; 根據當前位置決定方向
    ; 路徑: (1,1)下→(1,6)右→(3,6)上→(3,1)右→(11,1)下→(11,3)左→(6,3)下→(6,6)右→(13,6)上→(13,1)終點
    ; gridX=col, gridY=row
    
    movzx eax, (Monster PTR [edi]).gridX  ; 列col
    movzx ecx, (Monster PTR [edi]).gridY  ; 行row
    
    ; 關鍵轉角點判斷
    cmp ecx, 1          ; 行1
    je Row1Check
    cmp ecx, 3          ; 行3  
    je Row3Check
    cmp ecx, 6          ; 行6
    je Row6Check
    
    ; 其他位置繼續當前方向
    jmp ContinueDirection

Row1Check:
    ; 行1: (1,1)往下, (3,1)往右, (11,1)往下, (13,1)終點
    cmp eax, 1          ; (1,1)
    je MoveDown
    cmp eax, 3          ; (3,1) 轉右
    je TurnRight
    cmp eax, 11         ; (11,1) 轉下
    je TurnDown
    cmp eax, 13         ; (13,1) 終點
    je ReachEnd
    ; (3,1)→(11,1) 繼續往右
    jmp MoveRight

Row3Check:
    ; 行3: (1,3)往下, (3,3)往上, (6,3)往下, (11,3)往左, (13,3)往上
    cmp eax, 1          ; (1,3)
    je MoveDown
    cmp eax, 3          ; (3,3) 轉上
    je TurnUp
    cmp eax, 6          ; (6,3) 轉下
    je TurnDown
    cmp eax, 11         ; (11,3) 轉左
    je TurnLeft
    cmp eax, 13         ; (13,3)
    je MoveUp
    ; (11,3)→(6,3) 往左
    cmp eax, 11
    jg MoveUp           ; >11 往上
    jmp MoveLeft        ; 6-11之間往左

Row6Check:
    ; 行6: (1,6)往右, (3,6)往上或往右取決於來向, (6,6)往右, (13,6)往上
    cmp eax, 1          ; (1,6) 轉右
    je TurnRight
    cmp eax, 3          ; (3,6)
    je CheckCol3Row6
    cmp eax, 13         ; (13,6) 轉上
    je TurnUp
    ; (3,6)→(13,6) 往右
    jmp MoveRight

CheckCol3Row6:
    ; (3,6): 從下來(DIR_DOWN)→轉右, 從左來(DIR_RIGHT)→轉上
    mov al, (Monster PTR [edi]).direction
    cmp al, DIR_DOWN
    je TurnRight
    cmp al, DIR_RIGHT
    je TurnUp
    jmp TurnUp

ContinueDirection:
    ; 其他位置繼續當前方向
    mov al, (Monster PTR [edi]).direction
    cmp al, DIR_UP
    je MoveUp
    cmp al, DIR_DOWN
    je MoveDown
    cmp al, DIR_LEFT
    je MoveLeft
    jmp MoveRight

TurnUp:
    mov (Monster PTR [edi]).direction, DIR_UP
    jmp MoveUp
TurnDown:
    mov (Monster PTR [edi]).direction, DIR_DOWN
    jmp MoveDown
TurnLeft:
    mov (Monster PTR [edi]).direction, DIR_LEFT
    jmp MoveLeft
TurnRight:
    mov (Monster PTR [edi]).direction, DIR_RIGHT
    jmp MoveRight

MoveUp:
    ; Y--
    mov ax, (Monster PTR [edi]).gridY
    dec ax
    cmp ax, 0
    jl ReachEnd
    mov (Monster PTR [edi]).gridY, ax
    jmp UpdateScreenPos

MoveDown:
    ; Y++
    mov ax, (Monster PTR [edi]).gridY
    inc ax
    cmp ax, MAP_HEIGHT
    jge ReachEnd
    mov (Monster PTR [edi]).gridY, ax
    jmp UpdateScreenPos

MoveLeft:
    ; X--
    mov ax, (Monster PTR [edi]).gridX
    dec ax
    cmp ax, 0
    jl ReachEnd
    mov (Monster PTR [edi]).gridX, ax
    jmp UpdateScreenPos

MoveRight:
    ; X++
    mov ax, (Monster PTR [edi]).gridX
    inc ax
    cmp ax, MAP_WIDTH
    jge ReachEnd
    mov (Monster PTR [edi]).gridX, ax
    jmp UpdateScreenPos

UpdateScreenPos:
    ; 更新螢幕座標
    ; Screen X = 7 + gridX * 5
    mov ax, (Monster PTR [edi]).gridX
    mov cx, 5
    push edx
    mul cx
    pop edx
    add ax, 7
    mov (Monster PTR [edi]).xPos, ax
    
    ; Screen Y = 4 + gridY * 3
    mov ax, (Monster PTR [edi]).gridY
    mov cx, 3
    push edx
    mul cx
    pop edx
    add ax, 4
    mov (Monster PTR [edi]).yPos, ax
    jmp NextUpdate

ReachEnd:
    ; 到達終點或邊界，移除怪物
    mov (Monster PTR [edi]).isActive, 0
    
NextUpdate:
    inc ebx
    jmp UpdateLoop
    
UpdateDone:
    ret
updateMonstersPositions ENDP

; =================================================================================
; removeMonsters - 清除死亡的怪物 (HP <= 0)
; =================================================================================
removeMonsters PROC USES eax ebx edi
    
    xor ebx, ebx
RemoveLoop:
    cmp ebx, MAX_MONSTERS
    jge RemoveDone
    
    ; 計算怪物結構位址
    mov eax, SIZEOF Monster
    push edx
    mul ebx
    pop edx
    lea edi, monsters[eax]
    
    ; 檢查是否存活
    cmp (Monster PTR [edi]).isActive, 0
    je NextRemove
    
    ; 檢查 HP
    cmp (Monster PTR [edi]).hp, 0
    jg NextRemove
    
    ; 血量歸零，移除
    mov (Monster PTR [edi]).isActive, 0
    
NextRemove:
    inc ebx
    jmp RemoveLoop
    
RemoveDone:
    ret
removeMonsters ENDP
