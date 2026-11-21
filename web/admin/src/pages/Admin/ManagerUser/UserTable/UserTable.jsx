import Table from "../../../../components/Table/Table.jsx";

function UserTable({ onEdit }) {

        const columns = [
            { title: "STT", key: "stt" },

            { title: "Mã Số", key: "maSo" },

            { title: "Họ Và Tên", key: "hoTen" },

            {
                title: "Vai Trò",
                key: "vaiTro",
                render: (value, item) => (
                    <span className={item.roleClass}>
                        {value}
                    </span>
                )
            },

            { title: "Email", key: "email" },

            { title: "Số Điện Thoại", key: "soDienThoai" }
        ];

        const data = [
            {
                stt: "#001",
                maSo: "077205001847",
                hoTen: "Nguyễn Văn A",
                vaiTro: "Sinh Viên",
                roleClass: "common-student",
                email: "nva1847@ut.edu.vn",
                soDienThoai: "0123456789"
            },

            {
                stt: "#002",
                maSo: "077205001848",
                hoTen: "Trần Văn B",
                vaiTro: "Giảng Viên",
                roleClass: "common-teacher",
                email: "tvb1848@ut.edu.vn",
                soDienThoai: "0123456789"
            },

            {
                stt: "#003",
                maSo: "077205001849",
                hoTen: "Võ Thị C",
                vaiTro: "Nhân Viên Kỹ Thuật",
                roleClass: "common-technician",
                email: "vtc1849@ut.edu.vn",
                soDienThoai: "0123456789"
            }
        ];

        const actions = [
            {
                label: "Sửa",
                icon: "fa-regular fa-pen-to-square",
                className: "common-edit-button",
                onClick: onEdit
            },

            {
                label: "Xóa",
                icon: "fa-regular fa-trash-can",
                className: "common-delete-button"
            }
        ];
    
    return (
        <>
            <Table 
                columns={columns}
                data={data}
                actions={actions}
            />
        </>
    )
}

export default UserTable;