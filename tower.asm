; =================================================================================
; tower.asm
; 負責：防禦塔繪製、建造、拆除、以及子彈系統
; [修正] 全面改用 constants.inc 定義的 MAP_WIDTH/MAP_HEIGHT，解決邊界與索引錯誤
; =================================================================================

addTowerWithType PROTO      ; 在當前位置新增防禦塔
deleteTower PROTO           ; 刪除當前位置的塔
checkTowerAtCurrentPosition PROTO ; 檢查當前位置是否已經有塔
isTowerAtPositionSimple PROTO ; 輔助函式：檢查特定索引的塔是否在游標位置
removeTowerAtIndexSimple PROTO; 輔助函式：移除陣列中特定索引的塔
canPlaceTowerAtCurrentPos PROTO ; 檢查當前地形是否可以蓋塔 (不能蓋在路徑上)
drawATower PROTO            ; 繪製 A 型塔 (Cannon)
drawBTower PROTO            ; 繪製 B 型塔 (Sniper)
drawCTower PROTO            ; 繪製 C 型塔 (Ice)
drawDTower PROTO            ; 繪製 D 型塔 (Mage)
drawETower PROTO            ; 繪製 E 型塔 (Missile)
drawAllTowers PROTO         ; 繪製場上所有的塔
towerCombatSystem PROTO
updateBullets PROTO
clearAllBullets PROTO
_restoreBulletBG PROTO

.code

; =================================================================================
; 建造防禦塔
; =================================================================================
addTowerWithType PROC USES eax ecx esi
    ; 1. 檢查是否重疊
    call checkTowerAtCurrentPosition
    cmp eax, 1
    je NO_ADD_TYPE 
    
    ; 2. 檢查地形限制
    call canPlaceTowerAtCurrentPos
    cmp eax, 0
    je NO_ADD_TYPE 
    
    ; 3. 檢查塔數上限
    mov eax, towerCount
    cmp eax, towerMax
    jge NO_ADD_TYPE
    
    ; 4. 檢查金錢
    mov eax, 0
    mov al, bl              ; bl = tower type (1-5)
    dec eax                 
    mov esi, OFFSET towerCosts
    imul eax, 4             
    add esi, eax
    mov eax, DWORD PTR [esi] 
    cmp money, eax          
    jl NO_ADD_TYPE          
    
    ; 5. 扣除金錢與寫入
    sub money, eax
    
    mov ecx, towerCount     
    
    mov esi, OFFSET towersPosX
    mov eax, ecx            
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

; =================================================================================
; 刪除塔
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
    je DELETE_FOUND_TOWER 
    inc ecx
    jmp CHECK_TOWER_LOOP
DELETE_FOUND_TOWER:
    ; 返還金錢
    mov esi, OFFSET towersType
    add esi, ecx                
    mov al, BYTE PTR [esi]      
    mov ebx, 0
    mov bl, al
    dec ebx                     
    mov esi, OFFSET towerCosts
    imul ebx, 4                 
    add esi, ebx
    mov eax, DWORD PTR [esi]    
    shr eax, 1                  
    add money, eax              
    
    call removeTowerAtIndexSimple
DELETE_DONE:
    ret
deleteTower ENDP

; 輔助：檢查位置是否有塔 (內部呼叫)
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

; 輔助：檢查特定位置 (內部呼叫)
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

; 輔助：移除陣列元素 (內部呼叫)
removeTowerAtIndexSimple PROC USES eax ebx edx esi edi
    mov eax, ecx        
    mov ebx, towerCount
    dec ebx             
    cmp eax, ebx
    jge JUST_DECREASE_COUNT_SIMPLE 
    
    ; Shift X
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

; =================================================================================
; 輔助：檢查地形 [關鍵修正區]
; =================================================================================
canPlaceTowerAtCurrentPos PROC USES ebx ecx esi
    movzx eax, blockPos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax    ; ebx = Grid X
    
    movzx eax, blockPos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx         ; eax = Grid Y
    
    ; [修正] 使用常數 MAP_WIDTH (16) 與 MAP_HEIGHT (8)
    cmp ebx, MAP_WIDTH
    jge CANNOT_PLACE
    cmp eax, MAP_HEIGHT
    jge CANNOT_PLACE
    
    ; [修正] 計算索引必須使用 MAP_WIDTH
    mov ecx, MAP_WIDTH 
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov al, BYTE PTR [esi]
    
    cmp al, COMPONENT_EMPTY ; 0
    je CAN_PLACE 
CANNOT_PLACE:
    mov eax, 0
    ret
CAN_PLACE:
    mov eax, 1
    ret
canPlaceTowerAtCurrentPos ENDP

; =================================================================================
; 繪圖相關函式
; =================================================================================
drawAllTowers PROC USES ecx
    mov ecx, 0
L_DRAW:
    cmp ecx, towerCount
    jge DONE_DRAW
    push ecx
    call drawTower 
    inc ecx
    jmp L_DRAW
DONE_DRAW:
    ret
drawAllTowers ENDP

drawTower PROC USES eax ebx ecx edi esi
    mov edi, [esp+24] ; Get Index from Stack
    push DWORD PTR outerBoxPos

    mov esi, OFFSET towersPosX
    mov ebx, edi
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.X, ax

    mov esi, OFFSET towersPosY
    mov ebx, edi
    imul ebx, 2
    add esi, ebx
    mov ax, WORD PTR [esi]
    mov outerBoxPos.Y, ax

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
    ret 4 
drawTower ENDP

drawATower PROC USES esi
    mov esi, OFFSET attrTowerA 
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 2Fh   ; '/'
    mov tempBuffer+2, 0CFh  ; '╧' 
    mov tempBuffer+3, 5Ch   ; '\'
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 20h     ; ' '
    mov tempBuffer+1, 7Ch   ; '| '
    mov tempBuffer+2, 0DBh  ; '█' 
    mov tempBuffer+3, 7Ch   ; '|'
    mov tempBuffer+4, 20h   ; ' '
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR tempBuffer, blockWidth, outerBoxPos, ADDR count
    inc outerBoxPos.Y
    
    INVOKE WriteConsoleOutputAttribute, outputHandle, esi, blockWidth, outerBoxPos, ADDR cellsWritten
    mov tempBuffer, 1Eh      ; '▲'
    mov tempBuffer+1, 23h    ; '#'
    mov tempBuffer+2, 23h    ; '#'
    mov tempBuffer+3, 23h    ; '#'
    mov tempBuffer+4, 1Eh    ; '▲'
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

; =================================================================================
; 戰鬥與子彈系統
; =================================================================================

towerCombatSystem PROC USES eax ebx ecx edx esi edi
    LOCAL tIndex:DWORD
    LOCAL mIndex:DWORD
    LOCAL tX:WORD, tY:WORD, tType:BYTE
    LOCAL range:DWORD, damage:WORD
    LOCAL distSq:DWORD
    
    mov tIndex, 0

TOWER_LOOP:
    mov eax, tIndex
    cmp eax, towerCount
    jge ALL_TOWERS_DONE

    ; 1. 檢查冷卻
    lea esi, towersCD
    add esi, eax
    mov al, byte ptr [esi]
    cmp al, 0
    jg CD_DECREMENT
    jmp READY_TO_FIRE

CD_DECREMENT:
    dec byte ptr [esi]
    jmp NEXT_TOWER

READY_TO_FIRE:
    ; 2. 取得塔資訊
    mov esi, OFFSET towersPosX
    mov eax, tIndex
    imul eax, 2
    mov bx, word ptr [esi+eax]
    mov tX, bx                  
    
    mov esi, OFFSET towersPosY
    mov eax, tIndex
    imul eax, 2
    mov bx, word ptr [esi+eax]
    mov tY, bx                  
    
    mov esi, OFFSET towersType
    mov eax, tIndex
    add esi, eax
    mov bl, byte ptr [esi]
    mov tType, bl               
    
    ; 3. 取得能力值
    movzx eax, bl
    dec eax 
    mov esi, OFFSET towerRangeSq
    mov edx, DWORD PTR [esi + eax*4]
    mov range, edx
    mov esi, OFFSET towerDamage
    mov dx, WORD PTR [esi + eax*2]
    mov damage, dx

    ; 4. 搜尋目標
    mov mIndex, 0
MONSTER_LOOP:
    cmp mIndex, 10 
    jge NEXT_TOWER

    ; 存取 roundMonsters (24 bytes per struct)
    mov eax, SIZE Monster_status
    mul mIndex
    lea edi, roundMonsters[eax]

    ; 檢查存活 (HP > 0)
    cmp WORD PTR [edi], 0 
    jle NEXT_MONSTER
    
    ; 檢查已生成 (alrearyDraw == 1)
    cmp BYTE PTR [edi+12], 1 
    jne NEXT_MONSTER

    ; 5. 計算距離
    movzx eax, WORD PTR [edi+4] ; pos.X
    movzx ebx, tX
    sub eax, ebx
    imul eax, eax
    mov distSq, eax
    
    movzx eax, WORD PTR [edi+6] ; pos.Y
    movzx ebx, tY
    sub eax, ebx
    imul eax, eax
    add distSq, eax
    
    mov eax, distSq
    cmp eax, range
    jg NEXT_MONSTER 

    ; 攻擊判定成功
    push ecx        
    mov ecx, 0      

FIND_EMPTY_BULLET:
    cmp ecx, MAX_BULLETS
    jge SPAWN_DONE  

    mov eax, SIZE Bullet
    mul ecx
    lea esi, bulletList[eax]

    cmp (Bullet PTR [esi]).active, 0
    jne NEXT_BULLET_SLOT

    ; 初始化子彈
    mov (Bullet PTR [esi]).active, 1
    mov ax, tX
    mov (Bullet PTR [esi]).pos.X, ax
    mov ax, tY
    mov (Bullet PTR [esi]).pos.Y, ax
    
    mov (Bullet PTR [esi]).prev_pos.X, 0
    mov (Bullet PTR [esi]).prev_pos.Y, 0
    
    mov eax, mIndex
    mov (Bullet PTR [esi]).targetID, eax
    mov ax, damage
    mov (Bullet PTR [esi]).damage, ax
    mov al, tType
    mov (Bullet PTR [esi]).tType, al

    ; 設定冷卻
    movzx eax, tType
    dec eax 
    mov esi, OFFSET towerReload
    mov bl, byte ptr [esi+eax]
    mov esi, OFFSET towersCD
    add esi, tIndex
    mov byte ptr [esi], bl
    
    jmp SPAWN_DONE_AND_BREAK

NEXT_BULLET_SLOT:
    inc ecx
    jmp FIND_EMPTY_BULLET

SPAWN_DONE_AND_BREAK:
    pop ecx
    jmp NEXT_TOWER 

SPAWN_DONE:
    pop ecx 
NEXT_MONSTER:
    inc mIndex
    jmp MONSTER_LOOP
NEXT_TOWER:
    inc tIndex
    jmp TOWER_LOOP
ALL_TOWERS_DONE:
    ret
towerCombatSystem ENDP


updateBullets PROC USES eax ebx ecx edx esi edi
    mov ecx, 0  

BULLET_LOOP:
    cmp ecx, MAX_BULLETS
    jge BULLET_DONE

    mov eax, SIZE Bullet
    mul ecx
    lea esi, bulletList[eax]    

    cmp (Bullet PTR [esi]).active, 0
    je NEXT_BULLET

    ; 1. 清除舊軌跡
    mov ax, (Bullet PTR [esi]).prev_pos.X
    cmp ax, 0
    je SKIP_CLEAR
    mov xyPosition.X, ax
    mov ax, (Bullet PTR [esi]).prev_pos.Y
    mov xyPosition.Y, ax
    call _restoreBulletBG
SKIP_CLEAR:

    ; 2. 取得目標怪物
    mov edx, (Bullet PTR [esi]).targetID
    mov eax, SIZE Monster_status
    mul edx
    lea edi, roundMonsters[eax] 

    ; 檢查目標狀態 (HP=0, Drawn=12)
    cmp WORD PTR [edi], 0
    jle DEACTIVATE_BULLET
    cmp BYTE PTR [edi+12], 1
    jne DEACTIVATE_BULLET

    ; 3. 移動子彈
    ; X 軸
    mov ax, WORD PTR [edi+4] ; pos.X
    add ax, 2   
    cmp (Bullet PTR [esi]).pos.X, ax
    jl MOVE_RIGHT
    jg MOVE_LEFT
    jmp CHECK_Y_AXIS
MOVE_RIGHT:
    add (Bullet PTR [esi]).pos.X, 2 
    jmp CHECK_Y_AXIS
MOVE_LEFT:
    sub (Bullet PTR [esi]).pos.X, 2

CHECK_Y_AXIS:
    ; Y 軸
    mov ax, WORD PTR [edi+6] ; pos.Y
    add ax, 1   
    cmp (Bullet PTR [esi]).pos.Y, ax
    jl MOVE_DOWN
    jg MOVE_UP
    jmp CHECK_HIT
MOVE_DOWN:
    add (Bullet PTR [esi]).pos.Y, 1
    jmp CHECK_HIT
MOVE_UP:
    sub (Bullet PTR [esi]).pos.Y, 1

    ; 4. 命中判定
CHECK_HIT:
    mov ax, (Bullet PTR [esi]).pos.X
    sub ax, WORD PTR [edi+4] ; pos.X
    cwd             
    xor ax, dx
    sub ax, dx  
    cmp ax, 3 
    jg DRAW_BULLET  

    mov ax, (Bullet PTR [esi]).pos.Y
    sub ax, WORD PTR [edi+6] ; pos.Y
    cwd
    xor ax, dx
    sub ax, dx 
    cmp ax, 2 
    jg DRAW_BULLET  

    ; 擊中
    mov ax, WORD PTR [edi] ; HP
    sub ax, (Bullet PTR [esi]).damage
    mov WORD PTR [edi], ax
    jmp DEACTIVATE_BULLET

DRAW_BULLET:
    mov ax, (Bullet PTR [esi]).pos.X
    mov xyPosition.X, ax
    mov ax, (Bullet PTR [esi]).pos.Y
    mov xyPosition.Y, ax
    
    mov al, (Bullet PTR [esi]).tType
    mov bulletChar, '*'
    mov bulletAttr, 0ECh  
    
    cmp al, 3 
    jne CHECK_SNIPER
    mov bulletChar, 'o'
    mov bulletAttr, 0B0h  
    jmp DO_DRAW
CHECK_SNIPER:
    cmp al, 2 
    jne DO_DRAW
    mov bulletChar, '+'
    mov bulletAttr, 0CFh  

DO_DRAW:
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR bulletAttr, 1, xyPosition, ADDR bytesWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR bulletChar, 1, xyPosition, ADDR count
    
    ; 更新 prev_pos
    mov ax, (Bullet PTR [esi]).pos.X
    mov (Bullet PTR [esi]).prev_pos.X, ax
    mov ax, (Bullet PTR [esi]).pos.Y
    mov (Bullet PTR [esi]).prev_pos.Y, ax
    
    jmp NEXT_BULLET

DEACTIVATE_BULLET:
    mov (Bullet PTR [esi]).active, 0
    jmp NEXT_BULLET

NEXT_BULLET:
    inc ecx
    jmp BULLET_LOOP
BULLET_DONE:
    ret
updateBullets ENDP

clearAllBullets PROC USES eax ebx ecx
    mov ecx, 0
CLEAR_BULLET_LOOP:
    cmp ecx, MAX_BULLETS
    jge CLEAR_BULLET_RET

    mov eax, SIZE Bullet
    mul ecx
    lea esi, bulletList[eax]

    cmp (Bullet PTR [esi]).active, 1
    jne NEXT_CLEAR_BULLET

    mov ax, (Bullet PTR [esi]).prev_pos.X
    cmp ax, 0
    je DISABLE_BULLET_ONLY 
    
    mov xyPosition.X, ax
    mov ax, (Bullet PTR [esi]).prev_pos.Y
    mov xyPosition.Y, ax

    call _restoreBulletBG

DISABLE_BULLET_ONLY:
    mov (Bullet PTR [esi]).active, 0
NEXT_CLEAR_BULLET:
    inc ecx
    jmp CLEAR_BULLET_LOOP
CLEAR_BULLET_RET:
    ret
clearAllBullets ENDP

; =================================================================================
; 還原子彈背景 [關鍵修正區]
; =================================================================================
_restoreBulletBG PROC USES eax ebx ecx edx esi edi
    ; 1. 檢查該位置是否有塔
    mov ecx, 0
CHECK_TOWER_LOOP:
    cmp ecx, towerCount
    jge NO_TOWER_HERE 

    ; 範圍檢查 (塔寬5高3)
    mov esi, OFFSET towersPosX
    mov eax, ecx
    imul eax, 2             
    add esi, eax
    mov ax, WORD PTR [esi] 
    
    mov bx, xyPosition.X
    sub bx, ax              
    cmp bx, 0
    jl NEXT_TOWER_CHECK     
    cmp bx, 5               
    jge NEXT_TOWER_CHECK    

    mov esi, OFFSET towersPosY
    mov eax, ecx
    imul eax, 2
    add esi, eax
    mov ax, WORD PTR [esi] 
    
    mov bx, xyPosition.Y
    sub bx, ax
    cmp bx, 0
    jl NEXT_TOWER_CHECK    
    cmp bx, 3               
    jge NEXT_TOWER_CHECK    

    ; 找到塔 -> 重畫
    mov esi, OFFSET towersPosX
    mov eax, ecx
    imul eax, 2
    add esi, eax
    mov ax, WORD PTR [esi]
    mov outerBoxPos.X, ax   

    mov esi, OFFSET towersPosY
    mov eax, ecx
    imul eax, 2
    add esi, eax
    mov ax, WORD PTR [esi]
    mov outerBoxPos.Y, ax   
    
    ; 必須呼叫 drawTower 傳入 index
    push ecx
    call drawTower
    jmp RESTORE_FINISH

NEXT_TOWER_CHECK:
    inc ecx
    jmp CHECK_TOWER_LOOP

NO_TOWER_HERE:
    ; 2. 沒塔，畫地圖背景
    ; 計算 Grid X
    movzx eax, xyPosition.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx         
    mov ebx, eax        ; EBX = Grid X
    push edx            ; [Stack +1] 保存 X 軸像素偏移

    ; 計算 Grid Y
    movzx eax, xyPosition.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx             ; EAX = Grid Y, EDX = Pixel Offset Y
    
    ; [修正] 使用常數 MAP_WIDTH / MAP_HEIGHT
    cmp ebx, MAP_WIDTH 
    jge RESTORE_ABORT
    cmp eax, MAP_HEIGHT  
    jge RESTORE_ABORT
    
    push edx            ; [Stack +2] 保存 Y 軸像素偏移

    ; [修正] 計算索引必須使用 MAP_WIDTH
    mov ecx, MAP_WIDTH  
    mul ecx
    add eax, ebx    
    mov edi, OFFSET mapData
    add edi, eax
    mov bl, BYTE PTR [edi]  ; BL = Component ID
    
    ; 計算 componentChars 的起始地址
    movzx eax, bl   
    mov edx, 15     ; 每個元件 15 bytes (這是圖形資料大小，不是地圖寬度，不用改)
    mul edx         
    mov edi, OFFSET componentChars
    add edi, eax    
    
    ; 加上 Y 軸像素偏移
    pop eax         ; [Stack -1] 取出 Pixel Offset Y
    mov edx, 5      
    mul edx         
    add edi, eax    
    
    ; 加上 X 軸像素偏移
    pop eax         ; [Stack -2] 取出 Pixel Offset X
    add edi, eax    

    ; 繪製該字元
    INVOKE WriteConsoleOutputCharacter, outputHandle, edi, 1, xyPosition, ADDR count
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, 1, xyPosition, ADDR bytesWritten
    
RESTORE_FINISH:
    ret

RESTORE_ABORT:
    ; 錯誤處理：清除 Stack
    pop edx 
    
    mov al, ' '
    mov charBuf, al 
    INVOKE WriteConsoleOutputCharacter, outputHandle, ADDR charBuf, 1, xyPosition, ADDR count
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, 1, xyPosition, ADDR bytesWritten
    ret
_restoreBulletBG ENDP
END