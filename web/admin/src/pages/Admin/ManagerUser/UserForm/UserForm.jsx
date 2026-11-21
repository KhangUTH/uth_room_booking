
import Form from "../../../../components/Form/Form.jsx";

function UserForm({ onClose, isEdit }) {
    return (
        <>
            <Form
                title={isEdit ? "SỬA NGƯỜI DÙNG" : "THÊM NGƯỜI DÙNG"}
                icon={isEdit
                    ? "fa-regular fa-pen-to-square"
                    : "fa-solid fa-user-plus"
                }
                onClose={onClose}
                buttonText={isEdit ? "Cập Nhật" : "Thêm Người Dùng"}
                buttonIcon={isEdit
                    ? "fa-regular fa-pen-to-square"
                    : "fa-solid fa-user-plus"
                }
                width="650px"
            >

                <div className="form-group">
                    <label>Họ và tên</label>
                    <input
                        type="text"
                        placeholder="Nhập họ và tên"
                    />
                </div>

                <div className="form-row">
                    <div className="form-group">
                        <label>Mã người dùng</label>
                        <input
                            type="text"
                            placeholder="Nhập mã người dùng"
                        />
                    </div>

                    <div className="form-group">
                        <label>Số điện thoại</label>
                        <input
                            type="text"
                            placeholder="Nhập số điện thoại"
                        />
                    </div>
                </div>

                <div className="form-group">
                    <label>Email</label>
                    <input
                        type="email"
                        placeholder="Nhập địa chỉ email"
                    />
                </div>

                <div className="form-row">
                    <div className="form-group">
                        <label>Vai trò</label>
                        <select>
                            <option value="">-- Chọn vai trò --</option>
                            <option>Sinh viên</option>
                            <option>Giảng viên</option>
                            <option>Nhân viên kỹ thuật</option>
                        </select>
                    </div>
                </div>

            </Form>
        </>
    );
}

export default UserForm;
