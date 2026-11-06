# Xiaomi HyperOS & MIUI Optimizer

[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-brightgreen.svg)](#)
[![Magisk](https://img.shields.io/badge/Magisk-Supported-blue.svg)](#)
[![APatch](https://img.shields.io/badge/APatch-Supported-purple.svg)](#)
[![Device](https://img.shields.io/badge/Device-Universal%20Xiaomi-orange.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

Mô-đun tối ưu hóa chuyên sâu tự động nhận diện thiết bị dành riêng cho các dòng máy **Xiaomi / Redmi / POCO** chạy MIUI hoặc HyperOS (đã kiểm thử và tối ưu trên **Mi 10T Pro**, **Redmi K30 5G**,...).

Mô-đun tương thích hoàn hảo với **KernelSU**, **Magisk** và **APatch**.

---

## ⚡ Tính năng phiên bản v1.1.0

### 1. 🚀 Tối ưu I/O UFS & Bộ nhớ (RAM)
* **Tự động chuyển I/O Scheduler sang `noop`**: Loại bỏ overhead xếp hàng của CFQ (thuật toán dành cho ổ đĩa quay HDD), tối ưu riêng cho chip nhớ flash UFS 2.1 / 3.1 giúp đọc ghi dữ liệu nhanh và giảm tải CPU.
* **Tăng bộ đệm UFS `read_ahead_kb`**: Nâng lên **512 KB** trên toàn bộ phân vùng `sd*`.
* **Cân bằng Swappiness (`60`)**: Giảm gánh nặng nén dữ liệu vào ZRAM liên tục, ưu tiên giữ ứng dụng trong RAM thực giúp đa nhiệm mượt mà, hạn chế khựng lag trên các máy 6GB/8GB RAM.
* **VFS Cache Pressure (`80`)**: Tối ưu tốc độ giải phóng inode/dentry cache trong RAM.

### 2. 🌐 Tối ưu mạng & Giảm độ trễ
* **TCP Fast Open (`3`)**: Kích hoạt gửi dữ liệu ngay trong gói bắt tay SYN cho cả chiều Client và Server, giúp tải trang web và ứng dụng mạng nhanh hơn 1 chu kỳ RTT.
* **TCP Congestion Control (BBR / Cubic)**: Tự động kích hoạt thuật toán BBR nếu kernel hỗ trợ, hoặc giữ tối ưu Cubic.

### 3. 🛡️ Tắt dịch vụ ngầm & Debloat an toàn
* **Tắt tính năng ghi vết nền (`persist.traced.enable 0`)**: Vô hiệu hóa tiến trình `traced` và `traced_probes` chạy ngầm ngốn RAM và chu kỳ CPU.
* **Khóa dịch vụ theo dõi / bóp hiệu năng Xiaomi qua `pm disable-user`**:
  * `com.miui.daemon` (Dịch vụ theo dõi ngầm)
  * `com.xiaomi.joyose` (Dịch vụ bóp hiệu năng khi chơi game / tác vụ nặng)
  * `com.miui.analytics`, `com.miui.yellowpage`, `com.miui.bugreport`,...

### 4. ⚡ Smart DEX Compile (AOT Compilation)
* Quét và tự động phát hiện ứng dụng mới cài đặt từ người dùng.
* Thực hiện biên dịch AOT (`cmd package compile -m speed-profile`) để tối ưu mã thực thi bytecode.
* Ghi nhớ các ứng dụng đã biên dịch vào `optimized_apps.txt`, đảm bảo không biên dịch lặp lại.

### 5. ⏱️ Cơ chế hiển thị Action trực quan (10s Delay)
* Tự động nhận diện tên model và codename thiết bị (ví dụ: `Redmi K30 5G (picasso)` hoặc `Mi 10T Pro (apollo)`).
* Sau khi quét và tối ưu hoàn tất, cửa sổ Action sẽ **tạm dừng 10 giây** để người dùng thoải mái đọc toàn bộ kết quả báo cáo trên màn hình trước khi đóng.

### 6. 🌿 Cam kết tài nguyên: 0% CPU & 0 MB RAM ngầm
* Script `service.sh` chạy 1 lần duy nhất sau khi máy hoàn tất khởi động (`sys.boot_completed=1`) rồi tự động thoát hẳn (`exit 0`).

---

## 📦 Cấu trúc thư mục

```text
miuiopti/
├── META-INF/
│   └── com/google/android/
│       ├── update-binary            # Script cài đặt flashable
│       └── updater-script           # Khai báo định dạng cài đặt
├── system/
│   └── bin/
│       └── mi-opt                   # Lệnh chạy nhanh trong Terminal / Termux
├── action.sh                        # Script giao diện nút Action (kèm giữ màn hình 10s)
├── module.prop                      # Khai báo thông tin mô-đun
├── optimizer.sh                     # Logic tối ưu cốt lõi
├── service.sh                       # Kịch bản khởi chạy tự động sau khi boot
├── Xiaomi_Optimizer_v1.1.zip        # File zip flashable phiên bản v1.1.0
├── Mi10T_Pro_Optimizer_v1.0.zip     # File zip tương thích
└── README.md
```

---

## 🛠️ Hướng dẫn cài đặt / Flash lại

1. Tải về file [`Xiaomi_Optimizer_v1.1.zip`](./Xiaomi_Optimizer_v1.1.zip) (hoặc lấy tại thư mục `/sdcard/Download/Xiaomi_Optimizer_v1.1.zip` trên điện thoại).
2. Mở ứng dụng **KernelSU** / **Magisk** / **APatch**.
3. Vào tab **Mô-đun** (*Modules*) > Chọn **Cài đặt từ bộ nhớ** (*Install from storage*).
4. Chọn file zip vừa tải và flash đè lên bản cũ.
5. Khởi động lại máy.

---

## 🧪 Cách kích hoạt & kiểm tra thủ công

### 1. Dùng nút Action
* Mở KernelSU / APatch > Tab **Mô-đun** > Bấm **Action** bên cạnh mô-đun.
* Màn hình sẽ hiển thị kết quả và **giữ lại trong 10 giây** để bạn dễ dàng theo dõi.

### 2. Dùng dòng lệnh Termux
```bash
su
mi-opt
```
