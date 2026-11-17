# Backend Supabase

Flutter chưa kết nối Supabase. Project từ xa `UTHBookingApp` đã có các bảng
`profiles`, `rooms`, `equipment`, `bookings` và `incident_reports`, cùng trigger
tạo hồ sơ khi có tài khoản Auth. Khi kiểm tra, Supabase chưa ghi nhận migration
nào cho schema này.

## Migration nền tảng đang chờ duyệt

[`secure_booking_foundation.draft.sql`](secure_booking_foundation.draft.sql) dựa
trên schema hiện tại của `UTHBookingApp`. SQL này cần chạy trong một giao dịch
qua công cụ quản lý migration. Nó thay các policy và ràng buộc trên bảng hiện
có, đồng thời giữ nguyên các bản ghi và khóa chính.

- Sinh viên và giảng viên chỉ xem đăng ký, sự cố của mình. Cả hai có thể mượn
  thiết bị. Đặt nguyên phòng dành cho giảng viên. Hủy chỉ áp dụng với đơn chờ
  duyệt. Người dùng đọc hồ sơ của chính mình. Tài khoản đang hoạt động được
  sửa họ tên, số điện thoại và tùy chọn nhận thông báo qua Data API.
- Hồ sơ bổ sung `faculty`, `phone` và `notifications_enabled` theo màn hình
  Cá nhân. Khoa có thể để trống và do quản trị cập nhật. Migration
  `split_profile_codes_by_role` trên UTHBookingApp dùng `student_code` cho
  sinh viên, `lecturer_code` cho giảng viên và `employee_code` cho kỹ thuật viên.
  Khi kết nối Flutter, đổi email đăng nhập và mật khẩu qua Auth. Quyền camera
  và ảnh được quản lý trên thiết bị.
- Đơn chờ duyệt có thể trùng giờ. PostgreSQL từ chối hai đơn đã duyệt trùng
  tài sản, kể cả khi hai giao dịch duyệt đồng thời. Khoảng giờ `[bắt đầu, kết thúc)`
  cho phép hai lượt liền kề. Phòng ngừng hoạt động và thiết bị có trạng thái
  khác `available` bị chặn khi tạo và duyệt đơn.
- Kỹ thuật viên chỉ đọc phòng hoặc thiết bị thuộc phạm vi được phân công.
  Thiết bị trong phòng được phân công cũng nằm trong phạm vi này. Việc duyệt
  đơn và phân công cần backend quản trị có kiểm tra quyền. Khi duyệt hoặc từ
  chối, backend truyền ID người duyệt vào `reviewed_by`.

### Kết quả kiểm thử cục bộ

Đã chạy bản nháp thành công trên PostgreSQL 17 với bản sao cấu trúc của năm
bảng và dữ liệu giả. [Bộ kiểm thử SQL](tests/database/booking_foundation.sql)
đã kiểm tra quyền xem/sửa, quyền hủy, tài sản ngừng hoạt động, phân công kỹ
thuật và khung giờ liền kề. Một phép thử với hai kết nối độc lập xác nhận
đơn thứ hai vẫn ở trạng thái `pending` khi đơn trùng phòng đã được duyệt.

Để chạy lại trên PostgreSQL 17 trống bằng `psql`, nạp
[`standalone_auth.sql`](tests/database/fixtures/standalone_auth.sql),
[`current_schema.sql`](tests/database/fixtures/current_schema.sql) và bản nháp
theo thứ tự đó trong một giao dịch (`psql -1 -v ON_ERROR_STOP=1`). Sau đó
chạy `booking_foundation.sql` riêng. Auth trong phép thử là mô phỏng giao diện
SQL, nên cần kiểm tra lại luồng Auth/Data API và Security Advisor trên Supabase
khi triển khai. Bản sao schema là fixture kiểm thử, chưa phải migration nền
đã đăng ký của project từ xa.

## Các phần cần triển khai tiếp

- Tách đơn khỏi tài sản đăng ký khi triển khai nhiều thiết bị trong một đơn.
  Mô hình chỗ ngồi cần định danh từng chỗ và kiểm tra xung đột giữa đặt chỗ
  và đặt nguyên phòng. Lịch phòng cần trả về các khung giờ đã giữ chỗ mà
  không lộ người đăng ký hoặc mục đích sử dụng.
- Thêm mã phòng, mã tài sản, cấu hình và lịch ngừng hoạt động. Tạo
  `usage_sessions` để lưu thời điểm nhận/trả và người bàn giao.
- Giữ `incident_reports` làm nguồn sự cố. Bổ sung công việc, bảo trì và log
  sửa chữa theo phạm vi phân công. Dùng bucket riêng tư `incident-images`
  với quyền theo từng sự cố và giới hạn loại, kích thước tệp.

## Cấu trúc thư mục

Migration đã áp dụng `scope_profile_reads_to_owner` giới hạn quyền đọc
`profiles` theo `auth.uid()` cho cả ba vai trò. Edge Function đăng nhập
bằng mã số tiếp tục tra cứu hồ sơ qua quyền máy chủ.

- `migrations/`: migration `<timestamp>_<ten_thay_doi>.sql` khi triển khai database.
- `tests/database/`: test quyền truy cập và ràng buộc nghiệp vụ.
- `seed.sql`: điểm vào dữ liệu giả; hiện chỉ là chú thích.

Khi thiết lập backend, dùng Supabase CLI khởi tạo cấu hình `config.toml` phù hợp môi trường. Chưa thêm cấu hình chưa được kiểm chứng vào khung này.

Thứ tự nghiệp vụ theo tài liệu: profiles → rooms/equipment → bookings và tài sản đăng ký → usage_sessions → incidents/attachments → assignments/maintenance/tasks/repair_logs → quy tắc lịch và RLS/Storage. Tạo bảng được tham chiếu trước khóa ngoại; chỉ kết nối app sau khi quyền đã được kiểm thử. Ba vai trò app: student, teacher, technician. Phần quản trị được mô tả trong tài liệu nằm ngoài app này.

Chỉ đưa cấu hình client vào app; giữ khóa quản trị ở máy chủ. Kiểm tra quyền, chống trùng lịch và chuyển trạng thái phải được thực thi ở backend.
