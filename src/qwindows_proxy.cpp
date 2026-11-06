// SPDX-License-Identifier: GPL-3.0-or-later
// 先加载官方 Qt 平台插件，再把 zh_CN.rcc 注册到 :/languages。
// Qt 6.8 只接受带有只读 .qtmetad 节、且以 “QTMETADATA !” 开头的平台插件。
// 这 127 字节复制自官方 qwindows.dll。

#pragma section(".qtmetadata", read)
#include <windows.h>

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <string>
#include <vector>

static HMODULE g_self = nullptr;
static HMODULE g_real = nullptr;
static std::vector<unsigned char> g_rcc;

#include "qtmeta.inc"

static int be32(const unsigned char* p) {
    return (int)((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
}

static bool module_dir(wchar_t* dir, DWORD cch) {
    if (!g_self && !GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                           GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                       (LPCWSTR)&module_dir, &g_self))
        return false;
    if (!GetModuleFileNameW(g_self, dir, cch))
        return false;
    wchar_t* slash = wcsrchr(dir, L'\\');
    if (!slash)
        return false;
    *slash = 0;
    return true;
}

// 程序可能从 plugins\platforms 或 platforms 加载本插件。
// 从插件所在目录向上查找，直到 languages 和模拟器放在一起。
static bool find_languages_dir(wchar_t* out, DWORD cch) {
    wchar_t dir[MAX_PATH];
    if (!module_dir(dir, MAX_PATH))
        return false;
    for (int i = 0; i < 6; ++i) {
        wchar_t candidate[MAX_PATH];
        if (swprintf_s(candidate, L"%s\\languages", dir) < 0)
            return false;
        DWORD attr = GetFileAttributesW(candidate);
        if (attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY)) {
            wcscpy_s(out, cch, candidate);
            return true;
        }
        wchar_t* slash = wcsrchr(dir, L'\\');
        if (!slash)
            break;
        *slash = 0;
    }
    return false;
}

static void note(const wchar_t* text) {
    wchar_t dir[MAX_PATH];
    if (!find_languages_dir(dir, MAX_PATH))
        return;
    wchar_t path[MAX_PATH];
    if (swprintf_s(path, L"%s\\zh-load.log", dir) < 0)
        return;
    FILE* f = nullptr;
    _wfopen_s(&f, path, L"w, ccs=UTF-8");
    if (!f)
        return;
    fwprintf(f, L"%s\n", text);
    fclose(f);
}

static bool register_chinese() {
    wchar_t dir[MAX_PATH];
    wchar_t path[MAX_PATH];
    if (!find_languages_dir(dir, MAX_PATH)) {
        note(L"没有找到 languages 目录");
        return false;
    }
    if (swprintf_s(path, L"%s\\zh_CN.rcc", dir) < 0)
        return false;

    HANDLE file = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING,
                              FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) {
        note(L"没有找到 zh_CN.rcc");
        return false;
    }
    LARGE_INTEGER size{};
    if (!GetFileSizeEx(file, &size) || size.QuadPart < 20 || size.QuadPart > 64 * 1024 * 1024) {
        CloseHandle(file);
        note(L"zh_CN.rcc 的大小不正确");
        return false;
    }
    g_rcc.resize((size_t)size.QuadPart);
    DWORD got = 0;
    BOOL ok = ReadFile(file, g_rcc.data(), (DWORD)g_rcc.size(), &got, nullptr);
    CloseHandle(file);
    if (!ok || got != g_rcc.size()) {
        note(L"读取 zh_CN.rcc 失败");
        return false;
    }

    const unsigned char* b = g_rcc.data();
    if (b[0] != 'q' || b[1] != 'r' || b[2] != 'e' || b[3] != 's') {
        note(L"zh_CN.rcc 不是有效的 Qt 资源文件");
        return false;
    }
    const int version = be32(b + 4);
    const int tree_off = be32(b + 8);
    const int data_off = be32(b + 12);
    const int name_off = be32(b + 16);
    if (version < 1 || version > 3) {
        note(L"zh_CN.rcc 的版本不受支持");
        return false;
    }
    const int nbytes = (int)g_rcc.size();
    if (tree_off >= nbytes || data_off >= nbytes || name_off >= nbytes) {
        note(L"zh_CN.rcc 的内容已损坏");
        return false;
    }
    if (version >= 3) {
        const int flags = be32(b + 20);
        // 0x01 是 zlib，0x04 是 zstd。本翻译包不压缩。
        if (flags & ~0x01) {
            note(L"zh_CN.rcc 使用了当前程序无法读取的压缩");
            return false;
        }
    }

    HMODULE core = GetModuleHandleW(L"Qt6Core.dll");
    if (!core)
        core = LoadLibraryW(L"Qt6Core.dll");
    if (!core) {
        note(L"没有加载 Qt6Core.dll");
        return false;
    }
    using RegFn = bool (*)(int, const unsigned char*, const unsigned char*, const unsigned char*);
    auto reg = (RegFn)GetProcAddress(core, "?qRegisterResourceData@@YA_NHPEBE00@Z");
    if (!reg) {
        note(L"找不到注册翻译所需的 Qt 函数");
        return false;
    }
    if (!reg(version, b + tree_off, b + name_off, b + data_off)) {
        note(L"注册中文翻译失败");
        return false;
    }
    note(L"已注册界面翻译 :/languages/zh_CN.qm");
    return true;
}

static void ensure_real() {
    if (g_real)
        return;
    if (!g_self) {
        GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           (LPCWSTR)&ensure_real, &g_self);
    }
    wchar_t dir[MAX_PATH];
    wchar_t path[MAX_PATH];
    if (!module_dir(dir, MAX_PATH)) {
        note(L"无法取得插件自身的路径");
        return;
    }
    bool found = false;
    for (int i = 0; i < 6; ++i) {
        if (swprintf_s(path, L"%s\\qwindows_real.dll", dir) > 0 &&
            GetFileAttributesW(path) != INVALID_FILE_ATTRIBUTES) {
            found = true;
            break;
        }
        wchar_t* slash = wcsrchr(dir, L'\\');
        if (!slash)
            break;
        *slash = 0;
    }
    if (!found) {
        note(L"没有找到 qwindows_real.dll");
        return;
    }
    g_real = LoadLibraryW(path);
    if (!g_real) {
        note(L"加载 qwindows_real.dll 失败");
        return;
    }
    if (GetProcAddress(g_real, "eglantine_zh_proxy")) {
        note(L"qwindows_real.dll 是本中文插件，不是官方 Qt 插件");
        FreeLibrary(g_real);
        g_real = nullptr;
        return;
    }
    register_chinese();
}

// Qt 6.8 按值返回这个 16 字节结构。
struct PluginMeta {
    const void* data;
    size_t size;
};
static_assert(sizeof(PluginMeta) == 16, "元数据结构必须是 16 字节");

extern "C" __declspec(dllexport) int eglantine_zh_proxy() {
    return 1;
}

extern "C" __declspec(dllexport) void* qt_plugin_instance() {
    (void)kQtMeta[0];
    ensure_real();
    if (!g_real)
        return nullptr;
    auto fn = (void* (*)())GetProcAddress(g_real, "qt_plugin_instance");
    return fn ? fn() : nullptr;
}

extern "C" __declspec(dllexport) PluginMeta qt_plugin_query_metadata_v2() {
    ensure_real();
    if (!g_real)
        return {nullptr, 0};
    auto fn = (PluginMeta(*)())GetProcAddress(g_real, "qt_plugin_query_metadata_v2");
    if (!fn)
        return {nullptr, 0};
    return fn();
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        g_self = instance;
        DisableThreadLibraryCalls(instance);
    }
    return TRUE;
}
