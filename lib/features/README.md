# Tổ chức tính năng

Ứng dụng Flutter chỉ phục vụ ba vai trò: sinh viên (`student`), giảng viên
(`teacher`) và nhân viên kỹ thuật (`technician`). Admin sử dụng web quản trị riêng,
không có màn hình hoặc tính năng admin trong `lib/`.

Mỗi tính năng gồm `models/`, `data/`, `controllers/`, `presentation/`, `widgets/`.
Các thư mục chưa triển khai được giữ bằng `.gitkeep`, không đại diện cho chức năng đã hoàn tất.

- `auth`, `profile`, `splash`: các trang hiện có.
- `room`, `equipment`: tách từ `lists`; model và dữ liệu mẫu nằm trong từng tính năng.
- `technician`: giữ các trang, widget và model công việc hiện có.
- `booking`: khung đăng ký, xem lịch sử và hủy yêu cầu của người dùng app.
- `incident_report`: khung báo sự cố và theo dõi kết quả xử lý.

Duyệt đăng ký, quản lý tài khoản/tài sản, phân công kỹ thuật và thống kê thuộc web
quản trị. App nhận trạng thái duyệt, lịch phân công và kết quả xử lý từ backend dùng
chung. Vai trò `admin` được giữ trong thiết kế database để phục vụ web quản trị;
không thêm vai trò này vào `UserRole` của app.

`controllers/` dùng cho trạng thái/nghiệp vụ khi cần tách khỏi widget;
`data/` dùng cho repository khi thay dữ liệu mẫu bằng Supabase.
Giao diện dùng chung nằm trong `lib/shared/`; màu sắc và theme giữ tại `lib/theme/`.
