@echo off
rem run.cmd -Exe <victory.exe> -Game <game.exe> [-Console series-s] [-MipDrop 3]
rem         [-DisplayMode 1280x720] [-CardBuffersMB 512] [-KeepEnv]
rem Starts run.ps1 beside it without changing PowerShell's script policy (no "running scripts is disabled").
rem Applies the fork's low-memory Windows settings (see README.md, "Windows").
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
exit /b %errorlevel%
