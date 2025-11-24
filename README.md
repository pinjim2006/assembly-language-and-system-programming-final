# 環境

請確保目錄下有以下檔案 (`windbg.zip`中的檔案)
```
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
|-- user32.inc
|-- User32.Lib
|-- VirtualKeys.inc
|-- windows.inc
```

# 執行方式
1. 請先執行`make.bat`進行組譯，確定沒有錯誤訊息且有出現`main.exe`。

2. 使用`run.bat`來執行`main.exe`，不要直接執行`main.exe`，會有編碼問題。

