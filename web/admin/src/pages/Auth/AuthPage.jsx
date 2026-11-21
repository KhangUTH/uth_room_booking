import { useState } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import useAuth from "../../hooks/useAuth.js";
import { isSupabaseConfigured, supabase } from "../../lib/supabase.js";
import { authErrorMessage } from "../../lib/authErrors.js";
import "./AuthPage.css";

export default function AuthPage() {
  const { pathname, state } = useLocation();
  const navigate = useNavigate();
  const { session, loading, profileLoading, isAdmin, accessError, refreshProfile, signIn, signOut } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const forgot = pathname === "/forgot-password";
  const reset = pathname === "/reset-password";
  const from = state?.from;
  const destination = from?.pathname?.startsWith("/") && !from.pathname.startsWith("//")
    && !["/login", "/forgot-password", "/reset-password"].includes(from.pathname)
    ? `${from.pathname}${from.search || ""}${from.hash || ""}` : "/";

  if (loading || (!forgot && !reset && profileLoading)) return <div className="auth-loading" role="status">Đang kiểm tra quyền truy cập…</div>;
  if (session && isAdmin && !forgot && !reset) return <Navigate to={destination} replace />;

  async function switchAccount() {
    if (pending) return;
    setPending(true);
    setError("");
    try {
      await signOut();
      setPassword("");
    } catch (requestError) {
      setError(authErrorMessage(requestError));
    } finally {
      setPending(false);
    }
  }

  async function handleSubmit(event) {
    event.preventDefault();
    if (pending || !isSupabaseConfigured) return;
    setError("");
    setNotice("");
    if (reset && password !== confirmPassword) {
      setError("Mật khẩu xác nhận không khớp.");
      return;
    }
    setPending(true);
    try {
      if (forgot) {
        const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim(), {
          redirectTo: `${window.location.origin}/reset-password`,
        });
        if (resetError) throw resetError;
        setNotice("Nếu email này có tài khoản, bạn sẽ nhận được liên kết đặt lại mật khẩu. Vui lòng kiểm tra cả thư mục spam.");
      } else if (reset) {
        const { error: updateError } = await supabase.auth.updateUser({ password });
        if (updateError) throw updateError;
        navigate("/", { replace: true });
      } else {
        await signIn(email.trim(), password);
      }
    } catch (requestError) {
      setError(authErrorMessage(requestError));
    } finally {
      setPending(false);
    }
  }

  const denied = Boolean(session) && !forgot && !reset;
  const title = forgot ? "Quên mật khẩu?" : reset ? "Đặt mật khẩu mới" : denied ? "Chưa thể truy cập" : "Đăng nhập quản trị";
  const description = forgot
    ? "Nhập email tài khoản để nhận hướng dẫn khôi phục mật khẩu."
    : reset ? "Chọn mật khẩu mới để tiếp tục sử dụng hệ thống."
      : denied ? `Bạn đang đăng nhập bằng ${session.user.email}.`
        : "Dành cho quản trị viên hệ thống phòng học và lịch sử dụng tại UTH.";
  const invalidRecovery = reset && !session;

  return (
    <main className="auth-page">
      <section className="auth-intro" aria-label="UTH Booking Room">
        <div className="auth-brand"><span className="auth-logo">UTH</span><span>BOOKING ROOM</span></div>
        <div className="auth-intro-content">
          <span className="auth-eyebrow">HỆ THỐNG QUẢN LÝ PHÒNG</span>
          <h1>Không gian học tập.<br />Kết nối hiệu quả.</h1>
          <p>Quản lý phòng học, thiết bị và lịch sử dụng trong một không gian làm việc thống nhất.</p>
          <div className="auth-features">
            <span><i className="fa-regular fa-calendar-check" aria-hidden="true" /> Theo dõi lịch sử dụng phòng</span>
            <span><i className="fa-solid fa-desktop" aria-hidden="true" /> Quản lý phòng và thiết bị</span>
            <span><i className="fa-solid fa-users" aria-hidden="true" /> Phối hợp và hỗ trợ công việc</span>
          </div>
        </div>
        <p className="auth-footer">UTH · Hệ thống đặt và quản lý phòng</p>
      </section>

      <section className="auth-panel" aria-labelledby="auth-title">
        <div className="auth-card">
          <span className="auth-eyebrow">CỔNG TRUY CẬP</span>
          <h2 id="auth-title">{title}</h2>
          <p className="auth-description">{description}</p>

          {!isSupabaseConfigured && <p className="auth-message auth-error" role="alert">Chưa cấu hình kết nối Supabase. Vui lòng thiết lập VITE_SUPABASE_URL và VITE_SUPABASE_PUBLISHABLE_KEY trong .env.local rồi khởi động lại ứng dụng.</p>}
          {invalidRecovery && <p className="auth-message auth-error" role="alert">Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. <Link to="/forgot-password">Yêu cầu liên kết mới</Link>.</p>}
          {error && <p className="auth-message auth-error" role="alert">{error}</p>}
          {notice && <p className="auth-message auth-success" role="status">{notice}</p>}

          {denied ? <div className="auth-access-denied">
            <p className="auth-message auth-error" role="alert">{accessError}</p>
            <button className="auth-submit" type="button" onClick={refreshProfile} disabled={pending}>Kiểm tra lại quyền truy cập</button>
            <button className="auth-secondary" type="button" onClick={switchAccount} disabled={pending}>{pending ? "Đang đăng xuất…" : "Đăng xuất và đổi tài khoản"}</button>
          </div> : <>

          <form onSubmit={handleSubmit}>
            <fieldset disabled={pending || !isSupabaseConfigured || invalidRecovery}>
              {!reset && <div className="auth-field">
                <label htmlFor="email">Địa chỉ email</label>
                <input id="email" name="email" type="email" autoComplete="username" placeholder="email@uth.edu.vn" value={email} onChange={(event) => setEmail(event.target.value)} required autoFocus />
              </div>}
              {!forgot && <div className="auth-field">
                <label htmlFor="password">{reset ? "Mật khẩu mới" : "Mật khẩu"}</label>
                <div className="auth-password">
                  <input id="password" name="password" type={showPassword ? "text" : "password"} autoComplete={reset ? "new-password" : "current-password"} placeholder={reset ? "Ít nhất 8 ký tự" : "Nhập mật khẩu của bạn"} minLength={reset ? 8 : undefined} value={password} onChange={(event) => setPassword(event.target.value)} required />
                  <button type="button" onClick={() => setShowPassword(!showPassword)} aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"} aria-pressed={showPassword}>{showPassword ? "Ẩn" : "Hiện"}</button>
                </div>
              </div>}
              {reset && <div className="auth-field">
                <label htmlFor="confirm-password">Xác nhận mật khẩu mới</label>
                <input id="confirm-password" name="confirmPassword" type={showPassword ? "text" : "password"} autoComplete="new-password" minLength={8} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} required />
              </div>}
              {!forgot && !reset && <div className="auth-options"><Link to="/forgot-password">Quên mật khẩu?</Link></div>}
              <button className="auth-submit" type="submit" aria-busy={pending}>{pending ? "Đang xử lý…" : forgot ? "Gửi liên kết khôi phục" : reset ? "Lưu mật khẩu mới" : "Đăng nhập"}</button>
            </fieldset>
          </form>
          </>}
          {forgot || reset
            ? <Link className="auth-back" to="/login">← Quay lại đăng nhập</Link>
            : <p className="auth-help">Chưa có tài khoản? Liên hệ quản trị viên để được cấp quyền truy cập.</p>}
        </div>
      </section>
    </main>
  );
}
