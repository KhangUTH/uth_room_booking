import "./TopBar.css";
import useAuth from "../../hooks/useAuth.js";

function TopBar() {
    const { user, profile } = useAuth();
    return (
        <>
            <header className="topbar">
                <div className="top-actions">
                    <span className="topbar-user" title={user?.email}>{profile?.full_name || user?.email}</span>
                    <button className="icon-circle">
                        <i className="fa-regular fa-bell"></i>
                    </button>

                    <button className="icon-circle">
                        <i className="fa-regular fa-user"></i>
                    </button>
                </div>
            </header>
        </>
    )
}

export default TopBar;
