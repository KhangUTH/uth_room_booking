# uth_room_booking

Ứng dụng Flutter đặt lịch phòng máy và thiết bị cho Sinh viên, Giảng viên và Nhân viên kỹ thuật.

Chạy `flutter run` để đăng nhập vào UTHBookingApp bằng email và mật khẩu Supabase Auth. Chọn cổng phù hợp với vai trò của tài khoản. Tên, mã và vai trò lấy từ `profiles`; màn hình Cá nhân lấy email đăng nhập từ Auth. Số điện thoại, tùy chọn thông báo và các luồng đặt lịch, sự cố, kỹ thuật vẫn dùng dữ liệu trong app.

Để đăng nhập bằng mã, nhập đúng mã trong `profiles.student_code` (Sinh viên), `profiles.lecturer_code` (Giảng viên) hoặc `profiles.employee_code` (Nhân viên kỹ thuật) cùng mật khẩu của tài khoản. Edge Function `sign-in-by-code` tra mã theo cổng đăng nhập.

Để dùng một project Supabase khác, truyền `--dart-define=SUPABASE_URL=...` và `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` khi chạy hoặc build. Cần triển khai `sign-in-by-code` trên project đó để hỗ trợ đăng nhập bằng mã.

Xem [báo cáo đối chiếu project](docs/PROJECT_AUDIT.md) để biết cấu trúc thư mục và các nghiệp vụ còn thiếu. Khung backend nằm ở [supabase/](supabase/README.md).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
