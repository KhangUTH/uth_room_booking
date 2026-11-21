import { Navigate, Outlet, useLocation } from "react-router-dom";
import useAuth from "../hooks/useAuth.js";

export default function ProtectedRoute() {
  const { session, loading, profileLoading, isAdmin } = useAuth();
  const location = useLocation();

  if (loading || profileLoading) return <div className="auth-loading" role="status">Đang kiểm tra quyền truy cập…</div>;
  if (!session || !isAdmin) return <Navigate to="/login" state={{ from: location }} replace />;
  return <Outlet />;
}
