@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title 数码医生 - 一键体检 (v1)
rem ============ 数码医生 v1: 只读体检(不改动电脑任何设置) ============
set "DIR=%~dp0"
if not exist "%DIR%..\report" mkdir "%DIR%..\report"

rem ---- 时间戳(取wmic, 与语言无关; 失败则退回date) ----
set "TS="
for /f "tokens=2 delims==" %%x in ('wmic os get localdatetime /value 2^>nul') do if not defined TS set "TS=%%x"
if not defined TS (
  for /f "tokens=1-3 delims=/- " %%a in ('echo %date%') do set "TS=%%a%%b%%c00"
  for /f "tokens=1-2 delims=: " %%a in ('echo %time%') do set "T=%%a%%b"
  set "T=!T: =0!"
  set "TS=!TS!_!T!"
)
set "TS=%TS:~0,14%"
set "RPT=%DIR%..\report\体检报告_%TS%.txt"
type nul > "%RPT%"

echo 正在体检, 请稍候(约20秒)...
call :sec 系统信息 1
echo 电脑名: %COMPUTERNAME%   登录用户: %USERNAME% >> "%RPT%"
ver >> "%RPT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\sysinfo.ps1" -Section SYSTEM >> "%RPT%" 2>nul

call :sec 磁盘空间 2
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\sysinfo.ps1" -Section DISKS >> "%RPT%" 2>nul

call :sec "网络配置(IP/DNS/掩码/网关)" 3
ipconfig /all >> "%RPT%"

call :sec 连通性测试 4
echo [本机] >> "%RPT%"
ping 127.0.0.1 -n 2 >> "%RPT%"
set "GW="
for /f "tokens=3" %%g in ('route print -4 ^| findstr /c:"0.0.0.0"') do if not defined GW set "GW=%%g"
if defined GW (
  echo [默认网关 %GW%] >> "%RPT%"
  ping %GW% -n 2 >> "%RPT%"
) else (
  echo [未找到默认网关] >> "%RPT%"
)
echo [外网 223.5.5.5(阿里DNS)] >> "%RPT%"
ping 223.5.5.5 -n 2 >> "%RPT%"
echo [域名解析测试 www.baidu.com] >> "%RPT%"
nslookup www.baidu.com >> "%RPT%" 2>&1

call :sec "局域网设备(arp邻近表, 可查蹭网/陌生设备)" 5
arp -a >> "%RPT%"

call :sec "正在监听的端口(netstat, 查异常后门)" 6
netstat -ano | findstr LISTENING >> "%RPT%"

call :sec "恶意广告 / 劫持检查" 7
echo [hosts/代理/启动项 检查(含内容)] >> "%RPT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\secinfo.ps1" >> "%RPT%" 2>nul
echo [环境变量代理(如存在可能被注入)] >> "%RPT%"
echo HTTP_PROXY=%HTTP_PROXY% HTTPS_PROXY=%HTTPS_PROXY% >> "%RPT%"
echo. >> "%RPT%"
echo [计划任务列表(任务名; 注意陌生名字)] >> "%RPT%"
powershell -NoProfile -Command "$t = schtasks /query /fo csv /nh 2>$null; '任务总数: ' + $t.Count; $t | ForEach-Object { ($_ -split ',')[0] } | Select-Object -First 40" >> "%RPT%"
echo. >> "%RPT%"
echo [浏览器快捷方式被劫持检查(目标后带参数=被植入广告)] >> "%RPT%"
echo --- 可疑快捷方式(带参数) --- >> "%RPT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\lnkscan.ps1" >> "%RPT%" 2>nul

call :sec "系统状态 / 防火墙" 8
echo [防火墙各配置状态] >> "%RPT%"
powershell -NoProfile -Command "Get-NetFirewallProfile | Select-Object Name,Enabled | Format-List" >> "%RPT%" 2>nul
echo [进程数量与内存占用Top15] >> "%RPT%"
powershell -NoProfile -Command "(Get-Process).Count" >> "%RPT%"
powershell -NoProfile -Command "Get-Process | Sort-Object WS -Descending | Select-Object -First 15 Name,@{n='MEM_MB';e={[math]::Round($_.WS/1MB)}} | Format-Table -AutoSize" >> "%RPT%" 2>nul

echo.
echo ============================================================
echo  体检完成! 报告已保存:
echo    %RPT%
echo.
echo  下一步:
echo    1. 双击 数码医生.bat 选 [2=修复] 处理常见问题...
echo    2. 选 [3=AI分析] 让U盘自带的离线AI读这份报告给结论...
echo    3. 选 [6=深检] 查垃圾软件家族(新机/卡顿/弹广告必跑)...
echo ============================================================
pause
exit /b

:sec
echo. >> "%RPT%"
echo ==================== [%2] %1 ==================== >> "%RPT%"
exit /b