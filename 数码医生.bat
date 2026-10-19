@echo off
chcp 65001 >nul
title 数码医生 (U盘工具箱)
rem ============ 数码医生 主菜单 ============
set "DIR=%~dp0"
:menu
cls
echo ============================================================
echo             数 码 医 生...
echo    U盘上的网管维修工具 + 离线AI诊断 (纯净版/免安装)
echo ------------------------------------------------------------
echo    [1] 一键体检     只读检测, 生成报告(不改任何设置)
echo    [2] 修复问题     备份后可一键还原, 逐项确认...
echo    [3] AI 分析      用U盘自带离线AI读报告出结论...
echo    [4] 打开报告文件夹...
echo    [5] 生成病历卡二维码, 手机扫码看摘要...
echo    [6] 深检        查垃圾软件家族/弹窗广告根源...
echo    [7] 全面体检    体检+深检一次跑完
echo    [0] 退出...
echo ============================================================
set /p c=请选择(输入数字回车):
if "%c%"=="1" call "%DIR%tools\check.bat"
if "%c%"=="2" call "%DIR%tools\fix.bat"
if "%c%"=="3" call "%DIR%tools\ai.bat"
if "%c%"=="4" explorer "%DIR%report" & goto menu
if "%c%"=="5" "%DIR%病历卡.exe" & goto menu
if "%c%"=="6" call "%DIR%tools\deepcheck.bat"
if "%c%"=="7" call "%DIR%tools\全面体检.bat"
if "%c%"=="0" exit /b 0
goto menu