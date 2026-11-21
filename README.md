# UTH Lab

UTH Lab là ứng dụng Flutter để đăng ký sử dụng phòng máy và thiết bị, gửi báo cáo sự cố và theo dõi tiến độ xử lý.

## Cấu trúc repo

- [`mobile/`](mobile/) chứa mã Flutter, cấu hình Android và iOS, tài nguyên và kiểm thử.
- [`supabase/`](supabase/README.md) chứa cơ sở dữ liệu, migrations và Edge Functions dùng chung.
- [`web/`](web/README.md) dành cho web quản trị React. Luồng duyệt đăng ký trên web chưa được triển khai.

## Chạy ứng dụng

Cài Flutter SDK và Android SDK, sau đó kết nối điện thoại Android hoặc mở trình giả lập. Từ thư mục gốc của repo, chạy:

```powershell
cd mobile
flutter pub get
flutter run --profile
```

Nếu chỉ chạy để phát triển, dùng `flutter run`. Project đã có cấu hình iOS. Build iOS cần macOS và Xcode, và push iOS chưa được triển khai.

## Tài khoản và chức năng

Chọn cổng theo vai trò rồi đăng nhập bằng email hoặc mã tài khoản và mật khẩu. Supabase Auth xác thực phiên đăng nhập. Hàm `sign-in-by-code` tra mã tương ứng trong `profiles.student_code`, `profiles.lecturer_code` hoặc `profiles.employee_code`.

- **Sinh viên** đăng ký ca sử dụng phòng máy hoặc thiết bị, theo dõi lịch và gửi báo cáo sự cố.
- **Giảng viên** đăng ký phòng máy theo lớp học phần, đăng ký thiết bị và có thể đánh dấu cần hỗ trợ ngay trong giờ dạy khi gửi báo cáo.
- **Nhân viên kỹ thuật** xem báo cáo mới, nhận việc và cập nhật trạng thái xử lý. Đề xuất bảo trì đang chờ luồng duyệt trên web.

## Thông báo Android

Hộp thư trong app lấy dữ liệu từ Supabase. Thông báo nhận việc hoặc hoàn tất mở được báo cáo tương ứng từ hộp thư.

Android dùng Firebase Cloud Messaging của project `uth-lab` để hiện thông báo hệ thống. Trong **Cá nhân → Nhận thông báo**, bật công tắc và cấp quyền thông báo trên thiết bị để nhận push khi app chạy nền. Khi tắt, thông báo mới vẫn nằm trong hộp thư. Chạm push hiện mở app, chưa điều hướng thẳng tới nội dung.

Hàm `send-mobile-push` gửi qua FCM bằng secret `FCM_SERVICE_ACCOUNT_JSON` trong Supabase Edge Function Secrets. Giữ khóa service account ngoài Git và ngoài app. Nếu triển khai sang backend khác, áp dụng migrations, triển khai các Edge Functions và thiết lập [lịch gửi push](supabase/operations/enable_mobile_push.sql).

## Cấu hình và kiểm thử

Để dùng project Supabase khác, truyền `--dart-define=SUPABASE_URL=...` và `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` khi chạy hoặc build. Project đích cần triển khai `sign-in-by-code` để đăng nhập bằng mã.

Chạy từ thư mục `mobile/`:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Xem thêm [cách tổ chức mã Flutter](mobile/lib/features/README.md) và [tài liệu backend](supabase/README.md).
