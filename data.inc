; =================================================================================
; 資料區段 (Data Section)
; 此檔案包含所有遊戲資料變數、陣列、字串等
; 需要先 INCLUDE constants.inc
; =================================================================================

.data
; =========================================================
; [新增] 全域結構定義 (移到這裡以確保統一): 定義每回合個別怪物結構
; =========================================================
Monster_status STRUCT
    HP          WORD 0          ; 0
    Speed       BYTE 0          ; 2
    Reward      BYTE 0          ; 3
    pos         COORD <?, ?>    ; 4
    prev_pos    COORD <?, ?>    ; 8
    alrearyDraw BYTE 0          ; 12
    moveCounter BYTE 0          ; 13
    Direction   BYTE ?          ; 14
    originalSpeed BYTE 0        ; 15 - 原始速度（用於恢復）
    slowTimer   BYTE 0          ; 16 - 減速剩餘時間
    Chars       BYTE 15 DUP(?)  ; 17
    ; Total Size = 32 (若無 Padding)
Monster_status ENDS

Bullet STRUCT
    active      BYTE 0          ; 0
    pos         COORD <?, ?>    ; 1 (注意對齊)
    prev_pos    COORD <?, ?>    ; 5
    targetID    DWORD 0         ; 9
    damage      WORD 0          ; 13
    tType       BYTE 0          ; 15
Bullet ENDS

; =========================================================
; [新增] 全域陣列變數
; =========================================================
; 每回合怪的暫存陣列
roundMonsters Monster_status 10 DUP(<>)

; 子彈系統變數
MAX_BULLETS = 20
bulletList Bullet MAX_BULLETS DUP(<>)

bulletChar      BYTE '*'
bulletAttr      WORD 0ECh

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
strNameA        BYTE "Cannon ($8)", 0
strNameB        BYTE "Sniper ($12)", 0
strNameC        BYTE "Ice    ($16)", 0  
strNameD        BYTE "Mage   ($20)", 0
strNameE        BYTE "Missile($28)", 0 

; --- 側邊選單游標樣式 ---
attrMenuCursor  WORD 4 DUP(0C0h) ; 紅底黑字 (C0h)
menuCursorStr   BYTE " << "

; --- 選單文字屬性 ---
attrMenuName    WORD 12 DUP(0F0h)

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
life            DWORD 10      ; 玩家生命值 (測試用，歸零則遊戲結束)
money           DWORD 10       ; 玩家金錢 (用於建造塔)
gameOver        DWORD 0       ; 遊戲結束標誌 (0=繼續, 1=結束)

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

; 結束遊戲選單文字 (不含 Continue)
endMenuTitle    BYTE "========== GAME END ==========", 0
endMenuOption1  BYTE "   Restart", 0
endMenuOption2  BYTE "   How to Play", 0
endMenuOption3  BYTE "   End Game", 0

; Pixel Art 文字
youWinText      BYTE "YOU WIN", 0
gameOverText    BYTE "GAME OVER", 0

; 使用說明文字
helpTitle       BYTE "========== HOW TO PLAY ==========", 0
helpLine1       BYTE "Arrow Keys: Move cursor", 0
helpLine2       BYTE "F: Select tower (use up and down arrow keys)", 0
helpLine3       BYTE "ENTER: Build tower", 0
helpLine4       BYTE "X: Delete tower (get half money back)", 0
helpLine5       BYTE "G: Start round", 0
helpLine6       BYTE "ESC: Open menu", 0
helpLine7       BYTE "Towers can only be placed on empty tiles", 0
helpLine8		BYTE "If the monster ABYSSION arrives the destination, gamer will lose!", 0
helpLine9		BYTE "Be careful and good luck :)", 0
helpPrompt      BYTE "Press any key to continue...", 0

; 金錢系統提示訊息
insufficientMoneyMsg BYTE "Not enough money!", 0
moneyReturnedMsg     BYTE "Money returned!", 0

; 大數字/字母 ASCII 圖形 (3x3 格式)
; 數字 0-9 (每個 9 bytes = 3行 x 3字元)
bigNum0 BYTE 0DCh,0DCh,0DCh, 0DBh,20h,0DBh, 0DBh,0DCh,0DBh
bigNum1 BYTE 20h,0DCh,20h, 0DFh,0DBh,20h, 20h,0DBh,20h
bigNum2 BYTE 0DCh,0DCh,0DCh, 20h,0DCh,0DFh, 0DBh,0DCh,0DCh
bigNum3 BYTE 0DCh,0DCh,0DCh, 20h,0DCh,0DBh, 0DCh,0DCh,0DBh
bigNum4 BYTE 0DCh,20h,0DCh, 0DBh,0DCh,0DBh, 20h,20h,0DBh
bigNum5 BYTE 0DCh,0DCh,0DCh, 0DBh,0DCh,0DCh, 0DCh,0DCh,0DBh
bigNum6 BYTE 0DCh,0DCh,0DCh, 0DBh,0DCh,0DCh, 0DBh,0DCh,0DBh
bigNum7 BYTE 0DCh,0DCh,0DCh, 20h,20h,0DBh, 20h,20h,0DBh
bigNum8 BYTE 0DCh,0DCh,0DCh, 0DBh,0DCh,0DBh, 0DBh,0DCh,0DBh
bigNum9 BYTE 0DCh,0DCh,0DCh, 0DBh,0DCh,0DBh, 0DCh,0DCh,0DBh

; 完整字母表 A-Z (5x3 格式, 每個 15 bytes = 3行 x 5字元)
bigLetterA BYTE 20h,0DCh,0DCh,0DCh,20h, 0DBh,0DCh,0DCh,0DCh,0DBh, 0DBh,20h,20h,20h,0DBh
bigLetterB BYTE 0DCh,0DCh,0DCh,0DCh,20h, 0DBh,0DCh,0DCh,0DCh,0DFh, 0DBh,0DCh,0DCh,0DCh,0DFh
bigLetterC BYTE 20h,0DCh,0DCh,0DCh,20h, 0DBh,20h,20h,20h,20h, 0DFh,0DCh,0DCh,0DCh,20h
bigLetterD BYTE 0DCh,0DCh,0DCh,0DCh,20h, 0DBh,20h,20h,20h,0DBh, 0DBh,0DCh,0DCh,0DCh,0DFh
bigLetterE BYTE 0DCh,0DCh,0DCh,0DCh,0DCh, 0DBh,0DCh,0DCh,0DCh,20h, 0DBh,0DCh,0DCh,0DCh,0DCh
bigLetterF BYTE 0DCh,0DCh,0DCh,0DCh,0DCh, 0DBh,0DCh,0DCh,0DCh,20h, 0DBh,20h,20h,20h,20h
bigLetterG BYTE 20h,0DCh,0DCh,0DCh,0DCh, 0DBh,20h,0DCh,0DCh,0DCh, 0DFh,0DCh,0DCh,0DCh,0DBh
bigLetterH BYTE 0DCh,20h,20h,20h,0DCh, 0DBh,0DCh,0DCh,0DCh,0DBh, 0DBh,20h,20h,20h,0DBh
bigLetterI BYTE 20h,0DCh,0DCh,0DCh,20h, 20h,20h,0DBh,20h,20h, 20h,0DCh,0DBh,0DCh,20h
bigLetterJ BYTE 20h,0DCh,0DCh,0DCh,20h, 20h,20h,0DBh,20h,20h, 0DFh,0DCh,0DFh,20h,20h
bigLetterK BYTE 0DCh,20h,20h,0DCh,20h, 0DBh,0DCh,0DFh,20h,20h, 0DBh,20h,0DFh,0DCh,20h
bigLetterL BYTE 0DCh,20h,20h,20h,20h, 0DBh,20h,20h,20h,20h, 0DBh,0DCh,0DCh,0DCh,20h
bigLetterM BYTE 0DCh,20h,20h,20h,0DCh, 0DBh,0DFh,0DCh,0DFh,0DBh, 0DBh,20h,20h,20h,0DBh
bigLetterN BYTE 0DCh,20h,20h,20h,0DCh, 0DBh,0DFh,0DCh,20h,0DBh, 0DBh,20h,20h,0DFh,0DBh
bigLetterO BYTE 20h,0DCh,0DCh,0DCh,20h, 0DBh,20h,20h,20h,0DBh, 0DFh,0DCh,0DCh,0DCh,0DFh
bigLetterP BYTE 0DCh,0DCh,0DCh,0DCh,20h, 0DBh,0DCh,0DCh,0DCh,0DFh, 0DBh,20h,20h,20h,20h
bigLetterQ BYTE 20h,0DCh,0DCh,0DCh,20h, 0DBh,20h,0DCh,20h,0DBh, 0DFh,0DCh,0DCh,0DBh,0DCh
bigLetterR BYTE 0DCh,0DCh,0DCh,0DCh,20h, 0DBh,0DCh,0DCh,0DCh,0DFh, 0DBh,20h,20h,0DFh,0DCh
bigLetterS BYTE 20h,0DCh,0DCh,0DCh,0DCh, 0DFh,0DCh,0DCh,0DCh,20h, 0DCh,0DCh,0DCh,0DCh,0DFh
bigLetterT BYTE 0DCh,0DCh,0DCh,0DCh,0DCh, 20h,20h,0DBh,20h,20h, 20h,20h,0DBh,20h,20h
bigLetterU BYTE 0DCh,20h,20h,20h,0DCh, 0DBh,20h,20h,20h,0DBh, 0DFh,0DCh,0DCh,0DCh,0DFh
bigLetterV BYTE 0DCh,20h,20h,20h,0DCh, 0DBh,20h,20h,20h,0DBh, 20h,0DFh,0DCh,0DFh,20h
bigLetterW BYTE 0DCh,20h,20h,20h,0DCh, 0DBh,20h,20h,20h,0DBh, 0DFh,0DCh,0DFh,0DCh,0DFh
bigLetterX BYTE 0DCh,20h,20h,20h,0DCh, 20h,0DFh,0DCh,0DFh,20h, 0DCh,0DFh,20h,0DFh,0DCh
bigLetterY BYTE 0DCh,20h,20h,20h,0DCh, 20h,0DFh,0DCh,0DFh,20h, 20h,20h,0DBh,20h,20h
bigLetterZ BYTE 0DCh,0DCh,0DCh,0DCh,0DCh, 20h,20h,0DCh,0DFh,20h, 0DCh,0DBh,0DCh,0DCh,0DCh

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


; =========================================================
; 防禦塔屬性表 (Type 1-5)
; =========================================================
; 攻擊範圍 (半徑的平方, 避免開根號運算)
; A(Canon): 20^2=400, B(Sniper): 40^2=1600, C(Ice): 12^2=144, D(Mage): 25^2=625, E(Missile): 100^2=10000
towerRangeSq DWORD 400, 1600, 144, 625, 10000

; 攻擊傷害
towerDamage  WORD  5, 40, 2, 8, 333

; 攻擊冷卻時間 (單位: Frame, 50ms/frame)
towerReload  BYTE  15, 60, 2, 10, 100

; 每個塔當前的冷卻計時器 (與 towerMax 對應)
towersCD     BYTE  towerMax DUP(0)

; 範圍顯示用的顏色屬性 (紅色背景 4Fh, 綠色背景 2Fh)
attrRange    WORD  40h  ; 紅色背景(表示攻擊範圍)
attrNormal   WORD  0F0h ; 正常白底黑字