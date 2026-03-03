# 環境

請至 [此 Google Drive 連結](https://drive.google.com/file/d/1WzggzChCYfyONy3Og5orwkIF6wuPC4In/view?usp=drive_link) 下載專案所需的環境壓縮檔。

請確保目錄下有以下檔案 (請將`environment.zip`解壓縮並放入專案根目錄中)
```
|-- constants.inc
|-- data.inc
|-- dm.dll
|-- eecxx.dll
|-- em.dll
|-- gdi32.inc
|-- gdi32.lib
|-- GraphWin.inc
|-- Irvine32.inc
|-- Irvine32.lib
|-- Kernel32.Lib
|-- link.exe
|-- Macros.inc
|-- main.asm
|-- make.bat
|-- monsters.asm
|-- ML.ERR
|-- ML.EXE
|-- msdbi.dll
|-- msdis100.dll
|-- MSPDB50.DLL
|-- MSVCP50.DLL
|-- run.bat
|-- shcv.dll
|-- SmallWin.inc
|-- tlloc.dll
|-- tower.asm
|-- user32.inc
|-- User32.Lib
|-- VirtualKeys.inc
|-- windows.inc
```

# 執行方式

1. 請先執行`make.bat`進行組譯，確定沒有錯誤訊息且有出現`main.exe`。

2. 使用`run.bat`來執行`main.exe`，不要直接執行`main.exe`，會有編碼問題。

# 遊玩方式

1. 使用上下左右按鍵來操控

2. 使用按鍵 `f` 來選擇塔

3. 使用 `enter` 來建立塔

4. 使用 `x` 刪除塔

5. 使用 `g` 開始回合

5. 使用 `esc` 來開啟選單

# 遊戲規則

1. 塔僅能建造在空區域

2. 刪除塔僅能拿回該塔的一半價錢

3. 怪物出沒總共20回合

4. 最後一回合中，若終淵抵達終點則玩家戰敗

# debug按鍵

- `!` 減少生命值
- `@` 增加生命值
- `#` 減少金錢
- `$` 增加金錢
- `%` 減少回合
- `^` 增加回合