# -*- coding: utf-8 -*-
"""Align an upstream Eglantine zh_CN.ts file with one Windows build.

The shipped lang/zh_CN.ts is already aligned. Run this only when a newer
emulator renames Eden strings to Eglantine. Strings are matched as UTF-8 or
UTF-16LE, because several menu strings exist only as UTF-16 in the binary.
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
    parser = argparse.ArgumentParser()
    parser.add_argument("--ts", type=Path, required=True)
    parser.add_argument("--exe", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
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
    print(f"renamed={renamed} kept={kept} missing={missing} filled={filled} branded={branded}")


if __name__ == "__main__":
    main()
