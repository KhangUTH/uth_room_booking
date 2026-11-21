import { lazy, Suspense } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import ProtectedRoute from "../components/ProtectedRoute.jsx";
import AuthPage from "../pages/Auth/AuthPage.jsx";
import MainLayoutAdmin from "../layouts/MainLayoutAdmin.jsx";
import FacilitiesLayout from "../layouts/FacilitiesLayout.jsx";
import ManagerUser from "../pages/Admin/ManagerUser/ManagerUser.jsx";
import ManagerRoom from "../pages/Admin/ManagerRoom/ManagerRoom.jsx";
import ManagerTool from "../pages/Admin/ManagerTool/ManagerTool.jsx";
import ManagerAssignment from "../pages/Admin/ManagerAssignment/ManagerAssignment.jsx";

const AdminOperations = lazy(() => import("../pages/Admin/AdminOperations/AdminOperations.jsx"));

function OperationsRoute({ screen }) {
    return <Suspense fallback={<p className="content" role="status">Đang mở trang…</p>}>
        <AdminOperations key={screen} screen={screen} />
    </Suspense>;
}

function AppRouters() {
    return (
        <Routes>
            <Route path="/login" element={<AuthPage key="login" />} />
            <Route path="/forgot-password" element={<AuthPage key="forgot" />} />
            <Route path="/reset-password" element={<AuthPage key="reset" />} />
            <Route element={<ProtectedRoute />}>
                <Route element={<MainLayoutAdmin />}>
                    <Route index element={<OperationsRoute screen="overview" />} />
                    <Route path="/manageruser" element={<ManagerUser />} />
                    <Route path="/managersupport" element={<OperationsRoute screen="support" />} />
                    <Route path="/managercalendar" element={<OperationsRoute screen="bookings" />} />
                    <Route path="/managerassignment" element={<ManagerAssignment />} />
                    <Route path="/facilities" element={<FacilitiesLayout />}>
                        <Route index element={<Navigate to="rooms" replace />} />
                        <Route path="rooms" element={<ManagerRoom />} />
                        <Route path="equipment" element={<ManagerTool />} />
                    </Route>
                    <Route path="/managerroom" element={<Navigate to="/facilities/rooms" replace />} />
                    <Route path="/managertool" element={<Navigate to="/facilities/equipment" replace />} />
                </Route>
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
    );
}

export default AppRouters;
