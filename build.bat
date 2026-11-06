@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo 没有找到 Visual Studio。可以直接使用已经编译好的 dist\qwindows.dll。
  exit /b 1
)
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS=%%i"
if not defined VS (
  echo 没有找到微软 C++ 编译器。可以直接使用已经编译好的 dist\qwindows.dll。
  exit /b 1
)
call "%VS%\VC\Auxiliary\Build\vcvars64.bat" || exit /b 1
if not exist dist mkdir dist
cl /nologo /LD /O2 /EHsc /MT /utf-8 /I src /Fe:dist\qwindows.dll src\qwindows_proxy.cpp || exit /b 1
del /q src\qwindows_proxy.obj qwindows_proxy.obj dist\qwindows.exp dist\qwindows.lib 2>nul
echo 已生成 dist\qwindows.dll
