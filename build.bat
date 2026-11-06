@echo off
setlocal
cd /d "%~dp0"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo Visual Studio was not found. Use the prebuilt dist\qwindows.dll instead.
  exit /b 1
)
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS=%%i"
if not defined VS (
  echo MSVC was not found. Use the prebuilt dist\qwindows.dll instead.
  exit /b 1
)
call "%VS%\VC\Auxiliary\Build\vcvars64.bat" || exit /b 1
if not exist dist mkdir dist
cl /nologo /LD /O2 /EHsc /MT /utf-8 /I src /Fe:dist\qwindows.dll src\qwindows_proxy.cpp || exit /b 1
del /q src\qwindows_proxy.obj qwindows_proxy.obj dist\qwindows.exp dist\qwindows.lib 2>nul
echo built dist\qwindows.dll
