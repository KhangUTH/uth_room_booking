import Table from "../../../../components/Table/Table.jsx";

function CalendarTable({ onView }) {

    const columns = [
        { title: "STT", key: "stt" },

        { title: "Họ Và Tên", key: "name" },

        {
            title: "Vai Trò",
            key: "role",
            render: (value, item) => (
                <span className={item.roleClass}>
                    {value}
                </span>
            )
        },

        { title: "Loại Đăng Ký", key: "type" },
        
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
            role: "Sinh Viên",
            roleClass: "common-student",
            type: "Thiết Bị",
            status: "Chờ Duyệt",
            statusClass: "common-status-pending",
            statusIcon: "fa-regular fa-clock"
        },

        {
            stt: "#002",
            name: "Nguyễn Văn B",
            role: "Giảng Viên",
            roleClass: "common-teacher",
            type: "Phòng Máy",
            status: "Đã Sử Dụng",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#003",
            name: "Nguyễn Thị C",
            role: "Sinh Viên",
            roleClass: "common-student",
            type: "Thiết Bị",
            status: "Đang Sử Dụng",
            statusClass: "common-status-maintenance",
            statusIcon: "fa-solid fa-gear"
        },

        {
            stt: "#004",
            name: "Phạm Văn D",
            role: "Giảng Viên",
            roleClass: "common-teacher",
            type: "Phòng Máy",
            status: "Chờ Duyệt",
            statusClass: "common-status-pending",
            statusIcon: "fa-regular fa-clock"
        }
    ];

    const actions = [
        {
            label: "Xem",
            icon: "fa-regular fa-eye",
            className: "common-view-button",
            onClick: onView
        },
        
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

export default CalendarTable;
