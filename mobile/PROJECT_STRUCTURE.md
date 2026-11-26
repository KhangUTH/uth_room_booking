# Cây thư mục và mã nguồn UTH Lab Mobile

Các đường dẫn trong cây tính từ thư mục `mobile/`. Tài liệu liệt kê toàn bộ file Dart trong `lib/`, `test/` và `integration_test/`, cùng các file cấu hình và mã Android/iOS chính. Các thư mục build, cache và file sinh tự động được lược khỏi cây.

- `lib/features/` chứa các tính năng. `presentation/` ghép màn hình, `widgets/` chứa phần giao diện nhỏ, `controllers/` điều phối trạng thái, `data/` truy cập dữ liệu và `models/` định nghĩa kiểu dữ liệu.
- `lib/core/` chứa route và kết nối với hệ điều hành. `lib/shared/` chứa giao diện và tiện ích thật sự dùng chung. `lib/theme/` tập trung màu và cỡ chữ.
- Phần Supabase dùng chung nằm ở thư mục `supabase/` tại gốc dự án.

```text
mobile/
├── android/
│   ├── app/
│   │   ├── src/
│   │   │   ├── debug/
│   │   │   │   └── AndroidManifest.xml  —  Khai báo cấu hình bổ sung khi chạy bản debug.
│   │   │   ├── main/
│   │   │   │   ├── kotlin/
│   │   │   │   │   └── com/
│   │   │   │   │       └── example/
│   │   │   │   │           └── uth_room_booking/
│   │   │   │   │               └── MainActivity.kt  —  Nối Flutter với quyền hệ thống, thông báo và Firebase trên Android.
│   │   │   │   ├── res/
│   │   │   │   │   ├── drawable/
│   │   │   │   │   │   ├── ic_notification.xml  —  Biểu tượng nhỏ dùng cho thông báo Android.
│   │   │   │   │   │   └── launch_background.xml  —  Nền khởi động mặc định của Android.
│   │   │   │   │   ├── drawable-v21/
│   │   │   │   │   │   └── launch_background.xml  —  Nền khởi động cho Android theo bộ tài nguyên v21.
│   │   │   │   │   ├── values/
│   │   │   │   │   │   └── styles.xml  —  Theme Android dùng khi khởi động và hiển thị app.
│   │   │   │   │   └── values-night/
│   │   │   │   │       └── styles.xml  —  Theme Android tương ứng khi hệ thống ở chế độ tối.
│   │   │   │   └── AndroidManifest.xml  —  Khai báo quyền, Activity và cấu hình ứng dụng Android.
│   │   │   └── profile/
│   │   │       └── AndroidManifest.xml  —  Khai báo cấu hình bổ sung khi chạy bản profile.
│   │   ├── build.gradle.kts  —  Cấu hình bản build, SDK và định danh ứng dụng Android.
│   │   └── google-services.json  —  Cấu hình Firebase client cho Android.
│   ├── build.gradle.kts  —  Cấu hình Gradle dùng chung cho Android.
│   └── settings.gradle.kts  —  Khai báo plugin Gradle và cấu trúc module Android.
├── assets/
│   └── images/
│       ├── ai_chat/  —  Chứa avatar và biểu tượng robot UTH AI.
│       ├── illustrations/  —  Chứa ảnh minh họa giao diện.
│       ├── logo/  —  Chứa logo dùng trong ứng dụng.
│       └── splash/  —  Chứa ảnh màn hình khởi động.
├── integration_test/
│   ├── account_roles_test.dart  —  Kiểm thử tích hợp đăng nhập và luồng tính năng theo vai trò.
│   └── README.md  —  Hướng dẫn chạy kiểm thử tích hợp và kiểm thử hệ thống.
├── ios/
│   ├── Flutter/
│   │   ├── AppFrameworkInfo.plist  —  Thông tin framework Flutter khi build iOS.
│   │   ├── Debug.xcconfig  —  Cấu hình biên dịch Flutter cho bản iOS debug.
│   │   └── Release.xcconfig  —  Cấu hình biên dịch Flutter cho bản iOS release.
│   ├── Runner/
│   │   ├── Base.lproj/
│   │   │   ├── LaunchScreen.storyboard  —  Dựng màn hình khởi động của iOS.
│   │   │   └── Main.storyboard  —  Khai báo giao diện gốc chứa màn hình Flutter.
│   │   ├── AppDelegate.swift  —  Khởi tạo Flutter và nối kênh quyền thiết bị trên iOS.
│   │   ├── Info.plist  —  Khai báo cấu hình ứng dụng và mô tả các quyền iOS.
│   │   └── SceneDelegate.swift  —  Quản lý vòng đời scene của ứng dụng iOS.
│   ├── Runner.xcodeproj/
│   │   └── project.pbxproj  —  Danh sách target, tài nguyên và các thiết lập build trong Xcode.
│   └── RunnerTests/
│       └── RunnerTests.swift  —  Chứa kiểm thử ở lớp iOS native.
├── lib/
│   ├── core/
│   │   ├── platform/
│   │   │   └── app_permissions.dart  —  Gọi Android/iOS để đọc quyền, mở Cài đặt và xử lý sự kiện push.
│   │   ├── router/
│   │   │   ├── app_route.dart  —  Định nghĩa tên route và kiểu đối số truyền giữa các màn hình.
│   │   │   └── app_router.dart  —  Tạo màn hình theo route và nối dữ liệu theo tài khoản đăng nhập.
│   │   └── README.md  —  Ghi chú về cấu trúc các thành phần nền tảng.
│   ├── features/
│   │   ├── ai_chat/
│   │   │   ├── controllers/
│   │   │   │   ├── chat_controller.dart  —  Gửi tin nhắn, thử lại, chuyển hội thoại và quản lý lịch sử trong phiên.
│   │   │   │   └── chat_voice_input.dart  —  Xin quyền micro và chuyển lời nói tiếng Việt thành nội dung nhập.
│   │   │   ├── data/
│   │   │   │   ├── chat_repository.dart  —  Định nghĩa giao diện nguồn phản hồi cho bộ điều phối chat.
│   │   │   │   ├── mock_chat_repository.dart  —  Trả phản hồi mẫu cho đặt phòng, thiết bị và sự cố, đồng thời tra lịch cá nhân.
│   │   │   │   └── technician_chat_repository.dart  —  Lọc công việc kỹ thuật theo trạng thái hoặc mức gấp để trả lời.
│   │   │   ├── models/
│   │   │   │   └── chat_message.dart  —  Định nghĩa tin nhắn, kiểu phản hồi và thông tin phòng trong chat.
│   │   │   ├── presentation/
│   │   │   │   └── chat_screen.dart  —  Dựng trang UTH AI và điều phối nhập liệu, lịch sử, đính kèm, điều hướng.
│   │   │   └── widgets/
│   │   │       ├── chat_avatar.dart  —  Hiển thị avatar, nút nổi và hiệu ứng gợn sóng, nháy mắt của robot.
│   │   │       ├── chat_bubble.dart  —  Dựng bong bóng tin nhắn và hiệu ứng ba chấm khi chờ phản hồi.
│   │   │       ├── chat_header.dart  —  Dựng AppBar UTH AI, nút quay lại và menu hội thoại.
│   │   │       ├── chat_history_sheet.dart  —  Hiển thị cuộc đang mở và danh sách cuộc trò chuyện trong phiên.
│   │   │       ├── chat_incident_draft_dialog.dart  —  Cho sửa, kiểm tra và xác nhận bản nháp báo cáo mẫu.
│   │   │       ├── chat_input_bar.dart  —  Dựng ô nhập, nút đính kèm, micro và nút gửi.
│   │   │       ├── chat_reply_cards.dart  —  Chọn thẻ phù hợp với phản hồi và chuyển thao tác về chat.
│   │   │       ├── chat_room_card.dart  —  Hiển thị phòng, ca, số máy trống và nút đặt trong chat.
│   │   │       ├── chat_turn.dart  —  Ghép câu hỏi, phản hồi, thẻ kết quả và nút sao chép của một lượt chat.
│   │   │       └── chat_welcome.dart  —  Hiển thị lời chào và các câu hỏi gợi ý theo vai trò.
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_store.dart  —  Đăng nhập Supabase bằng mã hoặc email, đọc hồ sơ, khôi phục mật khẩu và đăng xuất.
│   │   │   │   └── remembered_session_storage.dart  —  Lưu và khôi phục phiên ghi nhớ bằng bộ nhớ bảo mật.
│   │   │   ├── models/
│   │   │   │   └── user_role.dart  —  Định nghĩa ba vai trò mobile và cách nhận diện vai trò.
│   │   │   ├── presentation/
│   │   │   │   └── login_page.dart  —  Điều phối màn đăng nhập, chuyển vai trò và khôi phục phiên.
│   │   │   └── widgets/
│   │   │       ├── academic_login_form.dart  —  Dựng ô nhập tài khoản và mật khẩu cho sinh viên, giảng viên.
│   │   │       ├── login_password_options.dart  —  Hiển thị tùy chọn ghi nhớ đăng nhập và quên mật khẩu.
│   │   │       ├── password_recovery_dialog.dart  —  Dựng các bước nhập email, xác minh OTP và đặt lại mật khẩu.
│   │   │       └── technician_login_sheet.dart  —  Dựng bảng trượt đăng nhập dành cho nhân viên kỹ thuật.
│   │   ├── booking/
│   │   │   ├── controllers/
│   │   │   │   └── booking_controller.dart  —  Quản lý lịch cá nhân, ca trống, đăng ký, hủy và tra cứu lịch cho UTH AI.
│   │   │   ├── data/
│   │   │   │   ├── asset_catalog.dart  —  Tải danh mục phòng và thiết bị, cùng điều kiện sử dụng theo vai trò.
│   │   │   │   ├── booking_store.dart  —  Đọc, tạo, hủy lịch và tra ca bận, lớp học phần qua Supabase.
│   │   │   │   └── sample_booking_data.dart  —  Cung cấp phòng, thiết bị, lớp và lịch mẫu cho chế độ demo.
│   │   │   ├── models/
│   │   │   │   └── booking.dart  —  Định nghĩa tài sản, ca, trạng thái và câu hỏi tra cứu lịch.
│   │   │   ├── presentation/
│   │   │   │   ├── booking_history_page.dart  —  Hiển thị lịch sử đăng ký phòng và thiết bị.
│   │   │   │   └── schedule_view.dart  —  Điều phối màn Lịch với ngày, ca và ba mục Phòng máy, Thiết bị, Của tôi.
│   │   │   └── widgets/
│   │   │       ├── booking_action_dialogs.dart  —  Mở bảng xác nhận đăng ký và hộp thoại xác nhận hủy.
│   │   │       ├── booking_asset_card.dart  —  Hiển thị một phòng hoặc thiết bị cùng trạng thái của ca.
│   │   │       ├── booking_asset_list.dart  —  Ghép bộ chọn ca với danh sách tài sản có thể đăng ký.
│   │   │       ├── booking_calendar.dart  —  Hiển thị ngày và dấu chỉ báo lịch trong tuần.
│   │   │       ├── booking_category_tabs.dart  —  Dựng thanh chuyển nhóm lịch theo dạng tab bo tròn.
│   │   │       ├── booking_confirmation_sheet.dart  —  Xác nhận phòng hoặc thiết bị, số người hoặc lớp học phần trước khi gửi.
│   │   │       ├── booking_hint.dart  —  Hiển thị lưu ý lần đầu, thông báo thao tác và gợi ý đặt lịch.
│   │   │       ├── booking_history_card.dart  —  Hiển thị thông tin, trạng thái và chi tiết một lượt đăng ký.
│   │   │       ├── booking_panel.dart  —  Cung cấp kiểu khung nền và viền chung cho các thẻ lịch.
│   │   │       ├── booking_slot_picker.dart  —  Hiển thị các ca và số tài sản trống để người dùng chọn.
│   │   │       ├── booking_status_badge.dart  —  Dựng nhãn trạng thái nhỏ có màu theo dữ liệu đầu vào.
│   │   │       └── my_bookings_section.dart  —  Hiển thị danh sách Của tôi và bộ lọc tất cả ngày.
│   │   ├── equipment/
│   │   │   ├── data/
│   │   │   │   └── sample_devices.dart  —  Cung cấp danh sách thiết bị mẫu.
│   │   │   ├── models/
│   │   │   │   └── device.dart  —  Định nghĩa dữ liệu thiết bị dùng cho màn danh sách.
│   │   │   └── presentation/
│   │   │       └── device_list_page.dart  —  Hiển thị danh mục thiết bị.
│   │   ├── home/
│   │   │   ├── presentation/
│   │   │   │   └── home_dashboard.dart  —  Dựng Trang chủ sinh viên và giảng viên, nối lịch, lịch sử và thông báo.
│   │   │   └── widgets/
│   │   │       ├── home_action_cards.dart  —  Dựng các thẻ lối tắt và hàng thẻ ở Trang chủ.
│   │   │       ├── home_notice_card.dart  —  Hiển thị tóm tắt một thông báo trên Trang chủ.
│   │   │       └── home_stats_card.dart  —  Hiển thị số lịch sắp tới, đang sử dụng và đã sử dụng.
│   │   ├── incident_report/
│   │   │   ├── data/
│   │   │   │   └── incident_report_store.dart  —  Tạo, đọc, hủy báo cáo và quản lý ảnh minh chứng qua Supabase.
│   │   │   ├── models/
│   │   │   │   └── incident_report.dart  —  Định nghĩa dữ liệu báo cáo, trạng thái và lựa chọn tài sản.
│   │   │   ├── presentation/
│   │   │   │   └── incident_report_view.dart  —  Điều phối tạo báo cáo, xem báo cáo đã gửi và làm mới trạng thái.
│   │   │   └── widgets/
│   │   │       ├── incident_inline_menu.dart  —  Dựng danh sách xổ xuống trong form báo cáo.
│   │   │       ├── incident_photo_field.dart  —  Hiển thị ảnh minh chứng, trạng thái tải và thao tác thay hoặc gỡ ảnh.
│   │   │       ├── incident_photo_picker.dart  —  Mở bảng chọn camera hoặc thư viện rồi đọc dữ liệu ảnh.
│   │   │       ├── incident_report_controls.dart  —  Dựng lựa chọn loại sự cố và công tắc hỗ trợ trong giờ dạy.
│   │   │       ├── incident_report_details_sheet.dart  —  Hiển thị chi tiết, ảnh minh chứng và thao tác của báo cáo.
│   │   │       ├── incident_report_form.dart  —  Dựng và xác thực form tạo báo cáo của sinh viên, giảng viên.
│   │   │       ├── incident_report_history.dart  —  Hiển thị danh sách Báo cáo của tôi.
│   │   │       ├── incident_report_labels.dart  —  Dựng nhãn trạng thái, tiêu đề trường và định dạng thời gian.
│   │   │       ├── incident_report_progress.dart  —  Hiển thị các bước chờ tiếp nhận, xử lý và hoàn tất.
│   │   │       └── incident_reporter_card.dart  —  Hiển thị avatar, tên và vai trò của người báo cáo.
│   │   ├── notifications/
│   │   │   ├── data/
│   │   │   │   ├── notice_store.dart  —  Tải thông báo, lưu trạng thái đọc và đồng bộ tùy chọn push.
│   │   │   │   └── sample_notices.dart  —  Cung cấp thông báo mẫu theo nhóm người dùng.
│   │   │   ├── models/
│   │   │   │   └── app_notice.dart  —  Định nghĩa dữ liệu và trường liên kết của thông báo.
│   │   │   ├── presentation/
│   │   │   │   ├── notice_navigation.dart  —  Mở đúng chi tiết báo cáo, công việc hoặc đề xuất từ thông báo.
│   │   │   │   └── notifications_view.dart  —  Điều phối hộp thư, tìm kiếm, lọc, đánh dấu và xóa thông báo.
│   │   │   └── widgets/
│   │   │       ├── notice_card.dart  —  Dựng thẻ thông báo và trạng thái đã đọc hoặc chưa đọc.
│   │   │       ├── notice_details_sheet.dart  —  Hiển thị chi tiết thông báo và nội dung liên quan.
│   │   │       └── notice_search_filters.dart  —  Dựng ô tìm kiếm và các bộ lọc hộp thư.
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   │   ├── profile_avatar_storage.dart  —  Đọc, tải lên và quản lý ảnh đại diện qua Supabase Storage.
│   │   │   │   └── profile_contact_store.dart  —  Đọc, cập nhật thông tin liên hệ và hỗ trợ đổi mật khẩu.
│   │   │   ├── presentation/
│   │   │   │   ├── app_permissions_page.dart  —  Hiển thị quyền thiết bị và làm mới trạng thái khi quay lại app.
│   │   │   │   ├── profile_avatar_controller.dart  —  Điều phối tải, cập nhật và hiển thị avatar dùng chung.
│   │   │   │   ├── profile_support_page.dart  —  Dựng Trung tâm trợ giúp, điều khoản và liên hệ hỗ trợ.
│   │   │   │   └── profile_view.dart  —  Điều phối thông tin cá nhân, tùy chọn push, mật khẩu và đăng xuất.
│   │   │   └── widgets/
│   │   │       ├── edit_profile_dialog.dart  —  Dựng hộp thoại chỉnh thông tin và đổi mật khẩu.
│   │   │       └── profile_sections.dart  —  Cung cấp tiêu đề nhóm, khung và hàng thông tin của trang Cá nhân.
│   │   ├── room/
│   │   │   ├── data/
│   │   │   │   └── sample_rooms.dart  —  Cung cấp danh sách phòng mẫu.
│   │   │   ├── models/
│   │   │   │   └── room.dart  —  Định nghĩa dữ liệu phòng dùng cho màn danh sách.
│   │   │   └── presentation/
│   │   │       └── room_list_page.dart  —  Hiển thị danh mục phòng.
│   │   ├── splash/
│   │   │   ├── presentation/
│   │   │   │   └── splash_screen.dart  —  Dựng màn khởi động và chuyển tiếp sau khi ứng dụng sẵn sàng.
│   │   │   └── widgets/
│   │   │       └── splash_ring_painters.dart  —  Vẽ các vòng trang trí cho màn khởi động.
│   │   ├── technician/
│   │   │   ├── controllers/
│   │   │   │   ├── maintenance_proposal_controller.dart  —  Quản lý tải, gửi và trạng thái đề xuất bảo trì.
│   │   │   │   └── technician_work_controller.dart  —  Quản lý danh sách công việc và làm mới khi tab kỹ thuật đang hiển thị.
│   │   │   ├── data/
│   │   │   │   ├── demo_incident_queue.dart  —  Chia sẻ báo cáo mẫu giữa màn người gửi và kỹ thuật viên trong chế độ demo.
│   │   │   │   ├── maintenance_proposal_store.dart  —  Đọc và ghi đề xuất bảo trì qua Supabase.
│   │   │   │   └── technician_incident_store.dart  —  Tải công việc, ảnh minh chứng và cập nhật tiến độ sự cố qua Supabase.
│   │   │   ├── models/
│   │   │   │   ├── maintenance_proposal.dart  —  Định nghĩa đề xuất bảo trì và trạng thái xét duyệt.
│   │   │   │   ├── task_filter.dart  —  Định nghĩa và áp dụng các bộ lọc công việc kỹ thuật.
│   │   │   │   └── technician_task.dart  —  Định nghĩa công việc, trạng thái xử lý và dữ liệu công việc mẫu.
│   │   │   ├── presentation/
│   │   │   │   ├── maintenance_proposals_page.dart  —  Hiển thị danh sách đề xuất và mở form tạo đề xuất.
│   │   │   │   ├── task_details_page.dart  —  Hiển thị chi tiết sự cố và thao tác nhận hoặc hoàn tất công việc.
│   │   │   │   ├── task_evidence_page.dart  —  Hiển thị ảnh minh chứng ở màn xem riêng.
│   │   │   │   ├── technician_assets_page.dart  —  Hiển thị phòng và thiết bị kỹ thuật viên phụ trách.
│   │   │   │   ├── technician_dashboard.dart  —  Dựng thống kê, lối tắt và công việc cần chú ý của kỹ thuật viên.
│   │   │   │   ├── technician_home_content.dart  —  Ghép dashboard, danh mục phụ trách và phần đề xuất bảo trì.
│   │   │   │   └── technician_work_view.dart  —  Hiển thị danh sách công việc và nhóm bộ lọc kỹ thuật.
│   │   │   └── widgets/
│   │   │       ├── maintenance_asset_field.dart  —  Dựng ô chọn phòng hoặc thiết bị trong form đề xuất.
│   │   │       ├── maintenance_proposal_card.dart  —  Hiển thị tóm tắt đề xuất và mở trang chi tiết.
│   │   │       ├── maintenance_proposal_details_sheet.dart  —  Hiển thị đầy đủ nội dung và trạng thái đề xuất đã gửi.
│   │   │       ├── maintenance_proposal_dialog.dart  —  Dựng form tạo đề xuất với tài sản và lý do bảo trì.
│   │   │       ├── task_details.dart  —  Mở màn chi tiết công việc và cung cấp nhãn trạng thái dùng chung.
│   │   │       ├── technician_asset_card.dart  —  Dựng thẻ phòng hoặc thiết bị và nhãn hoạt động, bảo trì.
│   │   │       ├── technician_attention_card.dart  —  Hiển thị công việc cần chú ý trên Trang chủ kỹ thuật viên.
│   │   │       ├── technician_page_title.dart  —  Cung cấp tiêu đề đồng bộ cho các trang kỹ thuật.
│   │   │       ├── technician_panel.dart  —  Cung cấp kiểu khung chung cho giao diện kỹ thuật.
│   │   │       ├── technician_task_card.dart  —  Hiển thị tóm tắt công việc, trạng thái và thao tác nhanh.
│   │   │       └── technician_task_overview.dart  —  Dựng phần tóm tắt vị trí, trạng thái và thông tin công việc.
│   │   └── README.md  —  Quy ước tổ chức mã theo tính năng.
│   ├── shared/
│   │   ├── images/
│   │   │   └── encode_jpeg_photo.dart  —  Đổi ảnh sang JPEG, giảm kích thước và nén trước khi tải.
│   │   ├── layouts/
│   │   │   ├── bottom_navigation_bar.dart  —  Dựng thanh điều hướng dưới dùng chung theo danh sách tab.
│   │   │   ├── header.dart  —  Dựng AppBar chính với danh tính, avatar và chuông thông báo.
│   │   │   ├── main_shell.dart  —  Điều phối các tab theo vai trò, điều hướng UTH AI và vòng đời controller.
│   │   │   └── shell_catalog_content.dart  —  Quản lý tải lại danh mục và trạng thái chờ, lỗi hoặc thử lại.
│   │   └── widgets/
│   │       ├── evidence_photos.dart  —  Dựng vùng hiển thị ảnh minh chứng dùng chung.
│   │       └── pill_tabs.dart  —  Cung cấp thanh tab dạng pill dùng lại ở nhiều tính năng.
│   ├── theme/
│   │   ├── app_colors.dart  —  Tập trung các màu chủ đạo, nền, chữ và bảng màu UTH AI.
│   │   ├── app_text_sizes.dart  —  Tập trung các cỡ chữ giao diện dùng chung.
│   │   └── app_theme.dart  —  Khai báo theme Material cho màu, nút, ô nhập và thông báo.
│   └── main.dart  —  Khởi tạo app, cấu hình Supabase, theo dõi điều hướng và khôi phục phiên.
├── test/
│   ├── support/
│   │   └── widget_test_helpers.dart  —  Cung cấp tiện ích giả lập kích thước màn hình và dọn widget khi test.
│   ├── auth_widget_test.dart  —  Kiểm tra đăng nhập, khôi phục mật khẩu và đổi tài khoản trên widget.
│   ├── booking_widget_test.dart  —  Kiểm tra quy tắc đặt lịch, lịch cá nhân và các luồng UTH AI.
│   ├── incident_report_widget_test.dart  —  Kiểm tra tạo, gửi lại và xem báo cáo sự cố.
│   ├── shell_widget_test.dart  —  Kiểm tra điều hướng, thông báo, làm mới lịch và trạng thái quyền micro.
│   └── technician_widget_test.dart  —  Kiểm tra công việc, đề xuất và tra cứu UTH AI của kỹ thuật viên.
├── analysis_options.yaml  —  Khai báo quy tắc phân tích tĩnh và lint Dart.
├── devtools_options.yaml  —  Cấu hình Flutter DevTools cho dự án.
├── pubspec.lock  —  Khóa phiên bản dependencies đã resolve.
└── pubspec.yaml  —  Khai báo dependencies, assets và metadata ứng dụng.
```
