@echo off
chcp 65001 >nul
where pwsh >nul 2>&1
if %errorlevel%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
)
if %errorlevel% neq 0 (
  echo 卸载没有完成。
  exit /b %errorlevel%
)
