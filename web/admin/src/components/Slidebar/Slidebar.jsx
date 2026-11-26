import { Link, NavLink } from "react-router-dom";
import { useState } from "react";
import useAuth from "../../hooks/useAuth.js";
import { authErrorMessage } from "../../lib/authErrors.js";
import './Slidebar.css';

const menuItems = [
    { to: "/", label: "Tổng quan", icon: "fa-solid fa-chart-line", end: true },
    { to: "/manageruser", label: "Người dùng", icon: "fa-solid fa-users" },
    { to: "/facilities", label: "Phòng & Thiết bị", icon: "fa-solid fa-building" },
    { to: "/managerassignment", label: "Theo dõi sự cố", icon: "fa-solid fa-screwdriver-wrench" },
    { to: "/managercalendar", label: "Đăng ký lịch", icon: "fa-regular fa-calendar-days" },
    { to: "/equipment-proposals", label: "Đề xuất bảo trì", icon: "fa-solid fa-clipboard-list" },
];

function Slidebar({ isOpen, setIsOpen }) {
    const { signOut } = useAuth();
    const [signingOut, setSigningOut] = useState(false);
    const [logoutError, setLogoutError] = useState("");

    async function handleSignOut() {
        if (signingOut) return;
        setSigningOut(true);
        setLogoutError("");
        try {
            await signOut();
        } catch (error) {
            setLogoutError(authErrorMessage(error));
        } finally {
            setSigningOut(false);
        }
    }

    function closeOnMobile() {
        if (window.matchMedia("(max-width: 767px)").matches) setIsOpen(false);
    }

    return (
        <aside className={`sidebar${isOpen ? "" : " close"}`} aria-label="Thanh điều hướng quản trị">
            <div className="sidebar-header">
                <Link className="sidebar-brand" to="/" onClick={closeOnMobile} aria-label="UTH - Tổng quan">
                    <img className="uth-brand-logo" src={`${import.meta.env.BASE_URL}uth-logo.jpg`} alt="" width="241" height="52" />
                </Link>
                <button className="sidebar-toggle" type="button" onClick={() => setIsOpen(!isOpen)}
                    aria-label={isOpen ? "Thu gọn thanh điều hướng" : "Mở rộng thanh điều hướng"}
                    aria-expanded={isOpen} aria-controls="admin-navigation"
                    title={isOpen ? "Thu gọn" : "Mở rộng"}>
                    <i className="fa-solid fa-bars" aria-hidden="true" />
                </button>
            </div>

            <nav className="sidebar-menu" id="admin-navigation" aria-label="Menu quản trị">
                {menuItems.map(({ to, label, icon, end }) => (
                    <NavLink key={to} to={to} end={end} onClick={closeOnMobile} title={label} aria-label={label}
                        className={({ isActive }) => `menu-item${isActive ? " active" : ""}`}>
                        <i className={icon} aria-hidden="true" />
                        <span>{label}</span>
                    </NavLink>
                ))}
            </nav>

            <div className="sidebar-footer">
                {logoutError && <p className="logout-error" role="alert">{logoutError}</p>}
                <button className="logout" type="button" onClick={handleSignOut} disabled={signingOut} title="Đăng xuất" aria-label="Đăng xuất">
                    <i className="fa-solid fa-right-from-bracket" aria-hidden="true" />
                    <span>{signingOut ? "Đang đăng xuất…" : "Đăng xuất"}</span>
                </button>
            </div>
        </aside>
    );
}

export default Slidebar;
