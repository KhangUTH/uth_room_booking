import DetailModal from "../../../../components/DetailModal/DetailModal.jsx";
import keyboard from "../../../../assets/Equitment/keyboard.png";

function AssignmentMaintenance({ onClose }) {
    return (
        <>
            <DetailModal
                onClose={onClose}
                image={keyboard}
                status="Chờ Duyệt"
                name="Bàn Phím A4Tech KR-83"
                title="Thông Tin Đề Xuất Bảo Trì"
                showButtons={true}
                statusClass="maintenance-status"

                information={
                    <>
                        <p className="code">#BT - 001</p>

                        <p>
                            <i className="fa-solid fa-location-dot"></i>
                            <b>Phòng Máy - H004 - Khu H - Tầng Trệt</b>
                        </p>

                        <p>
                            <i className="fa-solid fa-screwdriver-wrench"></i>
                            <span><b>Loại Bảo Trì:</b> Bảo trì định kỳ</span>
                        </p>
                    </>
                }

                registration={
                    <div className="detail-columns">

                        <div className="detail-column">
                            <p>
                                <i className="fa-solid fa-user-check"></i>
                                <span><b>Người Đề Xuất:</b> Nguyễn Văn A</span>
                            </p>

                            <p>
                                <i className="fa-regular fa-id-card"></i>
                                <span><b>Vai Trò:</b> <strong >Nhân Viên Kỹ Thuật</strong></span>
                            </p>

                            <p>
                                <i className="fa-regular fa-credit-card"></i>
                                <span><b>Mã Số:</b> 077205001847</span>
                            </p>
                        </div>

                        <div className="detail-column">
                            <p>
                                <i className="fa-regular fa-calendar"></i>
                                <span><b>Thời Gian Đề Xuất:</b> 5/11/2026 8:00</span>
                            </p>

                            <p>
                                <i className="fa-solid fa-message"></i>
                                <span>
                                    <b>Nội Dung:</b> Bàn phím đã sử dụng trong thời gian dài,
                                    cần kiểm tra và bảo dưỡng.
                                </span>
                            </p>
                        </div>

                    </div>
                }
            />
        </>
    );
}

export default AssignmentMaintenance;
