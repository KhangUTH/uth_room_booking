import { NavLink, Outlet } from "react-router-dom";
import "./FacilitiesLayout.css";

export default function FacilitiesLayout() {
    return (
        <section className="facilities-layout" aria-label="Phòng và thiết bị">
            <nav className="facilities-tabs" aria-label="Chuyển trang phòng và thiết bị">
                <NavLink to="/facilities/rooms" className={({ isActive }) => `facilities-tab${isActive ? " active" : ""}`}>
                    <i className="fa-solid fa-door-open" aria-hidden="true" />
                    Phòng
                </NavLink>
                <NavLink to="/facilities/equipment" className={({ isActive }) => `facilities-tab${isActive ? " active" : ""}`}>
                    <i className="fa-solid fa-hard-drive" aria-hidden="true" />
                    Thiết bị
                </NavLink>
            </nav>
            <Outlet />
        </section>
    );
}
