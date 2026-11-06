# Eglantine-zh

给 Windows 版 [Eglantine](https://github.com/Djihads80/Eglantine) 用的简体中文界面插件。把它装进自己的模拟器目录，菜单和设置会变成中文。这里不包含模拟器、游戏、密钥或固件。

官方仓库的 `dist/languages/zh_CN.ts` 已经有简体中文，但这份 Windows 构建没有把翻译打进程序。插件在启动时注册 `:/languages/zh_CN.qm`，模拟器自己的加载逻辑就能读到它。

已在 **Eglantine e85c099005-nx2、Qt 6.8.3、MSVC 19.44** 上验证。菜单显示为：文件、模拟、视图、工具、多人游戏、帮助。

## 安装

关闭 Eglantine，在本仓库目录打开终端：

```bat
install.bat -EmuDir "D:\你的模拟器目录"
```

目录里要有 `eglantine.exe`。脚本会：

1. 把官方 `plugins\platforms\qwindows.dll` 备份为模拟器目录下的 `qwindows_real.dll`
2. 用本插件替换 `plugins\platforms\qwindows.dll`；如果还存在 `platforms\qwindows.dll`，同样替换
3. 复制 `languages\zh_CN.rcc`
4. 把已有配置里的界面语言设为 `zh_CN`

然后重新打开模拟器。`languages\zh-load.log` 里应有一行 `registered :/languages/zh_CN.qm`。

`qwindows_real.dll` 必须放在 `eglantine.exe` 旁边，不能留在 `platforms` 目录里。否则 Qt 会直接加载官方插件，中文不会出现。

手动安装时，配置文件通常在 `%APPDATA%\eden\config\qt-config.ini`。只改这两行：

```ini
Paths\language\default=false
Paths\language=zh_CN
```

不要改 `language_index`。那是游戏语言，不是界面语言。

## 卸载

```bat
uninstall.bat -EmuDir "D:\你的模拟器目录"
```

官方插件会从 `qwindows_real.dll` 写回去，界面语言改回 `en`。

## 仍然是英文的文字

滤镜和后端名称保持原文：FX、FXAA、SCALEFORCE、HANDHELD、ACCURATE、VULKAN。部分状态文字（例如 Directory、Not scanned）和窗口标题里的产品名 Eglantine 也保持英文。没有附带 Qt 自带对话框的 qtbase 翻译，所以个别系统按钮仍是 OK / Cancel。这个插件只翻译模拟器界面，不翻译游戏内文字。

## 自己编译

`dist\qwindows.dll` 和 `lang\zh_CN.rcc` 可以直接使用。要重新编译插件，安装带 MSVC 的 Visual Studio 后运行 `build.bat`。

要重新生成翻译包，用 Qt 6 的工具，并且不要压缩资源。这份 Windows 构建读不了 zstd 压缩的 rcc：

```bat
lrelease lang\zh_CN.ts -qm lang\zh_CN.qm
rcc -binary -no-compress --no-zstd lang\zh_CN.qrc -o lang\zh_CN.rcc
```

`lang\zh_CN.ts` 基于 Eglantine `nx2` 分支的 `dist/languages/zh_CN.ts`。程序把一部分 “Eden” 改成了 “Eglantine” 之后，原文对不上的条目已按这个构建调整。更新的构建可以用：

```bat
python tools\align_ts.py --ts 上游zh_CN.ts --exe eglantine.exe --out lang\zh_CN.ts
```

## 原理

Qt 6.8 在真正加载平台插件之前，会检查 DLL 里只读的 `.qtmetad` 节是否以 `QTMETADATA !` 开头。本插件带有从官方 `qwindows.dll` 复制的 127 字节元数据，所以能被接受。加载后它转调旁边的 `qwindows_real.dll`，并调用 `qRegisterResourceData` 注册中文翻译。注册发生在界面读取语言之前。失败时仍会加载官方插件，界面保持英文。

## 许可

GPL-3.0。详见 [LICENSE](LICENSE)。

- `src/qwindows_proxy.cpp`：本仓库编写
- `lang/zh_CN.ts`：派生自 Eglantine / Eden 的翻译，原翻译由 Transifex 上的贡献者维护
- `src/qtmeta.inc`：Qt Windows 平台插件的元数据，Qt 以 LGPL / GPL 提供
