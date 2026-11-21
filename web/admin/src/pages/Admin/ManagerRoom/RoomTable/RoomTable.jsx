import Table from "../../../../components/Table/Table.jsx";
import H003 from "../../../../assets/Room/H003.jpg";
import H509 from "../../../../assets/Room/H509.jpg";
import library from "../../../../assets/Room/library.jpg";
import I001 from "../../../../assets/Room/I001.jpg";
import I002 from "../../../../assets/Room/I002.jpg";

function RoomTable({ onView, onEdit }) {

    const columns = [
        { title: "STT", key: "stt" },

        {   title: "Hình Ảnh", 
            key: "image",
            render: (image) => (
                <img src={image} alt="Ảnh" className="common-image"/>
            )
        },

        { title: "Tên Phòng", key: "name" },

        { title: "Khu Vực", key: "area" },

        { title: "Sức Chứa", key: "capacity" },

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
            image: H003,
            name: "Phòng Máy - H003",
            area: "Khu H - Tầng Trệt",
            capacity: "40 máy",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#002",
            image: H509,
            name: "Phòng Máy - H509",
            area: "Khu H - Tầng 5",
            capacity: "40 máy",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#003",
            image: library,
            name: "Phòng Thư Viện",
            area: "Khu K - Tầng 1",
            capacity: "22 máy",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#004",
            image: I001,
            name: "Phòng Máy - I001",
            area: "Khu I - Tầng Trệt",
            capacity: "40 máy",
            status: "Bảo Trì",
            statusClass: "common-status-maintenance",
            statusIcon: "fa-solid fa-wrench"
        },

        {
            stt: "#005",
            image: I002,
            name: "Phòng Máy - I002",
            area: "Khu I - Tầng Trệt",
            capacity: "40 máy",
            status: "Bảo Trì",
            statusClass: "common-status-maintenance",
            statusIcon: "fa-solid fa-wrench"
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
            label: "Sửa",
            icon: "fa-regular fa-pen-to-square",
            className: "common-edit-button",
            onClick: onEdit
        },

        {
            label: "Xóa",
            icon: "fa-solid fa-trash-can",
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

export default RoomTable;
