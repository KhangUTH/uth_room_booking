# Quy tắc tổ chức mã Flutter

- Bám sát phạm vi yêu cầu. Tái sử dụng hàm, widget, controller và lớp dữ liệu hiện có nếu đáp ứng đúng nhu cầu. Không thêm mã trùng lặp, helper không có nơi gọi, trạng thái không dùng hoặc chỉnh các phần không liên quan.

- Trước khi thêm tính năng hoặc sửa màn hình, đọc mã hiện có và [cấu trúc các tính năng](mobile/lib/features/README.md). Đặt mã mới trong thư mục của tính năng phụ trách.
- Giữ bố cục cấp màn hình, điều hướng và trạng thái cấp màn hình trong `presentation/`. Dùng các file hiện có trong `widgets/` cho form, danh sách, thẻ, hộp thoại và bottom sheet phù hợp.
- Đặt quy tắc nghiệp vụ trong controller hoặc model hiện có. Đặt dữ liệu mẫu và phần truy cập dữ liệu trong `data/` của tính năng. Đưa widget vào `shared/` khi nhiều tính năng thực sự dùng chung.
- Không dồn trách nhiệm mới vào màn hình hoặc file đang phụ trách nhiều việc. Ưu tiên chuyển logic hoặc giao diện vào file hiện có đúng chức năng. Khi người dùng yêu cầu tách file, tách theo trách nhiệm rõ ràng và chỉ tạo file có nơi sử dụng.
- Trước khi hoàn tất, rà lại diff để phát hiện mã trùng, import dư và phần thay đổi ngoài phạm vi. Khi tách file, cập nhật các nơi gọi và bỏ phần triển khai cũ đã được thay thế. Giữ các tính năng đang phát triển trừ khi người dùng yêu cầu xóa. Chạy `flutter analyze` và các kiểm thử Flutter liên quan khi sửa mã Flutter.
