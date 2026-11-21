import Title from "../../../../components/Title/Title.jsx";

function ToolTitle({ onAdd }) {
    return (
        <>
            <Title
                icon="fa-solid fa-hard-drive"
                title="QUẢN LÝ THIẾT BỊ"
                placeholder="Tìm kiếm theo tên thiết bị, loại,..."
                buttonText="Thêm Thiết Bị"
                onAdd={onAdd}
            >
                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Loại thiết bị</option>
                        <option value="Máy Tính">Máy Tính</option>
                        <option value="Máy Chiếu">Máy Chiếu</option>
                        <option value="Máy In">Máy In</option>
                        <option value="Switch">Switch</option>
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

export default ToolTitle;
