# Tổ chức tính năng

Màn hình nằm trong `presentation/` của tính năng tương ứng. Widget dành riêng cho một tính năng nằm trong `widgets/` của tính năng đó. AppBar, thanh điều hướng và `MainShell` nằm trong `lib/shared/layouts/`, còn widget được nhiều tính năng sử dụng nằm trong `lib/shared/widgets/`.

Khi mở rộng một màn hình, giữ điều phối luồng và trạng thái cấp màn hình trong `presentation/`. Đặt form, danh sách, thẻ và hộp thoại có trách nhiệm riêng trong `widgets/` của tính năng. Giữ quy tắc nghiệp vụ và dữ liệu ở lớp hiện có của tính năng.

- `booking/` chứa màn hình Lịch, lịch tuần, bảng xác nhận, thẻ lịch sử, dữ liệu mẫu và quy tắc đặt hoặc hủy ca.
- `incident_report/` chứa form, danh sách báo cáo và bảng chi tiết báo cáo sự cố.
- `home/`, `notifications/` và `profile/` chứa giao diện Trang chủ, Thông báo và Cá nhân.
- `technician/` chứa model, bộ lọc, lịch và chi tiết công việc. Dashboard và danh sách Công việc là hai widget tab riêng.
- `auth/`, `splash/`, `room/` và `equipment/` chứa các màn hình đăng nhập, khởi động và danh sách tài sản hiện có.

App chỉ hỗ trợ Sinh viên, Giảng viên, Nhân viên kỹ thuật. Vai trò thật phải lấy từ backend đã xác thực. Xem `docs/PROJECT_AUDIT.md` để biết phạm vi còn thiếu.
