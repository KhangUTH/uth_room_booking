# Backend Supabase

## Khôi phục mật khẩu

Trong **Authentication → Email Templates → Reset Password**, dùng
`{{ .Token }}` trong nội dung email để người dùng nhập mã vào app. Email được
gửi tới địa chỉ đã gắn với tài khoản Supabase Auth. Cấu hình SMTP riêng trước
khi gửi tới người dùng ngoài nhóm quản lý project.

Để kiểm thử, dùng một tài khoản thử có hộp thư thật. Sau khi nhận mã và đặt
mật khẩu mới, đăng nhập lại trên app bằng mật khẩu mới. Các tài khoản demo
dùng địa chỉ giả chỉ phục vụ trình diễn đăng nhập.

Flutter dùng Supabase cho xác thực, đọc hồ sơ, lưu ảnh đại diện và đọc danh
mục tài sản trong màn Lịch, Báo cáo và luồng bảo trì của kỹ thuật viên.
Project từ xa `UTHBookingApp` có các bảng `profiles`, `rooms`, `equipment`,
`bookings` và `incident_reports`, cùng trigger tạo hồ sơ khi có tài khoản Auth.
Danh mục app lấy phòng chưa lưu trữ (`is_archived = false`) từ `rooms`
và thiết bị chung từ `equipment`
với `room_id IS NULL`. Năm thiết bị chung đã được thêm trên UTHBookingApp.
Sinh viên và giảng viên đọc ca đã giữ, tạo đơn, xem và hủy đơn chờ duyệt
qua Supabase. Ô ca chỉ nhận UUID tài sản và giờ bắt đầu. Đơn chờ duyệt
và đã duyệt giữ ca theo ràng buộc chống trùng của PostgreSQL.

Migration `connect_mobile_incident_reports_and_evidence` nối phần gửi, xem
và hủy báo cáo của sinh viên và giảng viên với `incident_reports`. Tùy
chọn hỗ trợ ngay thuộc giảng viên. Lớp học phần là tùy chọn và được lấy
từ danh sách phân công trong `teaching_sections`. Ảnh PNG
được lưu ở bucket riêng tư `incident-images` theo tài khoản, tối đa 5 MB.
Ứng dụng gửi ảnh mới dưới dạng JPEG. RPC `incident_evidence_path` trả về
đường dẫn JPEG hoặc PNG tương ứng với ảnh đã lưu của báo cáo.
App dùng RPC `technician_incident_jobs` và `advance_technician_incident`
cho luồng chuyển trực tiếp báo cáo mới đến kỹ thuật viên. Người gửi nhận
thông báo trong app khi kỹ thuật viên nhận việc và khi công việc hoàn tất.
Đề xuất bảo trì vẫn mô phỏng.

Số điện thoại được lưu trong `profiles.phone`. Tài khoản đang hoạt động
có thể sửa số của mình.

UTHBookingApp dọn tối đa 50 ảnh minh chứng mỗi lượt vào 03:15 giờ Việt Nam.
Ảnh phải quá 24 giờ và chưa gắn báo cáo mới đủ điều kiện xóa.
Để bật trên project khác, triển khai Edge Function `clean-expired-incident-photos` với
xác thực JWT, sau đó đặt URL worker và JWT anon dạng cũ của cùng project
vào Vault bằng hai tên ghi trong
[`enable_incident_photo_cleanup.sql`](operations/enable_incident_photo_cleanup.sql)
và chạy script. Script tạo thêm token riêng để worker xác thực yêu cầu.

Migration `expose_approved_technician_usage_schedule` cấp cho kỹ thuật viên
đang hoạt động quyền xem tài sản, địa điểm, ca và trạng thái của các lượt
đã duyệt hoặc hoàn thành trong tuần. API lịch kỹ thuật không trả danh tính
người đăng ký hay các trường của đơn cá nhân.

Migration `prevent_overlapping_student_room_bookings` chặn một sinh viên
giữ hai phòng có thời gian trùng nhau. Đơn chờ duyệt và đã duyệt giữ ca.
Migration `limit_lecturer_library_room_bookings` loại phòng thư viện khỏi
danh sách đặt phòng của giảng viên theo cờ `rooms.allows_teacher_booking`.
Giảng viên chọn lớp học phần khi đặt phòng máy. Đơn thiết bị chỉ cần chọn ca.

Migration `prepare_mobile_bookings_and_teaching_sections` và
`expose_busy_booking_slots_without_user_details` đã áp dụng trên
`UTHBookingApp`. Lớp thật được nhập vào `teaching_sections` với mã lớp,
tên lớp và UUID giảng viên được phân công.

Migration `create_booking_in_app_notifications` ghi thông báo khi tạo
đơn hoặc đổi trạng thái. Người nhận đọc và cập nhật cờ đã đọc, đã lưu
trên thông báo của mình. App làm mới hộp thông báo khi mở và mỗi 30 giây.
Migration `allow_users_to_delete_own_in_app_notifications` cho phép xóa
theo nhóm ID trong hộp thông báo của chính tài khoản.

Migration [`connect_admin_booking_review`](migrations/20261121120000_connect_admin_booking_review.sql)
cấp cho admin đang hoạt động quyền xem và duyệt hoặc từ chối đơn chờ. Web
admin và Flutter dùng chung bảng `bookings` và trigger thông báo. Áp dụng
migration này trước khi cập nhật web admin. Migration cũng nâng cấp được
project đã chạy script `web/supabase/sql/06-admin-bookings.sql`.

## Dựng môi trường mới

1. Với Supabase CLI và Docker đang chạy, dùng `supabase start` rồi
   `supabase db reset --local` trên môi trường phát triển trống. Chuỗi trong
   `migrations/` tạo schema app trên Auth và Storage có sẵn của Supabase.
   `seed.sql` nạp danh mục phòng và thiết bị cho môi trường cục bộ.
2. Tạo tài khoản thử qua Auth với email `@ut.edu.vn` và vai trò phù hợp.
   Vai trò nằm trong metadata quản trị `app_role`. Gán lớp học phần cho tài
   khoản giảng viên nếu cần thử đặt phòng hoặc báo cáo cần hỗ trợ ngay.
3. Chạy `supabase functions serve sign-in-by-code` ở môi trường cục bộ hoặc
   triển khai hàm trong project mới bằng `supabase functions deploy sign-in-by-code`.
   Hàm đọc khóa từ biến môi trường của Supabase. Flutter chỉ dùng khóa
   publishable hoặc anon khi cấu hình URL project mới.

Repo lưu các phiên bản migration đã ghi nhận trên UTHBookingApp và bổ sung
schema nền cùng các thay đổi từng chạy qua SQL Editor. Trước khi dùng
`supabase db push` với UTHBookingApp hiện tại, đối chiếu và đồng bộ lịch sử
migration với schema đã tồn tại. Chạy lại schema nền trên project đang
có dữ liệu sẽ gây xung đột. Dữ liệu người dùng, lịch đặt, báo cáo và tệp
Storage được phục hồi qua bản sao lưu riêng khi cần.

## Bản nháp schema ban đầu

Bản nháp này có quy tắc đặt lịch cũ và cần đối chiếu với các migration
đã áp dụng trước khi tái sử dụng.

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

- Dùng UUID của tài sản khi lưu đăng ký, báo sự cố và đề xuất bảo trì.
- Cập nhật bản nháp đăng ký cho đúng nghiệp vụ hiện tại. Sinh viên được
  đăng ký phòng cho nhóm từ 10 người trong giới hạn sức chứa. Giảng viên
  đăng ký phòng theo lớp học phần được phân công.

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
