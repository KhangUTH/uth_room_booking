import Table from "../../../../components/Table/Table.jsx";
import computer from "../../../../assets/Equitment/computer.png";
import headphone from "../../../../assets/Equitment/headphone.png";
import keyboard from "../../../../assets/Equitment/keyboard.png";
import mouse from "../../../../assets/Equitment/mouse.png";
import micro from "../../../../assets/Equitment/micro.png";

function ToolTable({ onView, onEdit }) {

    const columns = [
        { title: "STT", key: "stt" },

        {   title: "Hình Ảnh", 
            key: "image",
            render: (image) => (
                <img src={image} alt="Ảnh" className="common-image"/>
            )
        },

        { title: "Tên Thiết Bị", key: "name" },

        { title: "Loại Thiết Bị", key: "type" },

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
            image: computer,
            name: "Máy Tính FPT Elead",
            type: "Máy tính",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#002",
            image: keyboard,
            name: "Bàn Phím A4Tech KR-83",
            type: "Bàn Phím",
            status: "Bảo Trì",
            statusClass: "common-status-maintenance",
            statusIcon: "fa-solid fa-wrench"
        },

        {
            stt: "#003",
            image: headphone,
            name: "Tai Nghe Logitech H340",
            type: "Tai Nghe",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#004",
            image: mouse,
            name: "Chuột Logitech M331 Silent Plus ",
            type: "Chuột",
            status: "Bảo Trì",
            statusClass: "common-status-maintenance",
            statusIcon: "fa-solid fa-wrench"
        },

        {
            stt: "#005",
            image: micro,
            name: "Micro TOA DM-1100",
            type: "Micro",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
        },

        {
            stt: "#006",
            image: micro,
            name: "Ổ Điện",
            type: "Ổ Điện",
            status: "Hoạt Động",
            statusClass: "common-status-active",
            statusIcon: "fa-solid fa-square-check"
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
        <>
            <Table 
                columns={columns}
                data={data}
                actions={actions}
            />
        </>
    )
}

export default ToolTable;