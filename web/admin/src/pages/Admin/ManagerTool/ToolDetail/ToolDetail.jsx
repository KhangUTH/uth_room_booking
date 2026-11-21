import keyboard from "../../../../assets/Equitment/keyboard.png";
import Detail from "../../../../components/Detail/Detail.jsx";

function ToolDetail({ onClose }) {
    return (
        <>
            <Detail
                image={keyboard}
                title="Bàn Phím A4Tech KR-83"
                status="Bảo Trì"
                statusIcon="fa-solid fa-wrench"
                statusColor="#1900ff"
                onClose={onClose}
            >
                <div className="common-detail-item">
                    <i className="fa-solid fa-file-lines"></i>
                    <p>
                        <b>Mô Tả:</b> Bàn phím được trang bị nhằm hỗ trợ soạn thảo văn bản 
                        và thực hiện các thao tác điều khiển máy tính trong quá trình học tập và giảng dạy.
                    </p>
                </div>

                <div className="common-detail-item">
                    <i className="fa-solid fa-location-dot"></i>
                    <p>
                        <b>Phòng Máy - H003 - Khu H - Tầng Trệt</b>
                    </p>
                </div>

                <div className="common-detail-item">
                    <i className="fa-solid fa-layer-group"></i>
                    <p>
                        <b>Loại Thiết Bị:</b> Máy chiếu
                    </p>
                </div>
            </Detail>
        </>
    )
}

export default ToolDetail;