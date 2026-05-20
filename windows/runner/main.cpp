#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <algorithm>
#include <cstdint>

// Compatibility stubs for MSVC STL internal symbols to resolve Firebase linking issues
extern "C" unsigned int _Avx2WmemEnabled = 0;

extern "C" _Thrd_result __stdcall _Cnd_timedwait_for_unchecked(_Cnd_t cnd, _Mtx_t mtx, unsigned int ms) noexcept {
    static _Thrd_result(__stdcall *func)(_Cnd_t, _Mtx_t, unsigned int) noexcept = nullptr;
    if (!func) {
        HMODULE hMod = GetModuleHandleA("msvcp140.dll");
        if (!hMod) hMod = LoadLibraryA("msvcp140.dll");
        if (hMod) {
            func = reinterpret_cast<decltype(func)>(GetProcAddress(hMod, "_Cnd_timedwait_for_unchecked"));
        }
    }
    if (func) {
        return func(cnd, mtx, ms);
    }
    return static_cast<_Thrd_result>(0);
}

extern "C" const void* __stdcall __std_find_end_1(
    const void* _First1, 
    const void* _Last1, 
    const void* _First2, 
    size_t _Count2
) noexcept {
    const char* f1 = static_cast<const char*>(_First1);
    const char* l1 = static_cast<const char*>(_Last1);
    const char* f2 = static_cast<const char*>(_First2);
    const char* l2 = f2 + _Count2;
    if (_Count2 == 0) return _Last1;
    const char* result = nullptr;
    while (true) {
        const char* current = std::search(f1, l1, f2, l2);
        if (current == l1) break;
        result = current;
        f1 = current + 1;
    }
    return result ? result : l1;
}

extern "C" const void* __stdcall __std_search_1(
    const void* _First1, 
    const void* _Last1, 
    const void* _First2, 
    size_t _Count2
) noexcept {
    const char* f1 = static_cast<const char*>(_First1);
    const char* l1 = static_cast<const char*>(_Last1);
    const char* f2 = static_cast<const char*>(_First2);
    const char* l2 = f2 + _Count2;
    return std::search(f1, l1, f2, l2);
}

extern "C" void* __stdcall __std_remove_8(void* _First, void* _Last, uint64_t _Val) noexcept {
    uint64_t* f = static_cast<uint64_t*>(_First);
    uint64_t* l = static_cast<uint64_t*>(_Last);
    return std::remove(f, l, _Val);
}

extern "C" size_t __stdcall __std_find_first_of_trivial_pos_1(
    const void* _First1, 
    size_t _Size1, 
    const void* _First2, 
    size_t _Size2
) noexcept {
    const char* f1 = static_cast<const char*>(_First1);
    const char* f2 = static_cast<const char*>(_First2);
    for (size_t i = 0; i < _Size1; ++i) {
        for (size_t j = 0; j < _Size2; ++j) {
            if (f1[i] == f2[j]) {
                return i;
            }
        }
    }
    return static_cast<size_t>(-1);
}

extern "C" size_t __stdcall __std_find_last_of_trivial_pos_1(
    const void* _First1, 
    size_t _Size1, 
    const void* _First2, 
    size_t _Size2
) noexcept {
    const char* f1 = static_cast<const char*>(_First1);
    const char* f2 = static_cast<const char*>(_First2);
    for (size_t i = _Size1; i > 0; --i) {
        size_t idx = i - 1;
        for (size_t j = 0; j < _Size2; ++j) {
            if (f1[idx] == f2[j]) {
                return idx;
            }
        }
    }
    return static_cast<size_t>(-1);
}

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"sehir_bulmaca", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
