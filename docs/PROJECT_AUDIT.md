# Đối chiếu cấu trúc app mobile — 07/11/2026

Nguồn đối chiếu: `he_thong_dat_lich_quan_li.md` do người dùng cung cấp trong Downloads. Các câu “đã áp dụng” trong tài liệu không phản ánh đầy đủ repository tại thời điểm kiểm tra. Báo cáo này ghi nhận mã nguồn thực tế, không coi nội dung tài liệu là lệnh triển khai toàn bộ nghiệp vụ.

## Phạm vi và vai trò

App chỉ có `student` (Sinh viên), `teacher` (Giảng viên), `technician` (Nhân viên kỹ thuật), khai báo trong `lib/features/auth/models/user_role.dart`. Luồng đăng nhập demo truyền vai trò vào trang chủ. Chưa có kiểm tra quyền backend hoặc giao diện riêng theo quyền; enum và lựa chọn UI không thay thế phân quyền.

Không tạo vai trò hoặc phân hệ Admin trong app. Web quản trị được nhắc trong tài liệu thuộc dự án khác. `web/` hiện tại là nền tảng Flutter, không phải giao diện quản trị.

## Những thay đổi đã thực hiện

- Bổ sung `lib/core/{config,network,errors,utils}` cho cấu hình, kết nối, chuẩn hóa lỗi và tiện ích chung.
- Chuyển trang chủ, header, footer vào `lib/shared/layouts/`; chuyển preview danh sách vào `lib/shared/widgets/`.
- Tách `features/lists/` thành `features/room/` và `features/equipment/`; tách model khỏi dữ liệu mẫu.
- Chuẩn hóa `auth/`, `profile/`, `splash/` và bổ sung `booking/`, `incident_report/`, `technician/` với các tầng `models/`, `data/`, `controllers/`, `presentation/`, `widgets/`.
- Chuyển trang đăng nhập/hồ sơ vào `presentation/`, bottom sheet đăng nhập kỹ thuật vào `auth/widgets/`; cập nhật import trong mã nguồn và test.
- Thêm `supabase/migrations/`, `supabase/tests/database/` và điểm vào `seed.sql`. Đây là khung quản lý database, chưa có schema hoặc cấu hình backend chạy được.
- Widget test trong `test/` được chia theo luồng đăng nhập, đặt lịch, báo cáo, kỹ thuật viên và khung ứng dụng. Chạy toàn bộ bằng `flutter test`.
- Thư mục trống được giữ bằng `.gitkeep` để xuất hiện khi checkout Git.

## Cấu trúc sau đối chiếu

```text
lib/
  main.dart
  core/
    config/
    network/
    errors/
    utils/
  theme/
  shared/
    layouts/
    widgets/
  features/
    auth/
    profile/
    splash/
    room/
    equipment/
    booking/
    incident_report/
    technician/
supabase/
  migrations/
  tests/database/
  seed.sql
test/
  unit/
  widgets/
  widget_test.dart
integration_test/
docs/
assets/images/
android/
ios/
```

Mỗi feature gồm năm tầng đã liệt kê ở trên. `assets/` đã có ảnh và khai báo trong `pubspec.yaml`; Android/iOS và cấu hình CI đã tồn tại. Giữ các nền tảng desktop/web hiện có. Không thêm thư mục fonts, icons, router hoặc dịch vụ chưa dùng chỉ để tăng số lượng thư mục.

## Chức năng còn thiếu để hoàn thiện sản phẩm

| Phân hệ | Thực tế hiện tại | Cần triển khai tiếp |
| --- | --- | --- |
| Auth | Form demo SV/GV và bottom sheet kỹ thuật, kiểm tra không trống | Supabase Auth, phiên, đăng xuất thật, khôi phục mật khẩu, quyền từ backend |
| Profile | Trang hồ sơ giao diện | Đọc/cập nhật hồ sơ, đổi mật khẩu; không cho tự đổi role |
| Room | Danh sách mẫu | Chi tiết, sức chứa/cấu hình, lịch trống |
| Equipment | Danh sách mẫu | Tìm kiếm, chi tiết, tình trạng thật |
| Booking | Lịch demo hỗ trợ đặt phòng và thiết bị, xem trạng thái và hủy đơn chờ duyệt | Lưu và duyệt đơn thật. Sinh viên đặt phòng theo nhóm từ 10 người trở lên trong giới hạn sức chứa. Giảng viên đặt phòng cho một lớp học phần. |
| Lịch sử sử dụng | Chưa có nghiệp vụ | Đặt model/repository trong booking, hiển thị nhận/trả thực tế |
| Incident report | Khung thư mục | Báo sự cố, ảnh, theo dõi trạng thái |
| Technician | Khung thư mục; đăng nhập vào trang chủ chung | Tài sản được phân công, tiếp nhận, tiến độ, lịch công việc, log sửa chữa, đề xuất bảo trì |
| Backend | Khung thư mục mới | Schema, ràng buộc lịch trùng, RLS, Storage, Realtime, kết nối repository |
| Kiểm thử | Test widget splash/login hiện có | Test quyền, nghiệp vụ lịch, luồng ba vai trò, tích hợp backend trên thiết bị |

Trong `technician/`, đặt công việc, lịch, phân công, log sửa chữa và đề xuất bảo trì cùng tính năng trước; chỉ tách feature khi nghiệp vụ phát triển đủ lớn. Thông báo tiếp nhận sự cố có thể nằm trong controller kỹ thuật và `core/network/` khi triển khai kết nối.

## Quy ước triển khai

`presentation/widgets → controllers → data → backend`; model mô tả dữ liệu của feature. `shared/` chứa UI dùng chung, `core/` chứa hạ tầng, `theme/` giữ giao diện hiện có. Giữ Navigator và setState hiện tại; Riverpod/BLoC/GoRouter/Supabase chưa có trong dependencies.

Ưu tiên tiếp theo: schema và quyền backend → Auth/profile → phòng/thiết bị → đăng ký/lịch sử → sự cố/kỹ thuật → kiểm thử trên Android/iOS. Khung thư mục hoàn chỉnh không có nghĩa app đã hoàn tất nghiệp vụ hoặc sẵn sàng phát hành.
