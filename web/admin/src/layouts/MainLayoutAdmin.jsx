import Slidebar from "../components/Slidebar/Slidebar.jsx";
import TopBar from "../components/TopBar/TopBar.jsx";
import { Outlet } from "react-router-dom";
import useOpen from "../hooks/useOpen.js";

function MainLayoutAdmin({ children }) {
    const { isOpen, setIsOpen } = useOpen(() =>
        typeof window === "undefined" || window.matchMedia("(min-width: 768px)").matches
    );
    return (
        <div className={`app-container${isOpen ? "" : " sidebar-collapsed"}`}>

            <Slidebar isOpen={isOpen} setIsOpen={setIsOpen} />

            <main className="main-content">

                <TopBar />
                {children ?? <Outlet />}
                
            </main>
        </div>
    );
}

export default MainLayoutAdmin;

