# Quy tắc tổ chức mã Flutter

- Khi chỉnh giao diện hoặc logic, ưu tiên sửa và tái sử dụng các file hiện có. Chỉ tạo file mới hoặc tách sang file mới khi người dùng yêu cầu rõ.

- Trước khi thêm tính năng hoặc sửa màn hình, đọc mã hiện có và [cấu trúc các tính năng](lib/features/README.md). Đặt mã mới trong thư mục của tính năng phụ trách.
- Giữ bố cục cấp màn hình, điều hướng và trạng thái cấp màn hình trong `presentation/`. Dùng các file hiện có trong `widgets/` cho form, danh sách, thẻ, hộp thoại và bottom sheet phù hợp.
- Đặt quy tắc nghiệp vụ trong controller hoặc model hiện có. Đặt dữ liệu mẫu và phần truy cập dữ liệu trong `data/` của tính năng. Đưa widget vào `shared/` khi nhiều tính năng thực sự dùng chung.
- Khi sửa file có nhiều trách nhiệm, giữ các phần liên quan gần nhau và tách thành widget hoặc hàm trong file hiện có nếu giúp dễ đọc.
- Sau khi tách file, cập nhật import và các nơi gọi. Chạy `flutter analyze` và các kiểm thử Flutter liên quan để xác nhận luồng vẫn hoạt động.
