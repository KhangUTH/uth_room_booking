import Title from "../../../../components/Title/Title.jsx";

function SupportTitle() {
    return (
        <>
            <Title
                icon="fa-solid fa-headset"
                title="QUẢN LÝ TRỢ GIÚP"
                placeholder="Tìm kiếm theo họ tên, email,..."
            >
                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Trạng Thái</option>
                        <option value="Chưa Trả Lời">Chưa Trả Lời</option>
                        <option value="Đã Trả Lời">Đã Trả Lời</option>
                    </select>

                    <i className="fa-solid fa-chevron-down"></i>
                </div>
            </Title>
        </>
    );
}

export default SupportTitle;
