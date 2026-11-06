# 把简体中文界面插件装进一个 Eglantine 目录。
# 用法：.\install.ps1 -EmuDir "D:\Eglantine"
param(
    [string]$EmuDir
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Fail([string]$Message) {
    Write-Host $Message
    exit 1
}

if ($EmuDir -and (Test-Path -LiteralPath $EmuDir -PathType Leaf)) {
    $EmuDir = Split-Path -Parent $EmuDir
}
if (-not $EmuDir) {
    if (Test-Path -LiteralPath (Join-Path $Root "eglantine.exe")) {
        $EmuDir = $Root
    } else {
        Fail "用法: .\install.ps1 -EmuDir `"eglantine.exe 所在文件夹`""
    }
}
$EmuDir = (Resolve-Path -LiteralPath $EmuDir).Path
$exe = Join-Path $EmuDir "eglantine.exe"
if (-not (Test-Path -LiteralPath $exe)) {
    Fail "找不到 eglantine.exe: $exe"
}

$proxy = Join-Path $Root "dist\qwindows.dll"
$rcc = Join-Path $Root "lang\zh_CN.rcc"
if (-not (Test-Path -LiteralPath $proxy)) { Fail "缺少 dist\qwindows.dll" }
if (-not (Test-Path -LiteralPath $rcc)) { Fail "缺少 lang\zh_CN.rcc" }
if ((Get-Item -LiteralPath $proxy).Length -gt 400000) {
    Fail "dist\qwindows.dll 看起来不是本插件。"
}

$real = Join-Path $EmuDir "qwindows_real.dll"
$pluginDirs = @(
    (Join-Path $EmuDir "plugins\platforms"),
    (Join-Path $EmuDir "platforms")
)

foreach ($dir in $pluginDirs) {
    $dll = Join-Path $dir "qwindows.dll"
    if (-not (Test-Path -LiteralPath $dll)) { continue }
    $len = (Get-Item -LiteralPath $dll).Length
    if ($len -gt 400000) {
        if (-not (Test-Path -LiteralPath $real)) {
            Copy-Item -LiteralPath $dll -Destination $real
            Write-Host "已把官方插件备份为 $real"
        }
    }
}

if (-not (Test-Path -LiteralPath $real) -or (Get-Item -LiteralPath $real).Length -lt 400000) {
    Fail "没有找到官方 qwindows.dll。请从原版压缩包恢复 plugins\platforms\qwindows.dll 后再安装。官方文件会备份成模拟器目录下的 qwindows_real.dll，不要把它放回 platforms 目录。"
}

foreach ($dir in $pluginDirs) {
    $existed = Test-Path -LiteralPath $dir
    $dll = Join-Path $dir "qwindows.dll"
    if (-not $existed -and $dir -eq (Join-Path $EmuDir "platforms")) {
        continue
    }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    try {
        Copy-Item -LiteralPath $proxy -Destination $dll -Force
    } catch {
        Fail "无法写入 $dll。请先关闭 Eglantine 再安装。"
    }
    Write-Host "已安装 $dll"
}

$lang = Join-Path $EmuDir "languages"
New-Item -ItemType Directory -Force -Path $lang | Out-Null
Copy-Item -LiteralPath $rcc -Destination (Join-Path $lang "zh_CN.rcc") -Force
Write-Host "已安装 languages\zh_CN.rcc"

function Set-UiLanguage([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $enc = $utf8
    try {
        $text = $utf8.GetString($bytes)
    } catch {
        $enc = [System.Text.Encoding]::GetEncoding(936)
        $text = $enc.GetString($bytes)
    }
    $updated = $text
    if ($updated -match '(?m)^Paths\\language=[^\r\n]*') {
        $updated = [regex]::Replace($updated, '(?m)^Paths\\language=[^\r\n]*', 'Paths\language=zh_CN')
    } else {
        if (-not $updated.EndsWith("`n")) { $updated += "`r`n" }
        $updated += "Paths\language=zh_CN`r`n"
    }
    if ($updated -match '(?m)^Paths\\language\\default=[^\r\n]*') {
        $updated = [regex]::Replace($updated, '(?m)^Paths\\language\\default=[^\r\n]*', 'Paths\language\default=false')
    } else {
        if (-not $updated.EndsWith("`n")) { $updated += "`r`n" }
        $updated += "Paths\language\default=false`r`n"
    }
    if ($updated -eq $text) {
        Write-Host "界面语言已经是简体中文：$path"
        return
    }
    [System.IO.File]::WriteAllBytes($path, $enc.GetBytes($updated))
    Write-Host "已把界面语言设为简体中文：$path"
}

$configs = @(
    (Join-Path $EmuDir "qt-config.ini"),
    (Join-Path $EmuDir "config\qt-config.ini"),
    (Join-Path $EmuDir "user\config\qt-config.ini"),
    (Join-Path $env:APPDATA "eglantine\config\qt-config.ini"),
    (Join-Path $env:APPDATA "eden\config\qt-config.ini")
) | Where-Object { Test-Path -LiteralPath $_ }

if ($configs) {
    foreach ($cfg in $configs) { Set-UiLanguage $cfg }
} else {
    Write-Host "没有找到配置文件。中文 Windows 会按系统语言加载。若界面仍是英文，请把配置中的 Paths\language 设为 zh_CN。"
}

Write-Host "安装完成。重新打开 Eglantine 后，菜单应为中文。游戏语言不会被修改。"
