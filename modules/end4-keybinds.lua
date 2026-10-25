hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })

-- Display configuration tool
hl.bind("SUPER + P", hl.dsp.exec_cmd("nwg-displays"), { description = "Utilities: Configure displays" })

-- macOS-style window controls: minimize và maximize/fullscreen toggle
-- Minimize: ẩn cửa sổ vào special workspace (giống Cmd+M trên macOS)
hl.bind("SUPER + M", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace special:minimized"), { description = "Window: Minimize (hide to special workspace)" })
-- Toggle minimize: hiển thị/ẩn tất cả cửa sổ đã minimize
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace minimized"), { description = "Window: Show/hide minimized windows" })

-- Maximize/Fullscreen toggle (giống Cmd+Ctrl+F trên macOS hoặc nút xanh trên titlebar)
-- fullscreen 1 = maximize (giữ panel và gaps), fullscreen 0 = thực sự toàn màn hình
hl.bind("SUPER + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"), { description = "Window: Toggle maximize (keep panel)" })
-- Fullscreen thực sự (ẩn cả panel, gaps)
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 0"), { description = "Window: Toggle real fullscreen (hide all)" })

-- Floating window toggle
hl.bind("SUPER + SHIFT + Space", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"), { description = "Window: Toggle floating mode" })

-- Preserve the workspace shortcuts used in the previous desktop workflow.
hl.bind("CTRL + ALT + Left", hl.dsp.focus({ workspace = "r-1" }), { description = "Workspace: Previous" })
hl.bind("CTRL + ALT + Right", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspace: Next" })
hl.bind("CTRL + Grave", hl.dsp.focus({ workspace = "previous" }), { description = "Workspace: Last used" })

-- Reliable capture shortcuts that do not depend on Quickshell IPC. Remove the
-- upstream bindings first so one key press never launches multiple tools.
hl.unbind("Print")
hl.unbind("CTRL + Print")
hl.unbind("SUPER + SHIFT + S")
hl.unbind("SUPER + SHIFT + R")
hl.unbind("CTRL + ALT + R")

hl.bind("Print", hl.dsp.exec_cmd("end4-screenshot region"),
    { locked = true, description = "Utilities: Select region screenshot" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd("end4-screenshot output"),
    { locked = true, description = "Utilities: Screenshot active monitor" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("end4-screen-record region"),
    { locked = true, description = "Utilities: Start/stop region recording" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("end4-screen-record output"),
    { locked = true, description = "Utilities: Start/stop monitor recording" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("end4-screenshot region"),
    { locked = true, description = "Utilities: Select region screenshot" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("end4-screen-record region"),
    { locked = true, description = "Utilities: Start/stop region recording" })
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("end4-screen-record output"),
    { locked = true, description = "Utilities: Start/stop monitor recording" })
