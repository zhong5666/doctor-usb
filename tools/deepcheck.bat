@echo off
chcp 65001 >nul
title 数码医生 - 深检
rem 深检: 垃圾软件家族/可疑自启追踪 (纯只读, 不改任何设置)
set "DIR=%~dp0"
echo 正在深检(垃圾软件家族/可疑路径, 约10-20秒)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\deepcheck.ps1"
echo.
pause