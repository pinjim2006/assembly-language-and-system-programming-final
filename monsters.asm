; =================================================================================
; monsters.asm
; =================================================================================

; ------------------------------------------------
; 函式原型宣告 (Prototypes)
; ------------------------------------------------
; [修正] 參數定義必須與 PROC 一致
createMonsters PROTO, roundVal:DWORD

initMonsterData PROTO,
    monsterID:DWORD, 
    pOut:PTR Monster_status 
	
ctrlDraw PROTO	
    
drawMonsters PROTO

restoreGraphicsAtMonPos PROTO

updateMonstersPositions PROTO
    
removeMonsters PROTO

; ------------------------------------------------
; 常數定義
; ------------------------------------------------

monsterWidth = 5
monsterHeight = 3

; 怪物類型常數
MONSTER_NOOB        = 101
MONSTER_GOBLIN      = 102
MONSTER_NEKOMATA    = 103
MONSTER_LAGOM       = 104
MONSTER_WARLOCK     = 105
MONSTER_ILLUMINAGON = 106
MONSTER_ZERA        = 107
MONSTER_KRAKEN      = 108
MONSTER_ABYSSION    = 109

.data

; ------------------------------------------------
; 定義每回合個別怪物結構 (Size = 2 + 1 + 1 + 4 + 1 + 15 = 24 bytes)
; ------------------------------------------------
Monster_status STRUCT
    HP          WORD 0          ; 血量
    Speed       BYTE 0          ; 移動速度
    Reward      BYTE 0          ; 擊殺報酬
    pos         COORD <?, ?>    ; 初始座標 (4 bytes)
	prev_pos    COORD <?, ?>	; 現在座標(清殘影用)
	alrearyDraw BYTE 0			; 判斷是否生成(0:尚未/1:已生成)
	moveCounter	BYTE 0			; 加到100就移動
    Direction   BYTE ?          ; 判斷移動方向
    Chars       BYTE 15 DUP(?)  ; 5x3 圖像 
Monster_status ENDS

; 每回合怪的暫存陣列
roundMonsters Monster_status 10 DUP(<>)

; 顏色屬性
monstersAttributes WORD monsterWidth DUP(0F4h)



; 怪的起始位置
monPosInit COORD <12, 10>

; 怪的終止位置
monPosEnd COORD <72, 7>

; 怪的初始移動方向
map1_InitDirection BYTE 1

; ------------------------------------------------
; 定義每種怪物的圖像
; ------------------------------------------------
MonstersChars LABEL BYTE

; 怪物1 菜雞: 
Monster1 BYTE 2 DUP(' '), 01h, 2 DUP(' ')      
         BYTE (' '), 0DAh, 0B0h, 0BFh, (' ')  
         BYTE 2 DUP(' '), 0BAh, 2 DUP(' ')    

; 怪物2 哥布林: 
Monster2 BYTE (' '), 3Ch, 02h, 3Eh, (' ')      
         BYTE (' '), 0DAh, 0DBh, 0C4h, 0E2h
         BYTE 2 DUP(' '), 0BAh, 2 DUP(' ') 
        
; 怪物3 貓妖: 
Monster3 BYTE (' '), 1Eh, (' '), 1Eh, (' ')        
         BYTE 28h, 0EDh, 41h, 0EDh, 29h 
         BYTE 2 DUP(' '), 0E3h, 2 DUP(' ')       
        
; 怪物4 兔獸:
Monster4 BYTE (' '), 0EFh, (' ') , 0EFh,(' ')        
         BYTE (' '), 28h, 0ECh, 29h, (' ')  
         BYTE (' '), 0D1h, (' '), 0D1h,(' ')  

; 怪物5 術師: 
Monster5 BYTE 2 DUP(' '), 93h, 2 DUP(' ')
         BYTE (' '), 2Fh, 0B2h, 5Ch, 0EAh 
         BYTE (' '),0DDh, 0E1h, 0DEh, (' ')
        
; 怪物6 光魍: 
Monster6 BYTE (' '), 60h, 0Fh, 27h,(' ')     
         BYTE (' '), 0C1h, 99h, 0C1h, (' ') 
         BYTE (' '), 3 DUP(9Dh),  (' ') 
          
; 怪物7 賽拉: 
Monster7 BYTE (' '), 0F9h, 23h, 0F9h, (' ')     
         BYTE (' '), 5Bh, 06h, 5Dh, (' ') 
         BYTE 5 DUP(8Fh)  
        
; 怪物8 海怪: 
Monster8 BYTE 0F7h , 3 DUP(15h), 0F7h        
         BYTE 0F7h, 0E9h, (' '), 0E9h, 0F7h 
         BYTE (' '), 3 DUP(15h), (' ') 
        
; 怪物9 終淵: 
Monster9 BYTE 28h, 0F8h, 77h, 0F8h, 29h    
         BYTE (' '), 0CCh, 0CEh, 0B9h, (' ')
         BYTE 2 DUP(0D6h), 0D2h,2 DUP(0B7h)       
        
; ------------------------------------------------
; 怪物能力表
; [修正] HP 超過 255，必須使用 WORD (DW)。
; 每一列的大小變成 2(HP) + 1(Speed) + 1(Reward) = 4 bytes
; ------------------------------------------------
MonsterTypeTable LABEL BYTE
    ;  HP(DW)   Speed(DB)  Reward(DB)
    DW 10       
    DB 1, 1           ; 101 菜雞
    DW 15       
    DB 1, 1           ; 102 哥布林
    DW 50       
    DB 2, 2           ; 103 貓妖
    DW 35       
    DB 3, 2           ; 104 兔獸
    DW 100      
    DB 1, 3           ; 105 術師
    DW 250      
    DB 2, 3           ; 106 光魍
    DW 160      
    DB 4, 3           ; 107 賽拉
    DW 300      
    DB 1, 4           ; 108 海怪
    DW 444      
    DB 3, 5           ; 109 終淵 
    
; ------------------------------------------------
; 設定每回合生成怪物
; ------------------------------------------------  
RoundsTable LABEL BYTE
    ;Round 1
    DB 2, MONSTER_NOOB, MONSTER_NOOB                                
    ;Round 2
    DB 3, MONSTER_NOOB, MONSTER_GOBLIN, MONSTER_NOOB
    ;Round 3
    DB 3, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN
    ;Round 4
    DB 4, MONSTER_GOBLIN, MONSTER_NEKOMATA, MONSTER_NOOB, MONSTER_NOOB
    ;Round 5
    DB 4, MONSTER_NEKOMATA, MONSTER_LAGOM, MONSTER_NOOB, MONSTER_NOOB
    ;Round 6
    DB 10, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN, MONSTER_GOBLIN
    ;Round 7
    DB 2, MONSTER_WARLOCK, MONSTER_NEKOMATA
    ;Round 8
    DB 3, MONSTER_LAGOM, MONSTER_LAGOM, MONSTER_NEKOMATA
    ;Round 9
    DB 1, MONSTER_ILLUMINAGON
    ;Round 10
    DB 2, MONSTER_ZERA, MONSTER_ZERA
    ;Round 11
    DB 4, MONSTER_NEKOMATA, MONSTER_LAGOM, MONSTER_NOOB, MONSTER_WARLOCK 
    ;Round 12
    DB 2, MONSTER_ILLUMINAGON, MONSTER_ZERA
    ;Round 13
    DB 5, MONSTER_ZERA, MONSTER_NEKOMATA, MONSTER_LAGOM, MONSTER_NEKOMATA, MONSTER_ZERA
    ;Round 14
    DB 2, MONSTER_ILLUMINAGON, MONSTER_KRAKEN
    ;Round 15
    DB 2, MONSTER_KRAKEN, MONSTER_KRAKEN    
    ;Round 16
    DB 6, MONSTER_ILLUMINAGON, MONSTER_ZERA, MONSTER_LAGOM, MONSTER_NOOB, MONSTER_LAGOM, MONSTER_WARLOCK
    ;Round 17
    DB 10, MONSTER_ZERA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_NEKOMATA, MONSTER_WARLOCK
    ;Round 18
    DB 3, MONSTER_ILLUMINAGON, MONSTER_ILLUMINAGON, MONSTER_ILLUMINAGON 
    ;Round 19
    DB 3, MONSTER_ILLUMINAGON, MONSTER_KRAKEN, MONSTER_ILLUMINAGON
    ;Round 20
    DB 4, MONSTER_ZERA, MONSTER_WARLOCK, MONSTER_ZERA, MONSTER_ABYSSION 

; ------------------------------------------------
; 函數用變數
; ------------------------------------------------ 
timeCounter     DWORD 0 		; 計算生怪延遲時間
xyPosition      COORD <>		; 暫存座標
charBuf         BYTE 15 DUP(?)	; 暫存圖像資料
bytesWritten    DWORD ? 
monsterCount	BYTE 0    		; 計算場上怪獸數  

.code

; ------------------------------------------------
; 尋找該回合要生成的怪物
; ------------------------------------------------
; [修正] 參數 roundVal 直接寫在 PROC 後面
createMonsters PROC USES eax ebx ecx edx esi edi, roundVal:DWORD
    
    mov esi, OFFSET RoundsTable
    mov edi, 1        ; round index
    xor eax, eax      ; 用作累加offset

findRoundStart:
    mov edx, roundVal
    cmp edi, edx
    je roundFound
    mov al, [esi]      ; 讀這回合怪物數量
    inc esi            ; 跳過數量
    add esi, eax       ; 跳過怪物ID
    inc edi
    jmp findRoundStart

roundFound:
    movzx ecx, byte ptr [esi]       ; 讀該回合怪物數量 (BYTE)
    inc esi             ; 指向第一個怪物ID
    xor ebx, ebx        ; EBX = roundMonsters 陣列索引

initData:
    movzx eax, byte ptr [esi+ebx]   ; 讀怪物ID，擴展到 EAX
    
    ; [修正] 移除無效的 [ebx*SIZE] 定址，改用手動計算
    push eax
    mov eax, SIZE Monster_status
    mul ebx     ; eax = ebx * 24
    lea edx, roundMonsters[eax]
    pop eax
    
    INVOKE initMonsterData, eax, edx

    inc ebx
    cmp ebx, ecx
    jb initData

    ret
createMonsters ENDP

; ------------------------------------------------
; 初始化怪物數據
; ------------------------------------------------  
; [修正] 參數直接寫在 PROC 後面
initMonsterData PROC USES eax ebx ecx edx esi edi, monsterID:DWORD, pOut:PTR Monster_status 

    mov eax, monsterID
    sub eax, 101                ; EAX:索引

    ; 讀能力值
    mov ebx, OFFSET MonsterTypeTable
    mov ecx, eax
    ; [修正] 每個怪物 entry 是 4 bytes (WORD+BYTE+BYTE)
    imul ecx, 4                 
    
    mov edi, pOut

    ; [修正] 讀取 WORD 大小的 HP
    mov dx, WORD PTR [ebx+ecx]         
    mov (Monster_status PTR [edi]).HP, dx

    ; [修正] 讀取 Speed (偏移 2)
    mov dl, BYTE PTR [ebx+ecx+2]         
    mov (Monster_status PTR [edi]).Speed, dl

    ; [修正] 讀取 Reward (偏移 3)
    mov dl, BYTE PTR [ebx+ecx+3]         
    mov (Monster_status PTR [edi]).Reward, dl
    
    ; 初始化怪物位置
    mov dx, monPosInit.X
    mov (Monster_status PTR [edi]).pos.X, dx
    mov dx, monPosInit.Y
    mov (Monster_status PTR [edi]).pos.Y, dx
    
    ; 初始化移動方向
    mov dl, map1_InitDirection
    mov (Monster_status PTR [edi]).Direction, dl

    ; 讀圖像 
    mov ebx, OFFSET MonstersChars
    mov ecx, eax
    imul ecx, 15                ; 對應不同怪的圖像 (15 bytes)
    lea esi, [ebx+ecx]          ; 圖像來源
    
    mov edi, pOut
    add edi, OFFSET Monster_status.Chars 
    
    mov ecx, 15
    rep movsb                   ; 複製圖像
    
    ret
initMonsterData ENDP

  

; ------------------------------------------------
; 控制怪物的生成(判斷怪要不要畫出，要再call drawMonsters)
; ------------------------------------------------  
ctrlDraw PROC USES eax ebx ecx edx esi edi
	mov eax, timeCounter
	inc eax
	cmp eax, 20
	jb storeCounter

	mov timeCounter, 0
	xor ebx, ebx
findSet:	
	; 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
    lea edi, roundMonsters[eax]
	
	cmp (Monster_status PTR [edi]).alrearyDraw, 0
	je setDraw
	inc ebx
	cmp ebx, 10
	je callPROC
	jmp findSet	
	
setDraw:
	mov (Monster_status PTR [edi]).alrearyDraw, 1
	;mov dl, monsterCount    <---------------------------------(施工中)
	;inc dl
	;mov monsterCount, dl
	jmp callPROC
	
storeCounter:
	mov timeCounter, eax
	
callPROC:
	call updateMonstersPositions 
	call restoreGraphicsAtMonPos 
    call removeMonsters  
	call drawMonsters
	
	ret
ctrlDraw ENDP 

; ------------------------------------------------
; 在地圖上生成(要用到alrearyDraw變數判斷該不該畫出)
; ------------------------------------------------

drawMonsters PROC USES eax ebx ecx esi edi

    xor ebx, ebx    ; monster index
    
nextMonster:
    ; 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
    lea edi, roundMonsters[eax]

    ; 判斷是否碰到空struct/怪物死亡或走到終點
    cmp (Monster_status PTR [edi]).Speed, 0
    je skip_draw
	
	;尚未到達生成時間
	cmp (Monster_status PTR [edi]).alrearyDraw, 0
	je skip_draw

    ; 起始繪製位置
    mov ax, (Monster_status PTR [edi]).pos.X
    mov xyPosition.X, ax
    mov ax, (Monster_status PTR [edi]).pos.Y
    mov xyPosition.Y, ax
	
	lea esi, (Monster_status PTR [edi]).Chars                
    ; 取得怪物圖像開始地址  
	
    mov ecx, monsterHeight      ; 怪物高度
rowLoop:
    push ecx
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR monstersAttributes, monsterWidth, xyPosition, ADDR bytesWritten
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, monsterWidth, xyPosition, ADDR count
    add esi, monsterWidth  
    inc xyPosition.Y        ; 游標 Y 座標向下移動一行
	pop ecx
	loop rowLoop

skip_draw:
    inc ebx                 
    cmp ebx, 10
    jl nextMonster

    ret
drawMonsters ENDP

; ------------------------------------------------
; 清除殘影(要用到alrearyDraw變數判斷該不該清除/且需大改成一次移動一整格)
; ------------------------------------------------
restoreGraphicsAtMonPos PROC USES eax ebx ecx edx esi edi
    xor ebx, ebx ; EDI = monster index (loop counter)

next_restore:
    ; 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
	push ebx
    lea edi, roundMonsters[eax] ; ESI -> monster struct
	
	;尚未到達生成時間
	cmp (Monster_status PTR [edi]).alrearyDraw, 0
	je skip_this_mon  
	
    ; 將要恢復的元件座標存入xyPosition
    mov ax, word ptr (Monster_status PTR [edi]).prev_pos.X
    mov xyPosition.X, ax
    mov ax, word ptr (Monster_status PTR [edi]).prev_pos.Y
    mov xyPosition.Y, ax

RESTORE_MAP:
    ;找對應的地圖索引
    movzx eax, (Monster_status PTR [edi]).prev_pos.X
    sub eax, 7
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax ; EBX : 地圖X座標
    
    ; Y Index (Row)
    movzx eax, (Monster_status PTR [edi]).prev_pos.Y
    sub eax, 4
    mov ecx, blockHeight
    xor edx, edx
    div ecx ; EAX = 地圖Y座標
    
    ; 檢查邊界
    cmp ebx, MAP_WIDTH
    jge skip_this_mon
    cmp eax, MAP_HEIGHT
    jge skip_this_mon
    
    ; 找對應的地圖元件
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi] ; CL : 元件
    
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
    INVOKE WriteConsoleOutputCharacter, outputHandle, esi, blockWidth, xyPosition, ADDR count
    INVOKE WriteConsoleOutputAttribute, outputHandle, ADDR blockAttributes, blockWidth, xyPosition, ADDR cellsWritten
    add esi, blockWidth
    inc xyPosition.Y
    pop ecx
    loop DRAW_RESTORE_LOOP

skip_this_mon:
    inc edi ; Increment monster index (EDI)
	pop ebx
	inc ebx
	cmp ebx, 10
    jb next_restore
    
    ret
restoreGraphicsAtMonPos ENDP

; ------------------------------------------------
; 怪物移動
; ------------------------------------------------  

updateMonstersPositions PROC USES eax ebx ecx edx esi edi
	
    xor ebx, ebx      ; 怪的索引


nextMon:
    ; [修正] 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
    lea edi, roundMonsters[eax]

    movzx ecx, (Monster_status PTR [edi]).Speed    
    cmp ecx, 0
    jle skip 
	
	;尚未到達生成時間
	cmp (Monster_status PTR [edi]).alrearyDraw, 0
	je skip
	
	;由速度控制移動
	mov dl,(Monster_status PTR [edi]).moveCounter
	add dl, (Monster_status PTR [edi]).Speed
	cmp dl, 10
	jge startMove
	
saveCount:
	mov (Monster_status PTR [edi]).moveCounter, dl
	jmp skip
	
startMove:	
	mov (Monster_status PTR [edi]).moveCounter, 0
move_loop:              
       
	;找對應的地圖索引
    mov ax, (Monster_status PTR [edi]).pos.X
	mov (Monster_status PTR [edi]).prev_pos.X, ax
    sub ax, blockPosInit.X
	movzx eax, ax
    mov ebx, blockWidth
    xor edx, edx
    div ebx
    mov ebx, eax ; EBX : 地圖X座標
    
    ; Y Index (Row)
    mov ax, (Monster_status PTR [edi]).pos.Y
	mov (Monster_status PTR [edi]).prev_pos.Y, ax
    sub ax, blockPosInit.Y
	movzx eax, ax
    mov ecx, blockHeight
    xor edx, edx
    div ecx ; EAX = 地圖Y座標
	
    
    ; 檢查邊界
    cmp ebx, MAP_WIDTH
    jge skip
    cmp eax, MAP_HEIGHT
    jge skip
    
    ; 找對應的地圖元件
    mov ecx, MAP_WIDTH
    mul ecx
    add eax, ebx
    mov esi, OFFSET mapData
    add esi, eax
    mov cl, BYTE PTR [esi] ; CL : 元件  
    
    mov dl, (Monster_status PTR [edi]).Direction

    ; 物件判斷
    cmp cl, COMPONENT_EXIT
    je skip_all

    cmp cl, COMPONENT_PATH_H
    je move_H
    cmp cl, COMPONENT_PATH_V
    je move_V

    cmp cl, COMPONENT_CORNER_1  
    je turnCorner1
    cmp cl, COMPONENT_CORNER_2  
    je turnCorner2
    cmp cl, COMPONENT_CORNER_3  
    je turnCorner3
    cmp cl, COMPONENT_CORNER_4  
    je turnCorner4


    ; 直走
move_H:
    cmp dl, 2   
    je move_left
    jmp move_right

move_V:
    cmp dl, 0   
    je move_up
    jmp move_down


    ; 轉角處
turnCorner1: 
    .IF dl == 0 
        mov (Monster_status PTR [edi]).Direction, 2 
        jmp move_left 
    .ENDIF 
    mov (Monster_status PTR [edi]).Direction, 1 
    jmp move_down 
turnCorner2: 
    .IF dl == 0 
        mov (Monster_status PTR [edi]).Direction, 3 
        jmp move_right 
    .ENDIF 
    mov (Monster_status PTR [edi]).Direction, 1 
    jmp move_down 
turnCorner3: 
    .IF dl == 1 
        mov (Monster_status PTR [edi]).Direction, 3 
        jmp move_right 
    .ENDIF 
    mov (Monster_status PTR [edi]).Direction, 0 
    jmp move_up 
turnCorner4: 
    .IF dl == 1 
        mov (Monster_status PTR [edi]).Direction, 2 
        jmp move_left 
    .ENDIF 
    mov (Monster_status PTR [edi]).Direction, 0 
    jmp move_up 
    
move_up: 
    sub (Monster_status PTR [edi]).pos.y, blockHeight 
    jmp moved
move_down: 
    add (Monster_status PTR [edi]).pos.y, blockHeight 
    jmp moved
move_left: 
    sub (Monster_status PTR [edi]).pos.x, blockWidth
    jmp moved
move_right: 
    add (Monster_status PTR [edi]).pos.x, blockWidth 



moved:
skip_all:
skip:
    inc ebx
    cmp ebx, 10
    jb nextMon

    ret
updateMonstersPositions ENDP

; ------------------------------------------------
; 移除死亡或走到終點的怪
; ------------------------------------------------  

removeMonsters PROC USES eax ebx edx edi

    xor ebx, ebx

check:
    ; [修正] 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
    lea edi, roundMonsters[eax]
	
    cmp (Monster_status PTR [edi]).Speed, 0       
    je nextMon
    
	;判斷怪被擊殺
    cmp (Monster_status PTR [edi]).HP, 0
    jle monDead               
    
	;判斷怪抵達終點
	mov dx, monPosEnd.X 
    cmp (Monster_status PTR [edi]).pos.X, dx   
    jne nextMon	
	mov dx, monPosEnd.Y
    cmp (Monster_status PTR [edi]).pos.Y, dx      
    jne nextMon
    jmp monArrive

monDead:
	;待新增擊殺報酬     
    jmp processMonData

monArrive:
	; 怪物抵達終點懲罰 - 扣除生命值
	mov eax, life
	dec eax
	mov life, eax
	
	; 檢查生命值是否歸零
	cmp eax, 0
	jle triggerGameOver
	jmp processMonData
	
triggerGameOver:
	mov gameOver, 1
	
processMonData:
	mov (Monster_status PTR [edi]).Speed, 0
	;(施工中)
	;mov dl, monsterCount
	;dec dl
	;mov monsterCount, dl
	;cmp dl, 0
	;ja nextMon
	
; 判斷回合結束與否	(施工中)
endWave:
	;mov startWave, 0
	;mov dl, cur_round
	;inc dl
	;mov cur_round, dl

nextMon:            
    inc ebx
    cmp ebx, 10
    jb check
    
    ret
removeMonsters ENDP

