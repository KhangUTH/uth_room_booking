import "./BoardActive.css";

function BoardActive() {
    return (
        <>
            <div className="dashboard-content">

                <div className="dashboard-box">
                    <h3>
                        <i className="fa-solid fa-clipboard-check"></i>
                        Thống Kê Đăng Ký
                    </h3>

                    <div className="dashboard-stat-row">
                        <span>Đã Duyệt</span>
                        <div className="dashboard-progress">
                            <div className="dashboard-progress-done"></div>
                        </div>
                        <b>65%</b>
                    </div>

                    <div className="dashboard-stat-row">
                        <span>Chờ Duyệt</span>
                        <div className="dashboard-progress">
                            <div className="dashboard-progress-pending"></div>
                        </div>
                        <b>25%</b>
                    </div>

                    <div className="dashboard-stat-row">
                        <span>Đã Từ Chối</span>
                        <div className="dashboard-progress">
                            <div className="dashboard-progress-rejected"></div>
                        </div>
                        <b>10%</b>
                    </div>
                </div>

                <div className="dashboard-box">
                    <h3>
                        <i className="fa-solid fa-screwdriver-wrench"></i>
                        Thống Kê Sự Cố
                    </h3>

                    <div className="dashboard-incident-row">
                        <span className="dashboard-dot pending"></span>
                        <span>Chờ Phân Công</span>
                        <b>03</b>
                    </div>

                    <div className="dashboard-incident-row">
                        <span className="dashboard-dot processing"></span>
                        <span>Đang Xử Lý</span>
                        <b>05</b>
                    </div>

                    <div className="dashboard-incident-row">
                        <span className="dashboard-dot completed"></span>
                        <span>Đã Hoàn Thành</span>
                        <b>20</b>
                    </div>
                </div>

            </div>
        </>
    )
}

export default BoardActive;