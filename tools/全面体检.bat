@echo off
chcp 65001 >nul
title 数码医生 - 全面体检
rem 一条龙: 标准体检 + 深检一起跑
echo.
echo ===== 第1步/2: 标准体检(8节) =====
echo.
call "%~dp0check.bat"
echo.
echo ===== 第2步/2: 深检(垃圾软件家族) =====
echo.
call "%~dp0deepcheck.bat"
echo.
echo 全面体检完成, 两份报告都在 report\ 文件夹...
pause