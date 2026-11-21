import Detail from "../../../../components/Detail/Detail.jsx";
import H003 from "../../../../assets/Room/H003.jpg";

function RoomDetail({ onClose }) {
    return (
        <>
            <Detail
                image={H003}
                title="Phòng Máy - H003"
                status="Hoạt Động"
                statusIcon="fa-solid fa-square-check"
                statusColor="#26964b"
                onClose={onClose}
            >
                <div className="common-detail-item">
                    <i className="fa-solid fa-file-lines"></i>
                    <p>
                        <b>Mô Tả:</b> Phòng máy H003 được trang bị máy tính
                        và các thiết bị hỗ trợ phục vụ việc học tập,
                        thực hành và nghiên cứu.
                    </p>
                </div>

                <div className="common-detail-item">
                    <i className="fa-solid fa-location-dot"></i>
                    <p>
                        <b>Phòng Máy - H003 - Khu H - Tầng Trệt</b>
                    </p>
                </div>

                <div className="common-detail-item">
                    <i className="fa-solid fa-desktop"></i>
                    <p>
                        <b>Sức Chứa:</b> 40 máy
                    </p>
                </div>
            </Detail>
        </>
    )
}

export default RoomDetail;