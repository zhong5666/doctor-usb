@echo off
chcp 65001 >nul
title 数码医生 - 一键准备 AI (Ollama + 模型)
setlocal
rem ============================================
rem  一键准备 AI(Ollama + qwen2.5 模型)
rem  本文件放在 U盘\OllamaU盘\数码医生\ 下
rem  AI 分析全程离线、免费、无需 API key
rem ============================================
set "HERE=%~dp0"
set "ROOT=%HERE%..\.."
set "NEED=0"

echo ============================================
echo   数码医生 · 一键准备 AI（全离线 · 免费）
echo ============================================
echo.

rem ---------- 检查 Ollama 程序 ----------
if exist "%ROOT%\ollama\ollama.exe" (
  echo [OK]   Ollama 程序     : %ROOT%\ollama\ollama.exe
) else (
  echo [缺失] Ollama 程序     : 未找到 %ROOT%\ollama\ollama.exe
  set NEED=1
)

rem ---------- 检查模型 ----------
set "MODEL_DIR=%ROOT%\models\manifests\registry.ollama.ai\library"
if exist "%MODEL_DIR%" (
  echo [OK]   模型目录        : %ROOT%\models\
  echo       检测到的模型:
  for /d %%d in ("%MODEL_DIR%\*") do echo         - %%~nxd
) else (
  echo [缺失] 模型目录        : %ROOT%\models\ 下没有模型
  set NEED=1
)

echo.
if "%NEED%"=="0" (
  echo ============================================
  echo   ✅ AI 组件齐全，插上 U 盘就能用！
  echo   全程离线、免费，数据不出 U 盘
  echo ============================================
  pause
  exit /b 0
)

echo ============================================
echo   还缺一些组件，按下面 2 步补齐：
echo ============================================
echo.
if not exist "%ROOT%\ollama\ollama.exe" (
  echo 【第1步】拿 Ollama 程序（免费）
  echo   方式A（推荐）: 到 GitHub 仓库
  echo     github.com/zhong5666/doctor-usb
  echo     的 Releases 页面下载 ollama-windows-amd64.zip
  echo     解压后把 ollama.exe 放进:
  echo     %ROOT%\ollama\
  echo   方式B: 官网下载 https://ollama.com/download/windows
  echo.
)
if not exist "%MODEL_DIR%" (
  echo 【第2步】拿模型 qwen2.5（免费，二选一）
  echo   方式A（推荐）: 找一台能联网的电脑：
  echo     1. 安装 Ollama 官网版
  echo     2. 运行:  ollama pull qwen2.5:3b   (8G内存老电脑选这个)
  echo             ollama pull qwen2.5:7b   (16G内存推荐这个)
  echo     3. 把模型目录 models 整个拷回 U 盘
  echo        (Windows 上一般在 C:\Users\你的用户名\.ollama\models)
  echo   方式B: 从网上下载现成的 qwen2.5 模型文件放入
  echo     %ROOT%\models\manifests\registry.ollama.ai\library\qwen2.5\
  echo.
)
echo ============================================
echo   完成后重新双击本脚本，全部 [OK] 即可使用
echo ============================================
pause