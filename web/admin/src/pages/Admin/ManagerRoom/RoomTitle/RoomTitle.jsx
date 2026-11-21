import Title from "../../../../components/Title/Title.jsx";

function RoomTitle({ onAdd }) {
    return (
        <>
            <Title
                icon="fa-solid fa-desktop"
                title="QUẢN LÝ PHÒNG"
                placeholder="Tìm kiếm theo tên phòng, stt,..."
                buttonText="Thêm Phòng"
                onAdd={onAdd}
            >
                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Khu vực</option>
                        <option value="Khu H">Khu H</option>
                        <option value="Khu I">Khu I</option>
                        <option value="Khu K">Khu K</option>
                    </select>

                    <i className="fa-solid fa-chevron-down"></i>
                </div>

                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Trạng thái</option>
                        <option value="Hoạt Động">Hoạt Động</option>
                        <option value="Bảo Trì">Bảo Trì</option>
                    </select>

                    <i className="fa-solid fa-chevron-down"></i>
                </div>
            </Title>
        </>
    );
}

export default RoomTitle;
