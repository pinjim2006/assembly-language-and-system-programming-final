; -------------------------------------------------------------------------
; Project: assembly-language-and-system-programming-final
; Copyright (C) 2026 pinjim2006, peresonacifer, HoshimiyaYuuto
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
; -------------------------------------------------------------------------

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

; --- 塔的價格設定 ---
TOWER_A_COST        EQU 8   ; Cannon 價格
TOWER_B_COST        EQU 12   ; Sniper 價格  
TOWER_C_COST        EQU 16   ; Ice 價格
TOWER_D_COST        EQU 20   ; Mage 價格
TOWER_E_COST        EQU 28   ; Missile 價格

.data

; 選單游標位置 (0-3) 用於 ESC 選單
menuCursor          BYTE 0

; --- 塔價格陣列 ---
towerCosts          DWORD TOWER_A_COST, TOWER_B_COST, TOWER_C_COST, TOWER_D_COST, TOWER_E_COST