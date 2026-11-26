# Tổ chức tính năng

Màn hình nằm trong `presentation/` của tính năng tương ứng. Widget dành riêng cho một tính năng nằm trong `widgets/` của tính năng đó. AppBar, thanh điều hướng và `MainShell` nằm trong `lib/shared/layouts/`, còn widget được nhiều tính năng sử dụng nằm trong `lib/shared/widgets/`.

`profile/presentation/profile_avatar_controller.dart` quản lý trạng thái tải và đổi ảnh đại diện cho AppBar và trang Cá nhân. `booking/controllers/booking_controller.dart` thực hiện gửi và hủy đăng ký. Các hộp xác nhận nằm trong `booking/widgets/booking_action_dialogs.dart`.

Lịch dùng ID Supabase để đối chiếu tài sản và ca bận. `ScheduleView` làm mới ngầm khi tab Lịch đang mở ở tiền cảnh.

`BookingController` lọc danh mục theo vai trò và tính số tài sản còn trống theo ca. `ScheduleView` giữ lựa chọn ngày, ca và trạng thái làm mới.

`ai_chat/` tách giao diện, mô hình tin nhắn, điều phối hội thoại và `ChatRepository`. Hội thoại hiện tại và lịch sử được giữ trong phiên đăng nhập. Repository mô phỏng luồng đặt phòng và báo cáo, còn lịch cá nhân dùng `BookingController` như trang Lịch.

Trong `ai_chat/widgets/`, `chat_avatar.dart` chứa robot, nút mở và hiệu ứng. `chat_welcome.dart` chứa màn chào và gợi ý theo vai trò. `chat_turn.dart` ghép bong bóng với thẻ kết quả. Form báo cáo mẫu nằm trong `chat_incident_draft_dialog.dart`. Hợp đồng `ChatRepository` nằm riêng với các triển khai trong `ai_chat/data/`.

`ChatVoiceInput` dùng dịch vụ nhận dạng giọng nói của thiết bị để điền tiếng Việt vào ô chat. Quyền micro được hỏi khi chạm nút micro. Người dùng kiểm tra văn bản trước khi gửi.

Ba vai trò dùng chung `ChatScreen`. Kỹ thuật viên nhận câu hỏi gợi ý về công việc và dùng `TechnicianChatRepository` để tra cứu danh sách theo quyền của tài khoản.

`HomeDashboard` theo dõi số liệu đặt lịch và mở trang Lịch sử. `IncidentReportView.fromCatalog` chuyển danh mục phòng và thiết bị thành các lựa chọn phù hợp cho báo cáo. Các hàng và nhóm thông tin của trang Cá nhân nằm trong `profile/widgets/profile_sections.dart`.

Khi mở rộng một màn hình, giữ điều phối luồng và trạng thái cấp màn hình trong `presentation/`. Đặt form, danh sách, thẻ và hộp thoại có trách nhiệm riêng trong `widgets/` của tính năng. Giữ quy tắc nghiệp vụ và dữ liệu ở lớp hiện có của tính năng.

- `auth/` tách màn hình đăng nhập, xác thực Supabase và lưu phiên thiết bị.
- `booking/` tách danh mục tài sản, truy cập đơn Supabase, dữ liệu mẫu,
  quy tắc đặt lịch, màn Lịch, trang Lịch sử và widget hiển thị.
- `incident_report/` tách truy cập báo cáo và ảnh minh chứng khỏi form,
  danh sách và bảng chi tiết báo cáo sự cố.
- `home/` chứa Trang chủ. `notifications/` tách truy cập hộp thư, dữ liệu
  mẫu, màn danh sách và thẻ thông báo. `profile/` tách lưu ảnh đại diện
  khỏi màn Cá nhân.
- `technician/` chứa model, bộ lọc, lịch và chi tiết công việc. Dashboard và danh sách Công việc là hai widget tab riêng. `TechnicianWorkController` quản lý việc tải và làm mới danh sách cho cả hai tab.
- `splash/`, `room/` và `equipment/` chứa màn hình khởi động và các danh sách tài sản hiện có.

Menu chọn vị trí và lớp học phần nằm trong `incident_report/widgets/incident_inline_menu.dart`. Phần hiển thị danh sách lịch cá nhân và bộ lọc thông báo nằm trong `booking/widgets/my_bookings_section.dart` và `notifications/widgets/notice_search_filters.dart`. Hai màn hình tương ứng giữ trạng thái lọc và xử lý thao tác.

Trạng thái tải lại danh mục, dữ liệu đã tải và khung thử lại nằm trong `lib/shared/layouts/shell_catalog_content.dart`. `MainShell` dùng chung phần này cho các tab cần danh mục.

`technician/presentation/technician_home_content.dart` ghép dashboard, danh mục phụ trách và đề xuất bảo trì. `MainShell` giữ trạng thái điều hướng và xử lý nút quay lại.

`auth/widgets/login_password_options.dart` chứa các tùy chọn dưới ô mật khẩu. Hộp thoại khôi phục mật khẩu, xác minh OTP và đặt mật khẩu mới nằm trong `auth/widgets/password_recovery_dialog.dart`.

Bảng chi tiết mở từ hộp thư nằm trong `notifications/widgets/notice_details_sheet.dart`. Các nút chọn loại sự cố và công tắc hỗ trợ trong giờ dạy nằm trong `incident_report/widgets/incident_report_controls.dart`. Hộp lưu ý khi mở Lịch nằm trong `booking/widgets/booking_hint.dart`.

`notifications/presentation/notice_navigation.dart` mở đúng báo cáo, công việc hoặc đề xuất khi người dùng chọn thông báo. `notifications_view.dart` quản lý hộp thư và thao tác trên danh sách.

`technician/data/maintenance_proposal_store.dart` gửi đề xuất theo ID tài sản lấy từ danh mục Supabase. Controller giữ danh sách trong phiên và dữ liệu demo. Danh sách công việc và màn chi tiết chỉ tải định kỳ khi màn tương ứng đang hiện.

Phần vẽ vòng trang trí màn hình khởi động nằm trong `splash/widgets/splash_ring_painters.dart`.

App chỉ hỗ trợ Sinh viên, Giảng viên, Nhân viên kỹ thuật. Vai trò thật phải lấy từ backend đã xác thực. Xem `docs/PROJECT_AUDIT.md` để biết phạm vi còn thiếu.
