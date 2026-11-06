# UTH Room Booking

Ứng dụng Flutter đăng ký sử dụng phòng máy và thiết bị dành cho ba vai trò:

- Sinh viên: xem thiết bị, đăng ký sử dụng, xem lịch sử và báo sự cố.
- Giảng viên: xem phòng/thiết bị, lịch phòng, đăng ký và báo sự cố.
- Nhân viên kỹ thuật: xem tài sản/công việc được phân công, cập nhật tiến độ,
  ghi nhận sửa chữa và đề xuất bảo trì.

Đây là phạm vi nghiệp vụ dự kiến; ứng dụng hiện dùng đăng nhập và dữ liệu demo.
Các thư mục tính năng chưa triển khai được giữ bằng `.gitkeep`.

Admin sử dụng **web quản trị riêng** để quản lý tài khoản/tài sản, duyệt đăng ký,
phân công kỹ thuật và xem thống kê. Mã nguồn web quản trị chưa có trong repository
này. Thư mục `web/` là nền tảng Flutter Web của cùng ứng dụng ba vai trò.

Backend Supabase dự kiến dùng chung cho app và web quản trị. Database vẫn có vai trò
`admin` để kiểm soát quyền và lưu người duyệt/phân công; giao diện app chỉ hỗ trợ
`student`, `teacher`, `technician`. Chưa triển khai schema SQL hoặc tích hợp Auth thật.

## Cấu trúc

- `lib/core/`: khung cấu hình, kết nối, lỗi và tiện ích dùng chung.
- `lib/features/`: các tính năng của ba vai trò app.
- `lib/shared/`: bố cục và widget dùng chung.
- `lib/theme/`: màu sắc và giao diện.
- `supabase/`: cấu hình local, nơi chứa migration, seed và kiểm thử database.
- `test/`: kiểm thử Flutter hiện có.

Chi tiết: [tài liệu hệ thống](he_thong_dat_lich_quan_li.md),
[tổ chức tính năng](lib/features/README.md), [database](supabase/README.md).

## Chạy và kiểm tra

Sau khi cài Flutter và tải dependencies:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```
