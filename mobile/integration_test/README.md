# Kiểm thử tích hợp và kiểm thử hệ thống UTH Lab

## Chạy trên điện thoại Android

Kết nối điện thoại, bật gỡ lỗi USB rồi chạy từ thư mục `mobile/`:

```powershell
flutter pub get
flutter devices
flutter test integration_test/account_roles_test.dart -d <device-id>
```

Bài đầu dùng tài khoản mô phỏng để kiểm tra điều hướng trên thiết bị. Test
lần lượt đăng nhập Sinh viên, Giảng viên và Nhân viên kỹ thuật, mở các tab
đúng vai trò rồi đăng xuất trước khi đổi tài khoản.

## Kiểm tra với Supabase thử nghiệm

Chuẩn bị một project Supabase thử nghiệm đã có schema, dữ liệu danh mục, Edge
Function `sign-in-by-code` nếu dùng mã và ba tài khoản có hồ sơ đúng vai trò.
Tạo một file JSON ngoài repo chứa các biến sau:

- `TEST_SUPABASE_URL` và `TEST_SUPABASE_PUBLISHABLE_KEY`
- `TEST_STUDENT_LOGIN` và `TEST_STUDENT_PASSWORD`
- `TEST_TEACHER_LOGIN` và `TEST_TEACHER_PASSWORD`
- `TEST_TECHNICIAN_LOGIN` và `TEST_TECHNICIAN_PASSWORD`

Chạy lệnh này với đường dẫn đến file và ID điện thoại của bạn:

```powershell
flutter test integration_test/account_roles_test.dart -d <device-id> --dart-define-from-file="D:/duong-dan/uth-test.json"
```

Khi thiếu biến, bài Supabase sẽ được bỏ qua. Chỉ dùng tài khoản thử vì
giá trị `dart-define` được nhúng vào bản build kiểm thử. Bài này kiểm tra
đăng nhập và mở tab, chưa tạo hoặc hủy đơn, gửi báo cáo, gửi OTP hay push.

### Tự động kiểm tra duyệt và từ chối lịch

Trên project thử nghiệm, chuẩn bị hai đơn **Chờ duyệt** thuộc sinh viên kiểm thử, với ca tương lai và tài sản đang hoạt động. Nên dùng tài khoản có ít đơn để hai thẻ dễ xuất hiện trong danh sách. Thêm vào file JSON thử nghiệm:

- `TEST_ALLOW_WRITES` với giá trị `"true"`
- `TEST_ADMIN_EMAIL` và `TEST_ADMIN_PASSWORD`
- `TEST_APPROVE_BOOKING_ID` và `TEST_REJECT_BOOKING_ID` là hai UUID khác nhau

Chạy lại lệnh kiểm thử trên. App giữ màn **Lịch → Của tôi** mở, còn tài khoản admin gọi cùng RPC với web. Bài kiểm thử chờ đúng thẻ đổi trạng thái mà không kéo làm mới. Hai đơn đổi trạng thái thật, vì vậy cần chuẩn bị đơn mới cho lần chạy sau.

## Kiểm thử hệ thống khi nối web quản trị

Chạy các ca dưới đây trên môi trường thử nghiệm chung cho mobile và web.
Chuẩn bị tài khoản Sinh viên, Giảng viên, Nhân viên kỹ thuật và Quản trị viên
web, một phòng máy, một thiết bị đang hoạt động và các ca trống. Kết quả
trong bảng là tiêu chí kiểm thử sau khi triển khai web.

| Ca kiểm thử | Thao tác | Kết quả mong đợi |
|---|---|---|
| Duyệt phòng máy | Sinh viên đăng ký phòng cho nhóm từ 10 người. Quản trị viên mở đơn trên web và duyệt. Sinh viên giữ **Lịch → Của tôi** mở. | Cùng một đơn tự chuyển từ **Chờ duyệt** sang **Đã duyệt**. Người gửi nhận thông báo và mở được chi tiết đăng ký. |
| Từ chối đăng ký thiết bị | Giảng viên đăng ký sử dụng thiết bị. Quản trị viên từ chối trên web. Kiểm tra **Của tôi** và thử đặt lại ca bằng tài khoản khác. | Đơn hiện **Từ chối**. Ca được giải phóng và tài khoản đủ điều kiện có thể đăng ký lại. |
| Duyệt phòng cho lớp học phần | Giảng viên đặt phòng máy và chọn lớp học phần. Quản trị viên kiểm tra rồi duyệt trên web. | Mã lớp, phòng, ngày và ca khớp giữa đơn trên web và chi tiết trên app. |
| Hủy khi đơn đang chờ duyệt | Quản trị viên mở đơn trên web. Người gửi hủy đơn từ mobile. Quản trị viên thử duyệt đơn đang mở mà chưa tải lại. | Hệ thống giữ trạng thái **Đã hủy**, từ chối thao tác duyệt trên dữ liệu cũ và giải phóng ca. |
| Đặt trùng tài sản và ca | Hai tài khoản đồng thời gửi yêu cầu cho cùng phòng hoặc cùng thiết bị trong cùng ca. | Chỉ một đơn giữ được ca. App còn lại báo ca đã bị giữ sau khi dữ liệu cập nhật. |
| Phân quyền duyệt | Dùng phiên Sinh viên, Giảng viên hoặc Nhân viên kỹ thuật gọi thao tác duyệt qua API của hệ thống thử nghiệm. | Backend từ chối và trạng thái đơn giữ nguyên. Tài khoản Quản trị viên được cấp quyền có thể duyệt. |
| Báo cáo sự cố | Sinh viên hoặc giảng viên gửi báo cáo. Kỹ thuật viên nhận việc rồi hoàn tất. Người gửi mở từng thông báo. | Kỹ thuật viên nhận trực tiếp và người gửi mở đúng báo cáo, kể cả khi có báo cáo trùng tiêu đề. Luồng này không cần quản trị viên duyệt. |
| Đề xuất bảo trì | Kỹ thuật viên gửi đề xuất từ mobile. Quản trị viên duyệt hoặc từ chối trên web. Kỹ thuật viên kiểm tra chuông và chạm thông báo. | Web nhận đề xuất, mobile cập nhật trạng thái, và thông báo mở đúng chi tiết. Duyệt đề xuất chỉ đổi trạng thái của đề xuất. |

Với ca có thông báo, thử thêm hai lượt trên Android. Khi bật **Nhận thông
báo** và đưa app xuống nền, thiết bị nhận push. Khi tắt, kết quả vẫn có
trong hộp thư và thiết bị không nhận push mới.

Ghi lại bản build mobile, bản web, mã đơn hoặc mã báo cáo, kết quả thực tế
và trạng thái đạt hoặc chưa đạt cho từng ca. Các ca mobile ↔ web trong
bảng chưa được chạy và chưa được tự động hóa.
