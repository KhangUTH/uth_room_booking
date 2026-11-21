import "./BoardTitle.css";
import { Link } from "react-router-dom";

function BoardTitle() {
    return (
        <>
            <div className="dashboard-title">
                <i className="fa-solid fa-chart-line"></i>
                <h1>DASHBOARD</h1>
            </div>

            <div className="dashboard-cards">

                <Link to="/facilities/rooms" className="dashboard-card">
                    <div className="dashboard-card-icon">
                        <i className="fa-solid fa-desktop"></i>
                    </div>
                    <div>
                        <p>Tổng Số Phòng</p>
                        <h2>25</h2>
                    </div>
                </Link>

                <Link to="/facilities/equipment" className="dashboard-card">
                    <div className="dashboard-card-icon">
                        <i className="fa-solid fa-hard-drive"></i>
                    </div>
                    <div>
                        <p>Tổng Thiết Bị</p>
                        <h2>350</h2>
                    </div>
                </Link>

                <Link to="/managercalendar" className="dashboard-card">
                    <div className="dashboard-card-icon">
                        <i className="fa-regular fa-calendar-days"></i>
                    </div>
                    <div>
                        <p>Đăng Ký Chờ Duyệt</p>
                        <h2>12</h2>
                    </div>
                </Link>

                <Link to="/managerassignment" className="dashboard-card">
                    <div className="dashboard-card-icon">
                        <i className="fa-solid fa-triangle-exclamation"></i>
                    </div>
                    <div>
                        <p>Sự Cố Chưa Xử Lý</p>
                        <h2>08</h2>
                    </div>
                </Link>

            </div>
        </>
    )
}

export default BoardTitle;
