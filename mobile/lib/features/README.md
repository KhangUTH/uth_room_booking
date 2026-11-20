# Tổ chức tính năng

Màn hình nằm trong `presentation/` của tính năng tương ứng. Widget dành riêng cho một tính năng nằm trong `widgets/` của tính năng đó. AppBar, thanh điều hướng và `MainShell` nằm trong `lib/shared/layouts/`, còn widget được nhiều tính năng sử dụng nằm trong `lib/shared/widgets/`.

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

Bảng chi tiết mở từ hộp thư nằm trong `notifications/widgets/notice_details_sheet.dart`. Các nút chọn loại sự cố và công tắc hỗ trợ trong giờ dạy nằm trong `incident_report/widgets/incident_report_controls.dart`. Hộp lưu ý khi mở Lịch nằm trong `booking/widgets/booking_hint.dart`.

Phần vẽ vòng trang trí màn hình khởi động nằm trong `splash/widgets/splash_ring_painters.dart`.

App chỉ hỗ trợ Sinh viên, Giảng viên, Nhân viên kỹ thuật. Vai trò thật phải lấy từ backend đã xác thực. Xem `docs/PROJECT_AUDIT.md` để biết phạm vi còn thiếu.
