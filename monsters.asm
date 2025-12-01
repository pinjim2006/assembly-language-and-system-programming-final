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
    
drawMonsters PROTO

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
    Direction   BYTE ?          ; 判斷移動方向
    Chars       BYTE 15 DUP(?)  ; 5x3 圖像 
Monster_status ENDS

; 每回合怪的暫存陣列
roundMonsters Monster_status 10 DUP(<>)

; 顏色屬性
monstersAttributes WORD monsterWidth DUP(0Ah)

; 怪的起始位置
monPosInit COORD <12, 10>

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
xyPosition      COORD <>
charBuf         BYTE monsterWidth DUP(?)
bytesWritten    DWORD ?   

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
    mov dx, monPosInit.x
    mov (Monster_status PTR [edi]).pos.x, dx
    mov dx, monPosInit.y
    mov (Monster_status PTR [edi]).pos.y, dx
    
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
; 在地圖上生成
; ------------------------------------------------  

; ------------------------------------------------
; 修正：函式名稱改為 drawMonsters (複數) 以匹配 main.asm
; ------------------------------------------------  

drawMonsters PROC USES eax ebx ecx edx esi edi

    xor ebx, ebx  ; monster index
    
nextMonster:
    ; 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
    lea edi, roundMonsters[eax]

    ; 判斷是否碰到空struct/怪物死亡或走到終點
    cmp (Monster_status PTR [edi]).Speed, 0
    je skip_draw

    ; 起始繪製位置
    mov eax, DWORD PTR (Monster_status PTR [edi]).pos
    mov DWORD PTR xyPosition, eax

    ; 取得怪物圖像開始地址
    lea esi, (Monster_status PTR [edi]).Chars

    mov edx, monsterHeight          ; 怪物高度
rowLoop:
    mov ecx, monsterWidth
    lea edi, charBuf
    cld
    rep movsb                       
    
    INVOKE WriteConsoleOutputAttribute,
      outputHandle, 
      ADDR monstersAttributes,
      monsterWidth, 
      xyPosition,
      ADDR bytesWritten
      
    INVOKE WriteConsoleOutputCharacter, 
      outputHandle, 
      ADDR charBuf,
      monsterWidth,
      xyPosition,
      ADDR count
      
    inc xyPosition.y
    add esi, monsterWidth           
    dec edx
    jnz rowLoop

skip_draw:
    inc ebx                         
    cmp ebx, 10
    jl nextMonster

    ret
drawMonsters ENDP

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

move_loop:              
    ; 讀怪獸座標
    mov dx, (Monster_status PTR [edi]).pos.x
    mov ax, (Monster_status PTR [edi]).pos.y
    
    sub dx, blockPosInit.x
    sub ax, blockPosInit.y

    xor edx, edx
    movzx eax, ax        
    
    ; [修正] div 指令不能用常數，必須轉到暫存器
    push ecx
    mov ecx, blockHeight
    div ecx          
    pop ecx
    
    movzx eax, ax        
    
    push ebx             
    mov ebx, MAP_WIDTH
    mul ebx              
    pop ebx
    
    mov esi, eax         

    ; 計算 X 索引
    mov ax, (Monster_status PTR [edi]).pos.x
    sub ax, blockPosInit.x
    xor dx, dx
    
    ; [修正] div 指令不能用常數
    push ecx
    mov ecx, blockWidth
    div ecx            
    pop ecx
    
    movzx eax, ax
    add esi, eax         

    ; 取得地圖元件
    mov eax, OFFSET mapData 
    add eax, esi
    mov al, byte ptr [eax]  
    
    mov dl, (Monster_status PTR [edi]).Direction

    ; 物件判斷
    cmp al, COMPONENT_EXIT
    je skip_all

    cmp al, COMPONENT_PATH_H
    je move_H
    cmp al, COMPONENT_PATH_V
    je move_V

    cmp al, COMPONENT_CORNER_1  
    je turnCorner1
    cmp al, COMPONENT_CORNER_2  
    je turnCorner2
    cmp al, COMPONENT_CORNER_3  
    je turnCorner3
    cmp al, COMPONENT_CORNER_4  
    je turnCorner4


    ; 直走
move_H:
    cmp dl, 2   
    je move_L
    jmp move_R

move_V:
    cmp dl, 0   
    je move_U
    jmp move_D


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
    sub (Monster_status PTR [edi]).pos.y, 1 
    jmp moved
move_down: 
    add (Monster_status PTR [edi]).pos.y, 1 
    jmp moved
move_left: 
    sub (Monster_status PTR [edi]).pos.x, 1 
    jmp moved
move_right: 
    add (Monster_status PTR [edi]).pos.x, 1 
    
move_U: jmp move_up
move_D: jmp move_down
move_L: jmp move_left
move_R: jmp move_right

moved:
    dec ecx
    cmp ecx, 0
    jg move_loop        


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

removeMonsters PROC USES ebx edi

    xor ebx, ebx

check:
    ; [修正] 手動計算 Struct Offset
    mov eax, SIZE Monster_status
    mul ebx
    lea edi, roundMonsters[eax]
    
    cmp (Monster_status PTR [edi]).Speed, 0       
    je nextMon
    
    cmp (Monster_status PTR [edi]).HP, 0
    jle monDead               
    
    cmp (Monster_status PTR [edi]).pos.x, 100     
    jne nextMon
    cmp (Monster_status PTR [edi]).pos.y, 100      
    jne nextMon
    jmp monArrive

monDead:
	;待新增擊殺報酬
    mov (Monster_status PTR [edi]).Speed, 0     
    jmp nextMon

monArrive:
	;待新增怪物抵達終點懲罰
    mov (Monster_status PTR [edi]).Speed, 0

nextMon:            
    inc ebx
    cmp ebx, 10
    jb check
    
    ret
removeMonsters ENDP

