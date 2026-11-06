# Mi 10T Pro Optimizer (apollo)

[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-brightgreen.svg)](#)
[![Magisk](https://img.shields.io/badge/Magisk-Supported-blue.svg)](#)
[![Device](https://img.shields.io/badge/Device-Xiaomi%20Mi%2010T%20Pro%20(apollo)-orange.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

Mô-đun tối ưu hóa chuyên sâu dành riêng cho **Xiaomi Mi 10T Pro (apollo)**, hỗ trợ cả **KernelSU** và **Magisk**.

Mô-đun được thiết kế với triết lý: **Hiệu năng tối đa - 0% chạy ngầm - Không hao pin**.

---

## ⚡ Tính năng chính

### 1. 🚀 Tối ưu Kernel & I/O UFS 3.1
* **TCP Congestion Control (BBR)**: Tự động kích hoạt thuật toán BBR (Google Bottleneck Bandwidth and RTT) nếu kernel hỗ trợ, giúp giảm độ trễ (ping) và tăng tốc mạng Wi-Fi/4G/5G.
* **VFS Cache Pressure**: Thiết lập giá trị `80` giúp cân bằng việc thu hồi inode/dentry cache trong RAM mà không gây giật lag khi chuyển đổi ứng dụng.
* **UFS 3.1 Buffer Tuning**: Tăng bộ đệm `read_ahead_kb` lên **512 KB** trên toàn bộ phân vùng bộ nhớ flash, tối ưu `rq_affinity` và tắt overhead thống kê I/O không cần thiết, giúp tốc độ đọc/ghi dữ liệu tuần hoàn và ngẫu nhiên mượt hơn.

### 2. 🛡️ Debloat dịch vụ rác MIUI / HyperOS
Tự động quét và vô hiệu hóa an toàn các dịch vụ theo dõi/quảng cáo chạy ngầm của Xiaomi thông qua `pm disable-user`:
* `com.miui.analytics` (Thu thập dữ liệu phân tích)
* `com.miui.daemon` (Dịch vụ theo dõi ngầm)
* `com.miui.yellowpage` (Trang vàng)
* `com.miui.hybrid` & `com.miui.hybrid.accessory` (Quick Apps)
* `com.xiaomi.discover` (Xiaomi App Mall / gợi ý ứng dụng)
* `com.miui.bugreport` (Báo cáo lỗi tự động gửi về máy chủ)
* `com.xiaomi.joyose` (Dịch vụ bóp hiệu năng và theo dõi trò chơi)

### 3. ⚡ Smart DEX Compile (AOT Compilation)
* Tự động phát hiện các ứng dụng mới được cài đặt bởi người dùng.
* Thực hiện biên dịch AOT (`cmd package compile -m speed-profile`) để tối ưu hóa mã bytecode của ứng dụng.
* Ghi nhớ các ứng dụng đã biên dịch vào `optimized_apps.txt`, đảm bảo không biên dịch lặp lại gây hao pin hay nóng máy.

### 4. 🌿 Tiêu thụ tài nguyên tối giản
* Chạy đúng **1 lần duy nhất** khi thiết bị hoàn tất khởi động (`sys.boot_completed=1`).
* Tự động thoát hoàn toàn (`exit 0`).
* **Cam kết**: 0% CPU, 0 MB RAM chạy ngầm liên tục.

---

## 📦 Cấu trúc thư mục

```text
miuiopti/
├── META-INF/
│   └── com/google/android/
│       ├── update-binary         # Script cài đặt flashable
│       └── updater-script        # Khai báo định dạng cài đặt
├── system/
│   └── bin/
│       └── mi-opt                # Lệnh chạy nhanh trong Terminal / Termux
├── action.sh                     # Script xử lý nút Action trên app KernelSU
├── module.prop                   # Khai báo thông tin mô-đun
├── optimizer.sh                  # Logic tối ưu cốt lõi
├── service.sh                    # Kịch bản khởi chạy tự động sau khi boot
├── Mi10T_Pro_Optimizer_v1.0.zip  # File zip đóng gói sẵn sàng flash
└── README.md
```

---

## 🛠️ Hướng dẫn cài đặt

### Cách 1: Flash qua KernelSU / Magisk App
1. Tải về file [`Mi10T_Pro_Optimizer_v1.0.zip`](./Mi10T_Pro_Optimizer_v1.0.zip).
2. Mở ứng dụng **KernelSU** (hoặc **Magisk**).
3. Vào mục **Mô-đun** (*Modules*) > Chọn **Cài đặt từ bộ nhớ** (*Install from storage*).
4. Chọn file zip vừa tải và hoàn tất cài đặt.
5. Khởi động lại máy.

---

## 🧪 Cách kích hoạt & kiểm tra thủ công

### 1. Dùng nút Action trên KernelSU (Tiện lợi nhất)
1. Mở ứng dụng **KernelSU** > Tab **Mô-đun**.
2. Tìm mô-đun **Mi 10T Pro Optimizer**.
3. Bấm vào nút **Action** (biểu tượng thao tác / tia sét).
4. Màn hình sẽ hiển thị trực quan tiến trình quét và tối ưu chỉ trong 1-2 giây:
   ```text
   ======================================
       MI 10T PRO OPTIMIZER (APOLLO)     
   ======================================
   --> Đang quét bloatware Xiaomi...
     [OK] Không có dịch vụ rác nào đang hoạt động.
   --> Đang tối ưu Kernel & UFS...
     [OK] TCP Congestion: bbr
     [OK] VFS Cache Pressure: 80
     [OK] UFS 3.1: Đã tăng bộ đệm 512KB trên 6 phân vùng.
   --> Đang quét ứng dụng cần tối ưu (Smart DEX)...
     [OK] Tất cả ứng dụng đã được tối ưu từ trước.
   --> Đã dọn bộ đệm RAM.
   ======================================
    [OK] QUÉT & TỐI ƯU HOÀN TẤT!         
   ======================================
   ```

### 2. Dùng dòng lệnh trong Termux
Mở Termux và chạy:
```bash
su
mi-opt
```

### 3. Xem lịch sử hoạt động (Log file)
Toàn bộ lịch sử các lần tối ưu đều được ghi lại tại:
```bash
cat /data/adb/modules/mi10t_optimizer/optimizer.log
```
