import "./BoardTable.css";

function BoardTable() {
    return (
        <>
            <div className="dashboard-activity">
                <h3>
                    <i className="fa-regular fa-clock"></i>
                    Hoạt Động Gần Đây
                </h3>

                <div className="dashboard-table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>STT</th>
                                <th>Người Thực Hiện</th>
                                <th>Hoạt Động</th>
                                <th>Thời Gian</th>
                                <th>Trạng Thái</th>
                            </tr>
                        </thead>

                        <tbody>
                            <tr>
                                <td>#001</td>
                                <td>Nguyễn Văn A</td>
                                <td>Đăng ký phòng H003</td>
                                <td>09/11/2026 - 09:30</td>
                                <td>
                                    <span className="dashboard-status-done">
                                        <i className="fa-solid fa-gear"></i> Đang Sử Dụng
                                    </span>
                                </td>
                            </tr>

                            <tr>
                                <td>#002</td>
                                <td>Trần Văn B</td>
                                <td>Báo cáo sự cố máy chiếu</td>
                                <td>09/11/2026 - 09:15</td>
                                <td>
                                    <span className="dashboard-status-pending"> 
                                        <i className="fa-regular fa-clock"></i> Chờ Phân Công
                                    </span>
                                </td>
                            </tr>

                            <tr>
                                <td>#003</td>
                                <td>Phạm Văn C</td>
                                <td>Đăng ký thiết bị máy tính</td>
                                <td>09/11/2026 - 08:45</td>
                                <td>
                                    <span className="dashboard-status-done">
                                        <i className="fa-solid fa-gear"></i> Đang Sử Dụng
                                    </span>
                                </td>
                            </tr>

                            <tr>
                                <td>#004</td>
                                <td>Võ Văn D</td>
                                <td>Đề xuất bảo trì thiết bị</td>
                                <td>09/11/2026 - 08:20</td>
                                <td>
                                    <span className="dashboard-status-pending">
                                        <i className="fa-regular fa-clock"></i> Chờ Phân Công
                                    </span>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </>
    )
}

export default BoardTable;