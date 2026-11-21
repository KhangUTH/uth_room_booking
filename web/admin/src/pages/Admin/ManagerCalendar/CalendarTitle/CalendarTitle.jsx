import Title from "../../../../components/Title/Title.jsx";

function CalendarTitle() {
    return (
        <>
            <Title
                icon="fa-regular fa-calendar-days"
                title="QUẢN LÝ ĐĂNG KÝ LỊCH"
                placeholder="Tìm kiếm theo tên, vai trò,..."
            >
                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Loại đăng ký</option>
                        <option value="Thiết Bị">Thiết Bị</option>
                        <option value="Phòng Máy">Phòng Máy</option>
                    </select>

                    <i className="fa-solid fa-chevron-down"></i>
                </div>

                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Trạng Thái</option>
                        <option value="Chờ Duyệt">Chờ Duyệt</option>
                        <option value="Đang Sử Dụng">Đang Sử Dụng</option>
                        <option value="Đã Sử Dụng">Đã Sử Dụng</option>
                    </select>

                    <i className="fa-solid fa-chevron-down"></i>
                </div>
            </Title>
        </>
    );
}

export default CalendarTitle;
