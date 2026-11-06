# Restore the official Qt platform plugin and the English UI language.
# Usage: .\uninstall.ps1 -EmuDir "D:\Eglantine"
param(
    [string]$EmuDir
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    Write-Host $Message
    exit 1
}

if ($EmuDir -and (Test-Path -LiteralPath $EmuDir -PathType Leaf)) {
    $EmuDir = Split-Path -Parent $EmuDir
}
if (-not $EmuDir) {
    Fail "用法: .\uninstall.ps1 -EmuDir `"eglantine.exe 所在文件夹`""
}
$EmuDir = (Resolve-Path -LiteralPath $EmuDir).Path
$real = Join-Path $EmuDir "qwindows_real.dll"
if (-not (Test-Path -LiteralPath $real) -or (Get-Item -LiteralPath $real).Length -lt 400000) {
    Fail "找不到官方备份 qwindows_real.dll，不能恢复。"
}

foreach ($dir in @(
    (Join-Path $EmuDir "plugins\platforms"),
    (Join-Path $EmuDir "platforms")
)) {
    $dll = Join-Path $dir "qwindows.dll"
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    try {
        Copy-Item -LiteralPath $real -Destination $dll -Force
    } catch {
        Fail "无法写回 $dll。请先关闭 Eglantine。"
    }
    Write-Host "已恢复 $dll"
}

$rcc = Join-Path $EmuDir "languages\zh_CN.rcc"
if (Test-Path -LiteralPath $rcc) {
    Remove-Item -LiteralPath $rcc -Force
    Write-Host "已删除 languages\zh_CN.rcc"
}
$log = Join-Path $EmuDir "languages\zh-load.log"
if (Test-Path -LiteralPath $log) {
    Remove-Item -LiteralPath $log -Force
}

function Set-English([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $enc = $utf8
    try {
        $text = $utf8.GetString($bytes)
    } catch {
        $enc = [System.Text.Encoding]::GetEncoding(936)
        $text = $enc.GetString($bytes)
    }
    if ($text -notmatch '(?m)^Paths\\language=') { return }
    $updated = [regex]::Replace($text, '(?m)^Paths\\language=[^\r\n]*', 'Paths\language=en')
    if ($updated -match '(?m)^Paths\\language\\default=') {
        $updated = [regex]::Replace($updated, '(?m)^Paths\\language\\default=[^\r\n]*', 'Paths\language\default=false')
    }
    if ($updated -ne $text) {
        [System.IO.File]::WriteAllBytes($path, $enc.GetBytes($updated))
    }
    Write-Host "界面语言已改回 en: $path"
}

@(
    (Join-Path $EmuDir "qt-config.ini"),
    (Join-Path $EmuDir "config\qt-config.ini"),
    (Join-Path $EmuDir "user\config\qt-config.ini"),
    (Join-Path $env:APPDATA "eglantine\config\qt-config.ini"),
    (Join-Path $env:APPDATA "eden\config\qt-config.ini")
) | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object { Set-English $_ }

Write-Host "已卸载中文界面插件。qwindows_real.dll 仍留在模拟器目录，作为官方插件备份。"
