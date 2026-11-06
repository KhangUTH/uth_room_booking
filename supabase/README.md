# Database Supabase

Thư mục này là khung quản lý database theo `he_thong_dat_lich_quan_li.md`.
Chưa có migration tạo bảng, policy RLS, bucket Storage hoặc kết nối đến Supabase hosted.
Ứng dụng Flutter vẫn sử dụng dữ liệu demo.

Backend dự kiến dùng chung cho app Flutter (sinh viên, giảng viên, nhân viên kỹ
thuật) và web quản trị riêng (admin). Thiết kế database vẫn có bốn vai trò để lưu
người duyệt, người phân công và kiểm soát quyền; app chỉ có ba vai trò sử dụng.
Mã nguồn web quản trị được quản lý riêng, chưa được tạo trong repository này.

## Cấu trúc

```text
supabase/
├── config.toml       # Cấu hình local tối thiểu, không chứa khóa bí mật
├── migrations/       # Migration SQL có thứ tự thời gian khi triển khai schema
├── seed.sql          # Điểm vào dữ liệu mẫu, hiện chỉ có chú thích
├── tests/database/   # Nơi đặt kiểm thử database khi có schema
└── README.md
```

## Chuẩn bị môi trường local

Cần cài Supabase CLI và Docker trước khi chạy từ thư mục gốc dự án:

```sh
supabase start
```

`config.toml` hiện chỉ xác định project local và đường dẫn seed; các thiết lập còn lại
dùng mặc định CLI. Có thể bổ sung cổng, Auth redirect và dịch vụ cần dùng sau khi
chốt môi trường phát triển. Không chạy `supabase init` ghi đè cấu hình hiện có.

## Thứ tự triển khai database

Tạo migration mới khi bắt đầu triển khai từng nhóm, ví dụ:

```sh
supabase migration new create_profiles
```

1. `create_profiles`: hồ sơ liên kết Supabase Auth, vai trò và trạng thái tài khoản.
2. `create_rooms_and_equipment`: phòng, thiết bị, mã tài sản và tình trạng vận hành.
3. `create_bookings`: đơn, phòng/thiết bị trong đơn và lịch sử nhận/trả.
4. `create_incidents_and_assignments`: sự cố, ảnh đính kèm và phạm vi phụ trách.
5. `create_maintenance_and_repair_logs`: đề xuất bảo trì, công việc và nhật ký sửa chữa.
6. `create_booking_rules`: giao dịch duyệt và ràng buộc chống trùng lịch.
7. `enable_rls_and_policies`: quyền theo người dùng, vai trò và phân công.
8. `configure_storage`: bucket ảnh riêng tư và quyền truy cập.

Không tạo file migration rỗng để đánh dấu các chức năng đã hoàn thành. Chỉ kết nối
client đến dữ liệu thật khi các ràng buộc và chính sách phân quyền đã được kiểm tra.
Không đưa khóa quản trị vào Flutter hoặc repository.

## Kiểm tra khi đã có schema

- Chạy migration trên môi trường local thử nghiệm trước.
- Kiểm tra quyền của ba vai trò app và vai trò admin trên web quản trị riêng.
- Kiểm tra người dùng app không thể tự nâng quyền, duyệt đơn hoặc phân công kỹ thuật.
- Kiểm tra tài khoản admin không được mở phiên sử dụng app khi tích hợp Auth thật;
  backend vẫn kiểm tra quyền cho mọi thao tác quản trị.
- Kiểm tra truy cập dữ liệu người khác và đồng bộ trạng thái từ web về app.
- Kiểm tra đặt/duyệt trùng phòng, thiết bị bằng hai phiên đồng thời.
- Kiểm tra trạng thái đơn, thời gian nhận/trả, phạm vi kỹ thuật viên và ảnh sự cố.

Chi tiết bảng và nghiệp vụ nằm ở mục 4 của tài liệu hệ thống. Hướng dẫn chính thức:
[cấu hình CLI](https://supabase.com/docs/guides/local-development/cli/config),
[database migrations](https://supabase.com/docs/guides/deployment/database-migrations).
