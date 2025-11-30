INCLUDE Irvine32.inc

main EQU start@0


;------------------------------------------------
; 函式原型宣告 (Prototypes)
;------------------------------------------------
createMonsters PROTO, round:BYTE

initMonsterData PROTO,
	monsterID:BYTE, 
    pOut:PTR Monster_status 
	
drawMonster PROTO

updateMonstersPositions PROTO
	
removeMonsters PROTO

;------------------------------------------------
;常數定義
;------------------------------------------------

monsterWidth = 5
monsterHeight = 3

;怪物類型常數
MONSTER_NOOB = 101
MONSTER_GOBLIN = 102
MONSTER_NEKOMATA = 103
MONSTER_LAGOM = 104
MONSTER_WARLOCK = 105
MONSTER_ILLUMINAGON = 106
MONSTER_ZERA = 107
MONSTER_KRAKEN = 108
MONSTER_ABYSSION = 109

.data

;------------------------------------------------
; 定義每回合個別怪物結構
;------------------------------------------------
Monster_status STRUCT
    HP      WORD 0         ; 血量
    Speed   BYTE 0         ; 移動速度
	Reward  BYTE 0		   ; 擊殺報酬
    pos COORD <?, ?>	   ; 初始座標
	Direction BYTE ?	   ; 判斷移動方向(0:上/1:下/2:左/3:右)
    Chars   BYTE 15 DUP(?) ; 5x3 圖像 
Monster ENDS

;每回合怪的暫存陣列
roundMonsters Monster_status 10 DUP(<>)

;顏色屬性
monstersAttributes WORD monsterWidth DUP(0Ah)

;怪的起始位置
monPosInit COORD <12, 10>

;怪的初始移動方向
map1_InitDirection BYTE 1

;------------------------------------------------
; 定義每種怪物的圖像
;------------------------------------------------
MonstersChars LABEL BYTE

; 怪物1 菜雞: 
Monster1 BYTE 2 DUP(' '), 01h, 2 DUP(' ')      
         BYTE (' '), 0DAh, 0B0h, 0BFh, (' ')  
         BYTE 2 DUP(' '), 0BAh, 2 DUP(' ')   

; 怪物2 哥布林: 
Monster2 BYTE  (' '), 3Ch, 02h, 3Eh, (' ')      
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
         BYTE BYTE (' '), 3 DUP(15h), (' ') 
		 
; 怪物9 終淵: 
Monster9 BYTE 28h, 0F8h, 77h, 0F8h, 29h   
         BYTE (' '), 0CCh, 0CEh, 0B9h, (' ')
         BYTE 2 DUP(0D6h), 0D2h,2 DUP(0B7h)		 
		 
;------------------------------------------------
; 怪物能力表
;------------------------------------------------
MonsterTypeTable LABEL BYTE

    ;  HP, Speed, Reward
    DB 10,     1,      1			; 101 菜雞
    DB 15, 	   1,	   1			; 102 哥布林
    DB 50,     2,      2			; 103 貓妖
    DB 35,     3,      2			; 104 兔獸
    DB 100,    1,      3			; 105 術師
    DB 250,    2,      3			; 106 光魍
    DB 160,    4,      3			; 107 賽拉
    DB 300,    1,      4			; 108 海怪
    DB 444,    3,      5			; 109 終淵 
	
;------------------------------------------------
; 設定每回合生成怪物
;------------------------------------------------	
RoundsTable LABEL BYTE

	;第一個數字n是生怪數量，接下來有n個數字代表怪的種類
	
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
	DB 5, MONSTER_ZERA, MONSTER_NEKOMATA, MONSTER_LAGOM,, MONSTER_NEKOMATA, MONSTER_ZERA
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

;------------------------------------------------
; 函數用變數
;------------------------------------------------	

xyPosition COORD <>
charBuf BYTE monsterWidth DUP(?)
cur_round  BYTE 1      ; 從第1回合開始打
startWave  BYTE 0      ; 0 = 等待開始 / 1 = 開始生成怪
		 
.code
;------------------------------------------------
; 尋找該回合要生成的怪物
;------------------------------------------------
	
createMonsters PROC	USES eax ebx ecx edx esi edi
	round:BYTE
	
	mov esi, OFFSET RoundsTable
	mov edi, 1        ; round index
	xor eax, eax      ; 用作累加offset

findRoundStart:
    cmp edi, round
    je roundFound
    mov al, [esi]      ; 讀這回合怪物數量
    inc esi            ; 跳過數量
    add esi, eax       ; 跳過怪物ID
    inc edi
    jmp findRoundStart

roundFound:
    mov ecx, [esi]       ; 讀該回合怪物數量 (BYTE)
    inc esi             ; 指向第一個怪物ID
    xor ebx, ebx        ; EBX = roundMonsters 陣列索引

initData:
    movzx eax, byte ptr [esi+ebx]   ; 讀怪物ID，擴展到 EAX
    lea edx, roundMonsters[ebx*SIZE Monster_status] ; 取得該怪物結構地址
    INVOKE initMonsterData, eax, edx

    inc ebx
    cmp ebx, ecx
    jb initData

    ret
createMonsters ENDP

;------------------------------------------------
; 初始化怪物數據
;------------------------------------------------	
	 
initMonsterData PROC USES eax ebx ecx edx esi edi
    monsterID:BYTE, 
    pOut:PTR Monster_status    	; Monster_status 變數

    mov eax, monsterID
    sub eax, 101            	; EAX:索引

    ; 讀能力值
    mov ebx, OFFSET MonsterTypeTable
    mov ecx, eax
    imul ecx, 3                	; 對應不同怪的status row
    mov edi, pOut

    mov dx, [ebx+ecx]          	; HP
    mov [edi].HP, dx

    mov dl, [ebx+ecx+1]        	; Speed
    mov [edi].Speed, dl

    mov dl, [ebx+ecx+2]        	; Reward
    mov [edi].Reward, dl
	
	; 初始化怪物位置
	mov dx, monPosInit.x
	mov [edi].pos.x, dx
	mov dx, monPosInit.y
	mov [edi].pos.y, dx
	
	;初始化移動方向
	mov dl, map1_InitDirection
	mov [edi].Direction, dl

    ; 讀圖像 
    mov ebx, OFFSET MonstersChars
    mov ecx, eax
    imul ecx, 15               	; 對應不同怪的圖像
    lea esi, [ebx+ecx]         	; 圖像來源
    lea edi, [pOut].Chars ; 結構內圖像起點
    mov ecx, 15
    rep movsb                  	; 複製圖像
	
	ret
initMonsterData ENDP

;------------------------------------------------
; 在地圖上生成
;------------------------------------------------	

drawMonster PROC USES eax ebx ecx edx esi edi

    xor ebx, ebx  ; monster index
	mov eax, 500  ; delay 要用
	
nextMonster:
    ;取得怪物結構 
    lea edi, roundMonsters[ebx*SIZE Monster_status]

    ; 判斷是否碰到空struct/怪物死亡或走到終點(SPEED為空可判斷)
    cmp [edi].Speed, 0
    je done

    ; 起始繪製位置
    mov xyPosition, [edi].pos

    ; 取得怪物圖像開始地址
    lea esi, [edi].Chars

    mov edx, monsterHeight      	; 怪物高度
rowLoop:
    mov ecx, monsterWidth
    lea edi, charBuf
    cld
    rep movsb        				; 由 ESI 複製 monsterWidth 個字元到 charBuf
	INVOKE WriteConsoleOutputAttribute,
	  outputHandle, 
	  ADDR monstersAttributes,
	  monsterWidth, 
	  xyPosition,
	  ADDR bytesWritten
    invoke WriteConsoleOutputCharacter, 
	  outputHandle, 
	  ADDR charBuf,
	  monsterWidth,
	  xyPosition,
	  ADDR count
    inc xyPosition.y
    add esi, monsterWidth  			; 指向下一行圖像
    dec edx
    jnz rowLoop

    call Delay         				; 停頓500ms再畫下一隻
    inc ebx            				; 下一隻
    jmp nextMonster

done:
    ret
drawMonster ENDP

;------------------------------------------------
; 怪物移動(待更新，可能出現碰觸邊界即轉向之未貼合路徑瑕疵
;------------------------------------------------	

updateMonstersPositions PROC USES eax ebx ecx edx esi edi

    xor ebx, ebx      ; 怪的索引

nextMon:
    lea edi, roundMonsters[ebx*SIZE Monster_status]

    movzx ecx, [edi].Speed   ; speed: 要執行幾次移動
	cmp ecx, 0
    jle skip 

move_loop:             


; 讀怪獸座標，轉換成地圖索引

    mov dx, [edi].pos.x
    mov ax, [edi].pos.y
    
    sub dx, blockPosInit.x
    sub ax, blockPosInit.y

    xor edx, edx
    div blockHeight          
    xor ah, ah
    mul MAP_WIDTH
    mov si, ax

    mov ax, dx
    div blockWidth           
    xor ah, ah
    add si, ax

    mov al, [map1Data + si]
    mov dl, [edi].Direction


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
		mov [edi].Direction, 2 
		jmp move_left 
	.ENDIF 
	mov [edi].Direction, 1 
	jmp move_down 
	turnCorner2: 
	.IF dl == 0 
		mov [edi].Direction, 3 
		jmp move_right 
	.ENDIF 
	mov [edi].Direction, 1 
	jmp move_down 
turnCorner3: 
	.IF dl == 1 
		mov [edi].Direction, 3 
		jmp move_right 
	.ENDIF 
	mov [edi].Direction, 0 
	jmp move_up 
turnCorner4: 
	.IF dl == 1 
		mov [edi].Direction, 2 
		jmp move_left 
	.ENDIF 
	mov [edi].Direction, 0 
	jmp move_up 
	
move_up: 
	sub [edi].pos.y, 1 
move_down: 
	add [edi].pos.y, 1 
move_left: 
	sub [edi].pos.x, 1 
move_right: 
	add [edi].pos.x, 1

moved:
    loop move_loop        ; 重複直到完成Speed次移動


skip_all:
skip:
    inc ebx
    cmp ebx, 10
    jb nextMon

    ret
updateMonstersPositions ENDP

;------------------------------------------------
; 移除死亡或走到終點的怪
;------------------------------------------------	

removeMonsters PROC USES ebx edi

    xor ebx, ebx

check:
    lea edi, roundMonsters[ebx*SIZE Monster_status]
	
	cmp	[edi].Speed, 0		  ; 排除空struct/已經死掉或抵達終點的怪
	je nextMon
	
    cmp [edi].HP, 0
    jle monDead               ; HP=0 清怪
    cmp [edi].pos.x, 100      ; 判斷是否到終點
    jne nextMon
	cmp [edi].pos.y, 100      
    jne nextMon
    jmp monArrive

monDead:
	;------------------------------------
    ; 奬勵 把SPEED調成0避免重加(待做)
	;------------------------------------
	mov WORD PTR [edi].Speed, 0    
	jmp nextM

monArrive:
	;------------------------------------
	; 懲罰 把SPEED調成0避免重加(待做)
	;------------------------------------
	mov WORD PTR [edi].Speed, 0

nextM:
    inc ebx
    cmp ebx, 10
    jb check
	
    ret
removeMonsters ENDP
