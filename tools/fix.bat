@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title 数码医生 - 修复 (v2)
rem ============ 数码医生 v2: 修复(每步先备份到U盘, 可一键还原) ============
rem 纯净原则: 只动下面列出的项, 不装任何软件, 不删任何软件.

set "DIR=%~dp0"

rem ---- 管理员检查(修复需要写系统文件) ----
net session >nul 2>&1
if %errorlevel% neq 0 (
  if /i "%DOCTOR_NOELEV%"=="1" goto main
    echo 修复功能需要管理员权限, 正在申请，请在弹出的窗口点"是"...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:main
rem ---- 本次会话备份目录 ----
set "TS="
for /f "tokens=2 delims==" %%x in ('wmic os get localdatetime /value 2^>nul') do if not defined TS set "TS=%%x"
if not defined TS set "TS=20260905000000"
set "TS=%TS:~0,14%"
set "B=%DIR%..\backup\%TS%"
if not exist "%B%" mkdir "%B%"
set "LOG=%B%\操作记录_%TS%.txt"
echo 数码医生修复记录 %date% %time% > "%LOG%"
echo 备份目录: %B% >> "%LOG%"

rem ---- 生成还原脚本头 ----
>  "%B%\还原_%TS%.bat" echo @echo off
>> "%B%\还原_%TS%.bat" echo echo 正在还原 %TS% 的修改...
>> "%B%\还原_%TS%.bat" echo echo --------------------------------------------------
>> "%B%\还原_%TS%.bat" echo echo 还原完成, 按任意键关闭...
>> "%B%\还原_%TS%.bat" echo pause

:menu
cls
echo ============================================================
echo   数码医生 - 修复菜单...
echo   所有操作都会先备份到: backup\%TS%\  (可一键还原)
echo ------------------------------------------------------------
echo    [1] 刷新 DNS 缓存          (网页打不开/解析错, 无害)
echo    [2] 清除 IE/系统代理       (一开浏览器就弹广告/被劫持)
echo    [3] 重置 WinHTTP 代理      (软件突然连不上网)
echo    [4] 还原 hosts 为默认      (浏览器被广告域名劫持)
echo    [5] 打开备份文件夹(看还原脚本)
echo    [0] 退出...
echo ============================================================
set /p c=请选择(输入数字回车):
if "%c%"=="1" call :fix_dns
if "%c%"=="2" call :fix_proxy
if "%c%"=="3" call :fix_winhttp
if "%c%"=="4" call :fix_hosts
if "%c%"=="5" call :open_backup
if "%c%"=="0" exit /b 0
goto menu

:open_backup
explorer "%B%"
pause
goto menu

:fix_dns
cls
echo 正在刷新 DNS 缓存...
ipconfig /flushdns
echo [%time%] [DNS] 刷新DNS缓存完成 >> "%LOG%"
echo 完成。如果问题还在, 试试 [4] 还原hosts.
pause
goto menu

:fix_proxy
cls
echo 步骤一: 备份当前代理设置(注册表)到备份目录...
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" "%B%\ie_settings_%TS%.reg" /y >nul
echo.
echo 将执行: 系统代理 -关闭-, 代理服务器-清空-, 自动配置脚本-删除-
echo 影响: 需要代理的软件(如科学上网)会切回直连, 需要时重新配置即可.
echo 备份还原: backup\%TS%\ie_settings_%TS%.reg  (或运行还原脚本)
set /p ok=确认执行? (y/n):
if /i not "%ok%"=="y" (
  echo [%time%] [代理] 用户取消 >> "%LOG%"
  echo 已取消, 未做任何修改.
  pause
  goto menu
)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /d "" /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
echo [%time%] [代理] 已清除: ProxyEnable=0, ProxyServer空, AutoConfigURL删除 >> "%LOG%"
>> "%B%\还原_%TS%.bat" echo reg import "%B%\ie_settings_%TS%.reg"
echo 完成! 刷新浏览器试试.
pause
goto menu

:fix_winhttp
cls
echo 备份当前 WinHTTP 代理...
netsh winhttp show proxy > "%B%\winhttp_%TS%.txt" 2>&1
echo.
echo 将执行: netsh winhttp reset proxy  (重置为直连)
set /p ok=确认执行? (y/n):
if /i not "%ok%"=="y" (
  echo [%time%] [WinHTTP] 用户取消 >> "%LOG%"
  echo 已取消.
  pause
  goto menu
)
netsh winhttp reset proxy
echo [%time%] [WinHTTP] 已重置代理 >> "%LOG%"
echo 完成!
pause
goto menu

:fix_hosts
cls
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
echo 步骤一: 备份原 hosts 文件...
copy /y "%HOSTS%" "%B%\hosts_%TS%.bak" >nul
echo   已备份到 backup\%TS%\hosts_%TS%.bak
echo.
echo 将执行: hosts 恢复为默认(仅 localhost 两行)
echo 影响: 之前手动加的映射(如游戏加速、内网地址)会失效...
echo        但被恶意塞进的广告域名也一并清除...
set /p ok=确认执行? (y/n):
if /i not "%ok%"=="y" (
  echo [%time%] [hosts] 用户取消-备份仍在 >> "%LOG%"
  echo 已取消。但备份已保留, 方便以后还原.
  pause
  goto menu
)
>  "%HOSTS%" echo # 数码医生还原 - 默认 hosts(备份见U盘backup)
>> "%HOSTS%" echo # Copyright (c) 1993-2020 Microsoft Corp.
>> "%HOSTS%" echo.
>> "%HOSTS%" echo 127.0.0.1       localhost
>> "%HOSTS%" echo ::1             localhost
echo [%time%] [hosts] 已还原为默认 >> "%LOG%"
>> "%B%\还原_%TS%.bat" echo copy /y "%B%\hosts_%TS%.bak" "%HOSTS%"
ipconfig /flushdns >nul
echo 完成! DNS缓存已一并刷新。刷新浏览器试试.
pause
goto menu