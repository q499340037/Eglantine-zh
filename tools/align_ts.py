# -*- coding: utf-8 -*-
"""把上游简体中文翻译和某一份 Windows 版 Eglantine 里的原文对齐。

仓库里的 lang/zh_CN.ts 已经对齐过。只有更新后的程序把 Eden 改成了
Eglantine 时才需要重跑。程序里有些菜单原文只有 UTF-16，所以两种编码都查。
"""
import argparse
import xml.etree.ElementTree as ET
from pathlib import Path

FILLS = {
    "GPU Readback Before NCE Invalidation": "NCE 失效前回读 GPU",
    "Flushes GPU buffer data back to guest memory before NCE invalidates the whole guest page, preserving it while the CPU store proceeds.": "在 NCE 使整个客户机页面失效之前，先把 GPU 缓冲区数据刷回客户机内存，这样 CPU 继续写入时这些数据不会丢失。",
    "Patch Runtime NROs for NCE": "为 NCE 修补运行时 NRO",
    "Applies NCE code patches to runtime-loaded NRO modules.This is required for some games to run correctly.": "对运行时加载的 NRO 模块应用 NCE 代码补丁。部分游戏需要开启此项才能正常运行。",
    "Controls the GPU fence synchronization behavior.\nImmediate is the fastest option, but can introduce some issues.\nBalanced offers better compatibility and may fix issues in some games.\nAccurate further improves compatibility at the cost of some performance.\nDefault follows the GPU Mode setting.": "控制 GPU 栅栏的同步方式。\n“立即”最快，但可能引发问题。\n“平衡”兼容性更好，能修复部分游戏的问题。\n“精确”进一步提升兼容性，但会损失一些性能。\n“默认”跟随 GPU 模式设置。",
    "Failed to announce the room to the public lobby. In order to host a room publicly, you must have a valid Eden account configured in Emulation -> Configure -> Web. If you do not want to publish a room in the public lobby, then select Unlisted instead.\nDebug Message: ": "未能把房间公布到公共大厅。若要公开主机，必须先在“模拟 -> 配置 -> 网络”中配置有效的 Eglantine 账号。如果不想出现在公共大厅，请改为选择“私有”。\n调试信息：",
}


def in_exe(blob: bytes, text: str) -> bool:
    return text.encode("utf-8") in blob or text.encode("utf-16le") in blob


def main() -> None:
    class _ChineseHelp(argparse.HelpFormatter):
        def add_usage(self, usage, actions, groups, prefix=None):
            return super().add_usage(usage, actions, groups, prefix="用法：")

    parser = argparse.ArgumentParser(
        description="把上游简体中文翻译和当前程序中的原文对齐。",
        formatter_class=_ChineseHelp,
        add_help=False,
    )
    parser._optionals.title = "参数"
    parser.add_argument("-h", "--help", action="help", help="显示帮助并退出")
    parser.add_argument("--ts", type=Path, required=True, help="上游 zh_CN.ts 的路径")
    parser.add_argument("--exe", type=Path, required=True, help="eglantine.exe 的路径")
    parser.add_argument("--out", type=Path, required=True, help="对齐后的 ts 输出路径")
    args = parser.parse_args()
    blob = args.exe.read_bytes()
    tree = ET.parse(args.ts)
    renamed = kept = missing = filled = branded = 0
    for msg in tree.getroot().iter("message"):
        source = msg.find("source")
        trans = msg.find("translation")
        if source is None or source.text is None:
            continue
        src = source.text
        if "Eden" in src:
            alt = src.replace("Eden", "Eglantine")
            if in_exe(blob, alt) and not in_exe(blob, src):
                source.text = alt
                src = alt
                renamed += 1
            elif in_exe(blob, src):
                kept += 1
            else:
                missing += 1
        if trans is None:
            continue
        if src in FILLS:
            trans.text = FILLS[src]
            trans.attrib.pop("type", None)
            for child in list(trans):
                trans.remove(child)
            filled += 1
        if trans.text and "Eden" in trans.text:
            trans.text = trans.text.replace("Eden", "Eglantine")
            branded += 1
        for child in trans.iter():
            if child is trans:
                continue
            if child.text and "Eden" in child.text:
                child.text = child.text.replace("Eden", "Eglantine")
                branded += 1
            if child.tail and "Eden" in child.tail:
                child.tail = child.tail.replace("Eden", "Eglantine")
                branded += 1
    tree.write(args.out, encoding="utf-8", xml_declaration=True)
    print(
        f"已改名 {renamed} 条，保留 {kept} 条，程序中未找到 {missing} 条，"
        f"补译 {filled} 条，产品名替换 {branded} 处"
    )


if __name__ == "__main__":
    main()
