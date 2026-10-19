@echo off
chcp 65001 >nul
setlocal
title 数码医生 - AI 分析 (v3)
rem ============ 数码医生 v3: 用U盘里的离线AI读体检报告 ============
rem 全程本机 11435 端口, 不需要网络.

set "DIR=%~dp0"
set "OLLAMA=%~dp0..\..\ollama\ollama.exe"
set "OLLAMA_MODELS=%~dp0..\..\models"
set "OLLAMA_HOST=127.0.0.1:11435"
set "PORT=11435"
if not exist "%DIR%..\report" mkdir "%DIR%..\report"

set "TS="
for /f "tokens=2 delims==" %%x in ('wmic os get localdatetime /value 2^>nul') do if not defined TS set "TS=%%x"
if not defined TS set "TS=20260905000000"
set "TS=%TS:~0,14%"
set "FACTS=%DIR%..\report\facts_%TS%.txt"
set "AI=%DIR%..\report\AI分析_%TS%.txt"

echo 步骤1/3: 检查U盘版Ollama服务(端口11435)...
powershell -NoProfile -Command "try{(Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:11435/api/tags' -TimeoutSec 2).StatusCode|Out-Null;exit 0}catch{exit 1}"
if not errorlevel 1 goto ollup
echo   未运行, 正在启动 U盘版 Ollama(首次加载模型约30秒)...
start "" /min "%OLLAMA%" serve
set /a n=0
:waitoll
set /a n+=1
if %n% gtr 15 (
  echo   [错误] Ollama启动超时, 请检查360之类软件是否拦截.
  pause
  exit /b 1
)
powershell -NoProfile -Command "try{(Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:11435/api/tags' -TimeoutSec 2).StatusCode|Out-Null;exit 0}catch{exit 1}"
if errorlevel 1 (
  timeout /t 2 /nobreak >nul
  goto waitoll
)
:ollup
echo   [OK] 服务在线.

echo 步骤2/3: 采集系统事实数据(纯读取)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\probe.ps1" -Facts "%FACTS%"
if not exist "%FACTS%" (
  echo   [错误] 数据采集失败.
  pause
  exit /b 1
)
echo   [OK] 已生成 %FACTS%

echo 模型选择: 回车=3B(老电脑兼容)  7=7B(更聪明, 16G内存推荐)...
set /p MODEL=请选择:
if "%MODEL%"=="7" (set "MODEL_NAME=qwen2.5:7b") else (set "MODEL_NAME=qwen2.5:3b")
echo 步骤3/3: 离线AI分析中(%MODEL_NAME%, 首次生成约1-3分钟, 请耐心)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%ps\analyze.ps1" -Facts "%FACTS%" -Out "%AI%" -Model "%MODEL_NAME%" -Port 11435
if not exist "%AI%" (
  echo   [错误] AI分析失败, 换 7B 模型或稍后重试.
  pause
  exit /b 1
)
echo.
echo ============================================================
echo   AI 分析完成! 结论已保存:
echo     %AI%
echo   报告文件夹: %DIR%..\report\
echo   (报告可导出给远程协助者二次诊断)
echo ============================================================
pause
exit /b