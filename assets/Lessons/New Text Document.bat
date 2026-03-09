@echo off
for /d %%X in (*) do "C:\Program Files\WinRAR\WinRAR.exe" a -ep1 -r "%%X.rar" "%%X"
pause