import "./RoomForm.css";
import Form from "../../../../components/Form/Form.jsx";

function RoomForm({ onClose, isEdit }) {
    return (
        <>
            <Form
                title={isEdit ? "SỬA PHÒNG" : "THÊM PHÒNG"}
                icon={isEdit
                    ? "fa-regular fa-pen-to-square"
                    : "fa-solid fa-desktop"
                }
                onClose={onClose}
                buttonText={isEdit ? "Cập Nhật" : "Thêm Phòng"}
                buttonIcon={isEdit
                    ? "fa-regular fa-pen-to-square"
                    : "fa-solid fa-desktop"
                }
            >

                <div className="room-fields">

                    <div className="common-form-group">
                        <label>Tên Phòng</label>
                        <input
                            type="text"
                            placeholder="Nhập tên phòng..."
                        />
                    </div>

                    <div className="common-form-group">
                        <label>Trạng Thái</label>
                        <select>
                            <option value="">-- Chọn trạng thái --</option>
                            <option>Hoạt Động</option>
                            <option>Bảo Trì</option>
                        </select>
                    </div>

                    <div className="common-form-group">
                        <label>Khu Vực</label>
                        <select>
                            <option value="">-- Chọn khu vực --</option>
                            <option>Khu H</option>
                            <option>Khu I</option>
                            <option>Khu K</option>
                        </select>
                    </div>

                    <div className="common-form-group">
                        <label>Tầng</label>
                        <select>
                            <option value="">-- Chọn tầng --</option>
                            <option>Tầng Trệt</option>
                            <option>Tầng 1</option>
                            <option>Tầng 5</option>
                        </select>
                    </div>

                    <div className="common-form-group">
                        <label>Sức Chứa</label>
                        <input
                            type="number"
                            min="1"
                            placeholder="Nhập sức chứa..."
                        />
                    </div>
                </div>

                <div className="common-form-group room-image">
                    <label>Hình Ảnh Phòng</label>

                    <div className="common-form-upload">
                        <i className="fa-regular fa-image"></i>
                        <p>Chọn hình ảnh phòng</p>
                        <input type="file" accept="image/*" />
                    </div>
                </div>

                <div className="common-form-group room-description">
                    <label>Mô Tả</label>
                    <textarea
                        rows="3"
                        placeholder="Nhập mô tả về phòng..."
                    ></textarea>
                </div>

            </Form>
        </>
    )
}

export default RoomForm;