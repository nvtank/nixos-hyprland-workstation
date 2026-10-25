# macOS-style Window Controls

Các phím tắt điều khiển cửa sổ giống macOS đã được thêm vào Hyprland config.

## Phím tắt mới

| Phím tắt | Chức năng | Tương tự macOS |
|----------|-----------|----------------|
| `Super + M` | **Minimize** - Ẩn cửa sổ hiện tại vào special workspace | `Cmd + M` |
| `Super + Shift + M` | **Show minimized** - Hiển thị/ẩn tất cả cửa sổ đã minimize | Nút Dock |
| `Super + F` | **Maximize** - Toàn màn hình (giữ panel) | `Cmd + Ctrl + F` hoặc nút xanh |
| `Super + Shift + F` | **Real Fullscreen** - Toàn màn hình thực sự (ẩn panel) | Fullscreen apps |
| `Super + Shift + Space` | **Toggle floating** - Chuyển đổi chế độ cửa sổ nổi | - |

## Cách hoạt động

### Minimize (`Super + M`)
- Ẩn cửa sổ hiện tại vào một workspace đặc biệt tên là "minimized"
- Cửa sổ vẫn đang chạy nhưng không hiển thị trên màn hình
- Hoạt động với mọi ứng dụng: Firefox, Files, Notes, Terminal, ...

### Show Minimized (`Super + Shift + M`)
- Hiển thị overlay chứa tất cả cửa sổ đã minimize
- Nhấn lại để ẩn overlay
- Click vào cửa sổ để khôi phục về workspace chính

### Maximize (`Super + F`)
- Phóng to cửa sổ toàn màn hình nhưng vẫn giữ panel/bar ở trên
- Giữ gaps (khoảng trống) giữa các cửa sổ
- Nhấn lại để về kích thước bình thường
- Tương tự nút màu xanh trên titlebar macOS

### Real Fullscreen (`Super + Shift + F`)
- Toàn màn hình thực sự, ẩn cả panel và gaps
- Thích hợp cho xem video, presentations
- Nhấn lại để thoát

## Cài đặt

```bash
cd /etc/nixos

# Build và kiểm tra
nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link

# Test trước
sudo nixos-rebuild test --flake path:/etc/nixos#nixos

# Nếu OK, apply vĩnh viễn
sudo nixos-rebuild switch --flake path:/etc/nixos#nixos

# Chạy end4-setup để cập nhật config
end4-setup

# Log out và đăng nhập lại Hyprland
```

## Kiểm tra

Sau khi đăng nhập lại:

1. Mở Firefox: `Super + Enter` → gõ "firefox"
2. Test minimize: `Super + M` (Firefox biến mất)
3. Test show minimized: `Super + Shift + M` (thấy Firefox trong overlay)
4. Click vào Firefox để khôi phục
5. Test maximize: `Super + F` (Firefox toàn màn hình nhưng còn panel)
6. Test lại: `Super + F` (về kích thước bình thường)

## Lưu ý

- Các phím tắt này hoạt động với **tất cả ứng dụng** trên Hyprland
- Không cần cấu hình riêng cho từng app
- Special workspace "minimized" tự động được tạo khi minimize lần đầu
- Cửa sổ minimize vẫn chạy background, không bị đóng
