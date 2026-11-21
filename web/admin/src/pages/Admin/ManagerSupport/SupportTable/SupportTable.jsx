import Table from "../../../../components/Table/Table.jsx";

function SupportTable() {

    const columns = [
        { title: "STT", key: "stt" },

        { title: "Họ Và Tên", key: "name" },

        { title: "Email", key: "email" },

        { title: "Nội Dung", key: "content" },

        {
            title: "Trạng Thái",
            key: "status",
            render: (value, item) => (
                <span className={item.statusClass}>
                    <i className={item.statusIcon}></i>
                    {value}
                </span>
            )
        }
    ];

    const data = [
        {
            stt: "#001",
            name: "Nguyễn Văn A",
            email: "nguyenvana@ut.edu.vn",
            content: "Cho em hỏi là cách đăng ký phòng máy như thế nào?",
            status: "Chưa Trả Lời",
            statusClass: "common-status-pending",
            statusIcon: "fa-regular fa-clock"
        },

        {
            stt: "#002",
            name: "Nguyễn Văn B",
            email: "nguyenvanb@ut.edu.vn",
            content: "Máy tính H003 bị lỗi không lên màn hình",
            status: "Đã Trả Lời",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {

            stt: "#003",
            name: "Nguyễn Thị C",
            email: "nguyenthic@ut.edu.vn",
            content: "Nhờ hỗ trợ về tài khoản đăng nhập hệ thống",
            status: "Đã Trả Lời",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },
        
        {
            stt: "#004",
            name: "Phạm Văn D",
            email: "phamvand@ut.edu.vn",
            content: "Hướng dẫn đặt lịch sử dụng thiết bị như thế nào?",
            status: "Chưa Trả Lời",
            statusClass: "common-status-pending",
            statusIcon: "fa-regular fa-clock"
        }
    ];

    const actions = [
        {
            label: "Xóa",
            icon: "fa-regular fa-trash-can",
            className: "common-delete-button"
        }
    ];

    return (
        <Table
            columns={columns}
            data={data}
            actions={actions}
        />
    );
}

export default SupportTable;
