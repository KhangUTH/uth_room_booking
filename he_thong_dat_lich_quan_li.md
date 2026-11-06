# TÀI LIỆU MÔ TẢ HỆ THỐNG ĐĂNG KÝ SỬ DỤNG PHÒNG MÁY VÀ THIẾT BỊ

## 1. Tổng quan hệ thống
Hệ thống được thiết kế nhằm mục đích số hóa và tối ưu hóa quy trình quản lý, đăng ký sử dụng phòng máy và thiết bị tại cơ sở giáo dục. Ứng dụng Flutter trong dự án này chỉ phục vụ 3 nhóm người dùng: Sinh viên, Giảng viên và Nhân viên kỹ thuật. Quản trị viên (Admin) sử dụng web quản trị riêng.

App và web quản trị dự kiến dùng chung backend Supabase: app gửi đăng ký/báo sự cố, web xử lý duyệt/phân công, app nhận trạng thái và lịch công việc. Mã nguồn web quản trị thuộc dự án riêng, chưa được triển khai trong repository này. Thư mục nền tảng `web/` của Flutter là cấu hình chạy cùng ứng dụng trên trình duyệt, không phải web quản trị admin.

### Công nghệ sử dụng:
*   **Frontend (App cho 3 vai trò):** Flutter, ngôn ngữ Dart.
*   **Web quản trị Admin:** Ứng dụng riêng; công nghệ triển khai chưa được xác định trong dự án này.
*   **Backend (BaaS):** Supabase (PostgreSQL Database, Authentication, Storage, Realtime Database).
*   **State Management đề xuất:** Riverpod hoặc BLoC.
*   **Routing đề xuất:** GoRouter.

---

## 2. Phân hệ chức năng theo vai trò và phạm vi nền tảng

### 2.1. Vai trò Sinh viên
Nhóm người dùng có nhu cầu mượn thiết bị và sử dụng phòng máy cho mục đích học tập cá nhân hoặc nhóm.
*   **1.1.** Đăng nhập, Đăng xuất (Authentication).
*   **1.2.** Quản lý thông tin cá nhân (Cập nhật profile, đổi mật khẩu).
*   **1.3.** Xem danh sách thiết bị (Tìm kiếm, xem tình trạng thiết bị).
*   **1.4.** Đăng ký sử dụng (Tạo form đăng ký mượn thiết bị/chỗ ngồi phòng máy).
*   **1.5.** Xem lịch sử đăng ký.
*   **1.6.** Xem lịch sử sử dụng máy.
*   **1.7.** Theo dõi/Hủy yêu cầu (Xem trạng thái chờ duyệt, đã duyệt, hoặc hủy form nếu chưa được xử lý).
*   **1.8.** Báo cáo sự cố (Gửi báo cáo lỗi thiết bị/phòng máy kèm hình ảnh).

### 2.2. Vai trò Giảng viên
Nhóm người dùng có quyền hạn cao hơn sinh viên, thường mượn phòng cho lớp học hoặc thiết bị phục vụ giảng dạy.
*   **2.1.** Đăng nhập, Đăng xuất.
*   **2.2.** Quản lý thông tin cá nhân.
*   **2.3.** Xem danh sách phòng máy (Xem chi tiết cấu hình, sức chứa).
*   **2.4.** Xem danh sách thiết bị.
*   **2.5.** Xem lịch phòng (Xem thời khóa biểu, lịch trống của các phòng máy).
*   **2.6.** Đăng ký sử dụng (Đặt phòng máy, mượn thiết bị).
*   **2.7.** Xem lịch sử đăng ký.
*   **2.8.** Theo dõi/Hủy yêu cầu.
*   **2.9.** Báo cáo sự cố.

### 2.3. Vai trò Nhân viên kỹ thuật
Nhóm chịu trách nhiệm bảo trì, sửa chữa thiết bị và phòng máy.
*   **3.1.** Đăng nhập, Đăng xuất.
*   **3.2.** Quản lý thông tin cá nhân.
*   **3.3.** Xem phòng/thiết bị được phân công (Quản lý các tài sản thuộc phạm vi phụ trách).
*   **3.4.** Tiếp nhận sự cố (Nhận thông báo lỗi từ Sinh viên/Giảng viên/Hệ thống).
*   **3.5.** Cập nhật tiến độ xử lý (Đổi trạng thái: Đang xử lý, Đã sửa xong,...).
*   **3.6.** Ghi nhận sửa chữa (Lưu lại log các thành phần đã thay thế hoặc sửa chữa).
*   **3.7.** Đề xuất bảo trì (Gửi yêu cầu để Admin duyệt trên web quản trị).

### 2.4. Web quản trị riêng — Vai trò Admin
Các chức năng dưới đây thuộc web quản trị riêng, không triển khai trong ứng dụng Flutter này. Admin điều hành hệ thống qua backend dùng chung.
*   **4.1.** Đăng nhập, Đăng xuất.
*   **4.2.** Quản lý tài khoản, phân quyền (Tạo mới, khóa, cấp quyền cho các user).
*   **4.3.** Quản lý phòng máy/thiết bị (Thêm, sửa, xóa, nhập kho thiết bị/phòng máy).
*   **4.4.** Duyệt/từ chối đăng ký (Xử lý các yêu cầu mượn phòng/thiết bị từ GV và SV).
*   **4.5.** Phân công kỹ thuật (Giao việc sửa chữa, bảo trì cho từng nhân viên kỹ thuật).
*   **4.6.** Quản lý sự cố (Giám sát toàn bộ các ticket sự cố trong hệ thống).
*   **4.7.** Thống kê, báo cáo (Xuất dữ liệu sử dụng, tần suất hỏng hóc, báo cáo tổng quan).

---

## 3. Cấu trúc thư mục dự án app Flutter (3 vai trò)

### 3.1. Cấu trúc hiện tại đã kiểm tra

Dự án đang tổ chức giao diện theo tính năng, sử dụng `StatefulWidget`/`setState` và `Navigator` để quản lý trạng thái, chuyển trang. Chưa tích hợp Riverpod, BLoC, GoRouter hoặc Supabase trong `pubspec.yaml`. Các công nghệ ở mục 1 là định hướng triển khai, chưa phải toàn bộ công nghệ đang sử dụng.

```text
uth_room_booking/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   ├── errors/
│   │   ├── network/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── presentation/
│   │   │   │   └── login_page.dart
│   │   │   └── widgets/
│   │   ├── booking/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── presentation/
│   │   │   └── widgets/
│   │   ├── equipment/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   │   └── sample_devices.dart
│   │   │   ├── models/
│   │   │   │   └── device.dart
│   │   │   ├── presentation/
│   │   │   │   └── device_list_page.dart
│   │   │   └── widgets/
│   │   ├── incident_report/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── presentation/
│   │   │   └── widgets/
│   │   ├── profile/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── presentation/
│   │   │   │   └── profile_page.dart
│   │   │   └── widgets/
│   │   ├── room/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   │   └── sample_rooms.dart
│   │   │   ├── models/
│   │   │   │   └── room.dart
│   │   │   ├── presentation/
│   │   │   │   └── room_list_page.dart
│   │   │   └── widgets/
│   │   ├── splash/
│   │   │   ├── controllers/
│   │   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── presentation/
│   │   │   │   └── splash_screen.dart
│   │   │   └── widgets/
│   │   └── technician/
│   │       ├── controllers/
│   │       ├── data/
│   │       ├── models/
│   │       │   └── technician_task.dart
│   │       ├── presentation/
│   │       │   ├── technician_home_page.dart
│   │       │   ├── technician_page.dart
│   │       │   └── technician_schedule_page.dart
│   │       └── widgets/
│   │           ├── task_details.dart
│   │           └── technician_header.dart
│   ├── shared/
│   │   ├── layouts/
│   │   │   ├── footer.dart
│   │   │   ├── header.dart
│   │   │   └── homepage.dart
│   │   └── widgets/
│   │       └── preview_list_section.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── main.dart
├── supabase/
│   ├── migrations/
│   ├── tests/
│   │   └── database/
│   ├── .gitignore
│   ├── config.toml
│   └── seed.sql
├── test/
│   ├── widget_test.dart
│   └── technician_test.dart
├── assets/
├── android/ · ios/ · linux/ · macos/ · web/ · windows/
├── pubspec.yaml
└── he_thong_dat_lich_quan_li.md
```

Cây trên lược bỏ thư mục sinh tự động, cấu hình IDE, `.gitkeep` và các README hướng dẫn. Thư mục chưa có mã nguồn được giữ bằng `.gitkeep`. Đăng nhập vẫn là luồng demo; phòng, thiết bị và công việc kỹ thuật dùng dữ liệu mẫu trong Dart. Đã tạo khung `supabase/` với cấu hình local và seed chưa có dữ liệu; chưa triển khai schema SQL hoặc kết nối database.

### 3.2. Cấu trúc đã áp dụng và trách nhiệm các thư mục

Đã áp dụng các thư mục trong cây dưới đây. Các tầng chưa có nghiệp vụ được giữ bằng `.gitkeep`; việc tạo thư mục chưa bao gồm triển khai repository, controller hoặc tích hợp Supabase:

```text
uth_room_booking/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/                    # Đọc cấu hình môi trường
│   │   ├── network/                   # Khởi tạo và cung cấp Supabase client
│   │   ├── errors/                    # Chuẩn hóa lỗi xác thực, dữ liệu, kết nối
│   │   └── utils/                     # Format thời gian, validation
│   ├── theme/                         # Giữ app_colors.dart, app_theme.dart
│   ├── shared/
│   │   ├── widgets/                   # Button, form field, trạng thái tải/lỗi
│   │   └── layouts/                   # Header, footer và bố cục dùng chung
│   └── features/
│       ├── auth/                      # Đăng nhập, đăng xuất, phiên người dùng
│       ├── profile/                   # Hồ sơ và đổi mật khẩu
│       ├── splash/                    # Màn hình khởi động
│       ├── room/                      # Danh sách, chi tiết và lịch phòng
│       ├── equipment/                 # Danh sách và chi tiết thiết bị
│       ├── booking/                   # Đăng ký, lịch sử, hủy yêu cầu
│       ├── incident_report/           # Báo sự cố, ảnh và theo dõi xử lý
│       └── technician/                # Công việc, lịch, sửa chữa, bảo trì
├── supabase/                          # Cấu trúc chi tiết ở mục 4
├── assets/
├── test/
└── pubspec.yaml
```

Mỗi tính năng đã có khung thư mục sau để bổ sung mã nguồn khi triển khai nghiệp vụ:

```text
features/<ten_tinh_nang>/
├── models/                            # Kiểu dữ liệu và ánh xạ dữ liệu database
├── data/                              # Repository truy vấn Supabase
├── controllers/                       # Trạng thái, kiểm tra và xử lý nghiệp vụ UI
├── presentation/                      # Các trang giao diện
└── widgets/                           # Widget chỉ dùng trong tính năng này
```

- `core/` chứa cấu hình dùng chung; các truy vấn nghiệp vụ đặt trong repository của tính năng.
- `data/` cung cấp dữ liệu cho controller; widget không tự thực hiện truy vấn database.
- `shared/` chỉ nhận thành phần dùng chung giữa nhiều tính năng. Đã chuyển `navbar/` và `homepage.dart` vào `shared/layouts/`, cập nhật các import liên quan.
- Đã tách `lists/` thành `room/` và `equipment/`; model nằm trong `models/`, dữ liệu demo nằm trong `data/sample_rooms.dart` và `data/sample_devices.dart`.
- Giữ các file kỹ thuật viên hiện tại làm nền tảng; đã tạo khung `data/` và `controllers/` cho bước kết nối lịch/công việc thật.
- Chỉ thêm `core/router/` nếu quyết định sử dụng bộ định tuyến riêng; chưa cần thay cách điều hướng hiện tại chỉ để phù hợp cây thư mục.

---

## 4. Cấu trúc thư mục database (Supabase)

### 4.1. Vị trí và cách tổ chức

Đặt `supabase/` ở thư mục gốc, ngang hàng `lib/`, để quản lý cấu trúc database dùng chung cho app và web quản trị bằng mã nguồn. Các thao tác quản trị được gọi từ web riêng; app chỉ thực hiện nghiệp vụ của sinh viên, giảng viên và nhân viên kỹ thuật. Không đặt migration SQL trong thư mục giao diện Flutter.

```text
supabase/
├── .gitignore                        # Bỏ qua dữ liệu local và secrets
├── config.toml                       # Cấu hình local tối thiểu
├── migrations/                       # Chưa có migration SQL; giữ bằng .gitkeep
├── seed.sql                          # Điểm vào seed, hiện chỉ có chú thích
├── tests/
│   └── database/                     # Chưa có test SQL; giữ bằng .gitkeep
└── README.md                         # Hướng dẫn và thứ tự triển khai schema
```

Khi triển khai schema, tạo migration theo mẫu `<timestamp>_<ten_thay_doi>.sql`. Thứ tự dự kiến: `create_profiles`, `create_rooms_and_equipment`, `create_bookings`, `create_incidents_and_assignments`, `create_maintenance_and_repair_logs`, `create_booking_rules`, `enable_rls_and_policies`, `configure_storage`. Hiện chưa tạo các migration này. Các migration phải tạo bảng được tham chiếu trước bảng chứa khóa ngoại. Chỉ bật truy cập ứng dụng sau khi các chính sách phân quyền đã được áp dụng đầy đủ.

- `config.toml`: đã tạo cấu hình tối thiểu cho môi trường local, cần kiểm tra bằng Supabase CLI khi thiết lập backend; không ghi mật khẩu hoặc khóa bí mật vào repository.
- `migrations/`: chứa bảng, khóa ngoại, chỉ mục, hàm, trigger, ràng buộc và chính sách RLS. Những thay đổi tiếp theo cần migration mới để có thể tái tạo database nhất quán.
- `seed.sql`: dùng dữ liệu giả cho phòng, thiết bị và tình huống thử nghiệm; dữ liệu phụ thuộc tài khoản phải tham chiếu tài khoản thử nghiệm được tạo hợp lệ.
- `tests/database/`: kiểm tra người dùng có truy cập đúng dữ liệu và hệ thống có ngăn đặt trùng lịch hay không.
- `README.md`: ghi điều kiện môi trường, thứ tự thiết lập, cách chạy kiểm tra và giới hạn của dữ liệu mẫu.

Cấu trúc này chưa yêu cầu Edge Functions. Nếu cần tác vụ quản trị tài khoản hoặc nghiệp vụ phía máy chủ, có thể bổ sung `supabase/functions/` ở bước triển khai tương ứng.

### 4.2. Các bảng nghiệp vụ dự kiến

Đây là mô hình thiết kế ban đầu, chưa phải schema đang tồn tại trên Supabase. Các bảng nghiệp vụ dự kiến đặt trong schema `public`; tài khoản xác thực do Supabase Auth quản lý.

| Bảng | Nội dung chính | Quan hệ dự kiến |
| --- | --- | --- |
| `profiles` | Họ tên, mã người dùng, vai trò, trạng thái tài khoản | `id` liên kết `auth.users.id`; app: `student`, `teacher`, `technician`; web quản trị: `admin` |
| `rooms` | Mã phòng, tên, vị trí, sức chứa, cấu hình, trạng thái vận hành | Một phòng chứa nhiều thiết bị |
| `equipment` | Mã tài sản, tên, loại, cấu hình, tình trạng | `room_id` liên kết `rooms`, có thể trống với thiết bị di động |
| `bookings` | Người đăng ký, mục đích, thời gian bắt đầu/kết thúc, trạng thái, người duyệt | `requester_id`, `reviewed_by` liên kết `profiles` |
| `booking_rooms` | Phòng được đăng ký | Liên kết `bookings` và `rooms` |
| `booking_equipment` | Các thiết bị cụ thể được mượn | Liên kết `bookings` và `equipment` |
| `usage_sessions` | Thời điểm nhận/trả thực tế, người bàn giao, ghi chú | Liên kết `bookings` để lưu lịch sử sử dụng |
| `incidents` | Nội dung sự cố, người báo, mức độ ưu tiên, trạng thái | Liên kết `profiles` và phòng/thiết bị gặp sự cố |
| `incident_attachments` | Đường dẫn ảnh đính kèm, người tải lên | Liên kết `incidents`; lưu đường dẫn đối tượng trong Storage |
| `technician_assignments` | Phạm vi phòng/thiết bị kỹ thuật viên phụ trách | Liên kết `profiles` với `rooms` hoặc `equipment` |
| `maintenance_requests` | Đề xuất bảo trì, tài sản, thời gian dự kiến, kết quả duyệt | Liên kết người đề xuất, người duyệt và phòng/thiết bị |
| `technician_tasks` | Công việc được giao, lịch xử lý, ưu tiên, tiến độ | Liên kết kỹ thuật viên và nguồn `incidents` hoặc `maintenance_requests` |
| `repair_logs` | Nội dung sửa chữa, linh kiện thay thế, thời điểm thực hiện | Liên kết `technician_tasks` và người ghi nhận |

### 4.3. Ràng buộc và phân quyền cần triển khai

- Mỗi phòng, thiết bị và mã người dùng có mã định danh duy nhất. Các khóa ngoại và trường bắt buộc cần được khai báo trong database.
- Đơn đăng ký phải có ít nhất một phòng hoặc thiết bị; thời gian kết thúc phải sau thời gian bắt đầu. Kiểm tra và duyệt phải thực hiện trong giao dịch để tránh hai yêu cầu đồng thời đặt cùng tài sản.
- Quy tắc chống trùng phải xét từng phòng và từng thiết bị trong các đơn đã duyệt còn hiệu lực. Khi phòng bị đóng để bảo trì hoặc tài sản không sẵn sàng, hệ thống phải chặn đăng ký/duyệt tương ứng.
- Trạng thái đơn dự kiến: `pending`, `approved`, `rejected`, `cancelled`, `completed`. Chỉ cho phép hủy đơn chưa xử lý theo nghiệp vụ ở mục 2; lưu người xử lý và thời điểm thay đổi.
- Trạng thái công việc dùng `pending`, `accepted`, `in_progress`, `completed` để ánh xạ với `TaskStatus` hiện tại. Mức ưu tiên dùng `urgent`, `medium`, `low` tương ứng `TaskPriority`.
- Sự cố/đề xuất bảo trì phải chỉ rõ tài sản liên quan. Công việc kỹ thuật phải xác định một nguồn sự cố hoặc đề xuất bảo trì, tránh tạo bản ghi không có ngữ cảnh.
- Lưu thời gian có múi giờ; giao diện hiển thị theo `Asia/Ho_Chi_Minh` để lịch sử và lịch kỹ thuật nhất quán.
- Áp dụng Row Level Security (RLS) cho các bảng ứng dụng. Sinh viên/giảng viên xem, tạo và cập nhật dữ liệu của mình trong phạm vi nghiệp vụ; kỹ thuật viên truy cập tài sản/công việc được phân công; admin thực hiện chức năng quản trị từ web riêng. Việc tách giao diện không thay thế kiểm tra quyền tại backend.
- Khi tích hợp Auth thật, app chỉ cho phép tài khoản có vai trò `student`, `teacher`, `technician` và trạng thái hợp lệ mở phiên sử dụng. Tài khoản `admin` sử dụng web quản trị riêng. Lựa chọn vai trò ở giao diện demo không phải nguồn xác định quyền; vai trò thật phải lấy từ backend đã xác thực.
- Người dùng không được tự đổi vai trò, người duyệt, người được phân công hoặc trạng thái duyệt qua cập nhật hồ sơ/yêu cầu. Những thao tác này phải được kiểm tra quyền ở database hoặc dịch vụ phía máy chủ.
- Ảnh sự cố dự kiến đặt trong bucket riêng tư `incident-images`, có chính sách truy cập theo sự cố và người phụ trách. Database lưu đường dẫn ảnh; giới hạn loại/kích thước file khi triển khai.
- Ứng dụng Flutter chỉ dùng cấu hình truy cập dành cho client kết hợp chính sách phân quyền. Khóa quản trị Supabase không được đưa vào mã nguồn hoặc bản build ứng dụng.

### 4.4. Thứ tự triển khai đề xuất

1. Khởi tạo môi trường Supabase và cấu hình local, tạo migration cho hồ sơ, phòng và thiết bị.
2. Tạo bảng đặt lịch, lịch sử sử dụng, sự cố, phân công và bảo trì; bổ sung khóa ngoại, ràng buộc và quy tắc duyệt/chống trùng.
3. Hoàn thiện RLS, quyền theo vai trò và Storage; kiểm tra ba vai trò app và vai trò admin của web quản trị trước khi kết nối giao diện.
4. Tích hợp xác thực và repository Flutter, lần lượt thay dữ liệu mẫu ở `room/data/sample_rooms.dart`, `equipment/data/sample_devices.dart` và `technician/models/technician_task.dart` bằng dữ liệu thật.
5. Kiểm tra phối hợp app/web: đăng ký trên app → duyệt trên web → sử dụng/trả; báo sự cố trên app → phân công trên web → kỹ thuật viên xử lý/ghi nhận trên app.

Đã áp dụng cấu trúc thư mục Flutter, cập nhật import và tạo khung Supabase trong repository. Schema SQL, chính sách phân quyền và kết nối Supabase từ ứng dụng vẫn thuộc kế hoạch triển khai; luồng giao diện hiện tại tiếp tục dùng dữ liệu demo.
