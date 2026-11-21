import "./ToolForm.css";
import Form from "../../../../components/Form/Form.jsx";

function ToolForm({ onClose, isEdit }) {
    return (
        <>
            <Form
                title={isEdit ? "SỬA THIẾT BỊ" : "THÊM THIẾT BỊ"}
                icon={isEdit
                    ? "fa-regular fa-pen-to-square"
                    : "fa-solid fa-hard-drive"
                }
                onClose={onClose}
                buttonText={isEdit ? "Cập Nhật" : "Thêm Thiết Bị"}
                buttonIcon={isEdit
                    ? "fa-regular fa-pen-to-square"
                    : "fa-solid fa-hard-drive"
                }
            >

                <div className="tool-fields">

                    <div className="common-form-group">
                        <label>Tên Thiết Bị</label>
                        <input
                            type="text"
                            placeholder="Nhập tên thiết bị..."
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
                        <label>Loại Thiết Bị</label>
                        <select>
                            <option value="">-- Chọn loại thiết bị --</option>
                            <option>Máy tính</option>
                            <option>Máy chiếu</option>
                            <option>Máy in</option>
                            <option>Thiết bị mạng</option>
                        </select>
                    </div>

                    <div className="common-form-group">
                        <label>Tên Phòng</label>
                        <select>
                            <option value="">-- Chọn phòng --</option>
                            <option>Phòng Máy - H003</option>
                            <option>Phòng Máy - H004</option>
                            <option>Phòng Máy - H509</option>
                            <option>Phòng Thư Viện</option>
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
                        <label>Khu Vực</label>
                        <select>
                            <option value="">-- Chọn khu vực --</option>
                            <option>Khu H</option>
                            <option>Khu I</option>
                            <option>Khu K</option>
                        </select>
                    </div>

                </div>

                <div className="common-form-group tool-image">
                    <label>Hình Ảnh Thiết Bị</label>

                    <div className="common-form-upload">
                        <i className="fa-regular fa-image"></i>
                        <p>Chọn hình ảnh thiết bị</p>
                        <input type="file" accept="image/*" />
                    </div>
                </div>

                <div className="common-form-group tool-description">
                    <label>Mô Tả</label>
                    <textarea
                        rows="3"
                        placeholder="Nhập mô tả về thiết bị..."
                    ></textarea>
                </div>

            </Form>
        </>
    )
}

export default ToolForm;