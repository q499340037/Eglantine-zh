# Eglantine-zh

这是给 Windows 版 [Eglantine](https://github.com/Djihads80/Eglantine) 准备的中文汉化插件。

## 安装

先关闭 Eglantine，再在本仓库目录打开终端：

```bat
install.bat -EmuDir "D:\你的模拟器目录"
```

目录里要有 `eglantine.exe`。脚本会：

1. 把官方 `plugins\platforms\qwindows.dll` 备份为模拟器目录下的 `qwindows_real.dll`
2. 用本插件替换 `plugins\platforms\qwindows.dll`；如果还存在 `platforms\qwindows.dll`，同样替换
3. 复制 `languages\zh_CN.rcc`
4. 把已有配置里的界面语言设为简体中文

然后重新打开模拟器。`languages\zh-load.log` 里应有一行：已注册界面翻译。

`qwindows_real.dll` 必须放在 `eglantine.exe` 旁边，不能留在 `platforms` 目录里。否则程序会直接加载官方插件，中文不会出现。

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

官方插件会从 `qwindows_real.dll` 写回去，界面语言改回英文。

## 仍然是英文的文字

滤镜和后端名称保持原文：FX、FXAA、SCALEFORCE、HANDHELD、ACCURATE、VULKAN。部分状态文字（例如 Directory、Not scanned）和窗口标题里的产品名 Eglantine 也保持英文。没有附带 Qt 自带对话框的翻译，所以个别系统按钮仍是确定和取消的英文。这个插件只翻译模拟器界面，不翻译游戏内文字。

## 自己编译

`dist\qwindows.dll` 和 `lang\zh_CN.rcc` 可以直接使用。要重新编译插件，先安装带微软编译器的 Visual Studio，再运行 `build.bat`。

要重新生成翻译包，使用 Qt 6 的工具，并且不要压缩资源。这份 Windows 构建读不了 zstd 压缩的资源包：

```bat
lrelease lang\zh_CN.ts -qm lang\zh_CN.qm
rcc -binary -no-compress --no-zstd lang\zh_CN.qrc -o lang\zh_CN.rcc
```

`lang\zh_CN.ts` 基于 Eglantine `nx2` 分支的 `dist/languages/zh_CN.ts`。程序把一部分 “Eden” 改成了 “Eglantine” 之后，原文对不上的条目已按这个构建调整。换了更新的程序后，可以运行：

```bat
python tools\align_ts.py --ts 上游的zh_CN.ts --exe eglantine.exe --out lang\zh_CN.ts
```


## 许可

GNU 通用公共许可证第 3 版（GPL-3.0）。全文见 [LICENSE](LICENSE)。

- `src/qwindows_proxy.cpp`：本仓库编写
- `lang/zh_CN.ts`：派生自 Eglantine / Eden 的翻译，原翻译由 Transifex 上的贡献者维护
- `src/qtmeta.inc`：Qt Windows 平台插件的元数据。Qt 以 GNU 宽通用公共许可证（LGPL）和 GNU 通用公共许可证（GPL）提供
