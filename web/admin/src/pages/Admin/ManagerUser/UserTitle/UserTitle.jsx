import Title from "../../../../components/Title/Title.jsx";

function UserTitle({ onAdd }) {
    return (
        <>
            <Title
                icon="fa-solid fa-users"
                title="QUẢN LÝ NGƯỜI DÙNG"
                placeholder="Tìm kiếm theo tên, mã số,..."
                buttonText="Thêm Người Dùng"
                onAdd={onAdd}
            >
                <div className="filter-box">
                    <select defaultValue="">
                        <option value="">Vai trò</option>
                        <option value="Sinh Viên">Sinh Viên</option>
                        <option value="Giảng Viên">Giảng Viên</option>
                        <option value="Nhân Viên Kỹ Thuật">
                            Nhân Viên Kỹ Thuật
                        </option>
                    </select>

                    <i className="fa-solid fa-chevron-down"></i>
                </div>
            </Title>
        </>
    );
}

export default UserTitle;
