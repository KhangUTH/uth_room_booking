import "./TopBar.css";
import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import useAuth from "../../hooks/useAuth.js";
import { supabase } from "../../lib/supabase.js";
import { authErrorMessage } from "../../lib/authErrors.js";
import AdminPasswordDialog from "./AdminPasswordDialog.jsx";
import { StatusBadge } from "../Table/Table.jsx";
import { bookingAsset, bookingStatuses, countBookingsSince, displayDateTime, listBookings } from "../../pages/Admin/AdminOperations/operationsData.js";

function TopBar({ bookingRevision }) {
    const { user, profile, signOut } = useAuth();
    const menu = useRef(null);
    const account = useRef(null);
    const [accountOpen, setAccountOpen] = useState(false);
    const [changePassword, setChangePassword] = useState(false);
    const [accountMessage, setAccountMessage] = useState("");
    const [signingOut, setSigningOut] = useState(false);
    const [open, setOpen] = useState(false);
    const [rows, setRows] = useState(null);
    const [failed, setFailed] = useState(false);
    const [retry, setRetry] = useState(0);
    const [unseenCount, setUnseenCount] = useState(0);
    const [initialSeenAt] = useState(() => new Date().toISOString());
    const seenAt = useRef(initialSeenAt);
    const newBookings = open ? 0 : unseenCount;

    useEffect(() => {
        if (!supabase) return;
        const request = new AbortController();
        const timeout = setTimeout(() => request.abort(), 15000);
        let active = true;
        const startedAt = new Date().toISOString();
        const load = open
            ? listBookings(supabase, { status: "", type: "", date: "", search: "", page: 1 }, request.signal)
            .then(({ rows }) => {
                if (!active) return;
                setRows(rows);
                setFailed(false);
                seenAt.current = startedAt;
                setUnseenCount(0);
            })
            : countBookingsSince(supabase, seenAt.current, request.signal)
                .then((count) => { if (active) setUnseenCount(count ?? 0); });
        load.catch(() => { if (active && open) setFailed(true); })
            .finally(() => clearTimeout(timeout));
        return () => {
            active = false;
            clearTimeout(timeout);
            request.abort();
        };
    }, [open, bookingRevision, retry]);

    useEffect(() => {
        if (!open && !accountOpen) return;
        function dismiss(event) {
            if (event.type === "keydown" && event.key !== "Escape") return;
            for (const disclosure of [menu.current, account.current]) {
                if (!disclosure?.open || (event.type === "pointerdown" && disclosure.contains(event.target))) continue;
                disclosure.open = false;
                if (event.type === "keydown") disclosure.querySelector("summary")?.focus();
            }
        }
        document.addEventListener("pointerdown", dismiss);
        document.addEventListener("keydown", dismiss);
        return () => {
            document.removeEventListener("pointerdown", dismiss);
            document.removeEventListener("keydown", dismiss);
        };
    }, [open, accountOpen]);

    async function logout() {
        if (signingOut) return;
        setSigningOut(true);
        setAccountMessage("");
        try {
            await signOut();
        } catch (error) {
            setAccountMessage(authErrorMessage(error));
        } finally {
            setSigningOut(false);
        }
    }

    return (
        <>
            <header className="topbar">
                <div className="top-actions">
                    <span className="topbar-user" title={user?.email}>{profile?.full_name || user?.email}</span>
                    <details className="topbar-notices" ref={menu} onToggle={(event) => {
                        setOpen(event.currentTarget.open);
                    }}>
                        <summary className="icon-circle topbar-bell" aria-label={newBookings ? `Thông báo, ${newBookings} đăng ký mới` : "Thông báo"}>
                            <i className="fa-regular fa-bell" aria-hidden="true"></i>
                            {newBookings > 0 && <span className="topbar-notice-count" aria-hidden="true">{newBookings > 99 ? "99+" : newBookings}</span>}
                        </summary>
                        <section className="topbar-notice-panel" aria-label="Thông báo đặt lịch">
                            <h2>Thông báo</h2>
                            {failed && <button type="button" onClick={() => setRetry((value) => value + 1)}>Không tải được thông báo. Thử lại</button>}
                            {!failed && !rows && <p role="status">Đang tải…</p>}
                            {rows?.length === 0 && <p>Chưa có đăng ký lịch.</p>}
                            {rows?.length > 0 && <ul>
                                {rows.map((row) => <li key={row.id}>
                                    <Link to={`/managercalendar?ma=${row.id}`} onClick={() => { menu.current.open = false; }}>
                                        <strong>{bookingAsset(row)}</strong>
                                        <span>{row.requester_name || "Người đăng ký"} · {displayDateTime(row.start_time)}</span>
                                        <StatusBadge tone={bookingStatuses[row.status]?.tone}>{bookingStatuses[row.status]?.label || row.status}</StatusBadge>
                                    </Link>
                                </li>)}
                            </ul>}
                            <Link className="topbar-notice-all" to="/managercalendar" onClick={() => { menu.current.open = false; }}>Xem tất cả đăng ký</Link>
                        </section>
                    </details>

                    <details className="topbar-notices" ref={account} onToggle={(event) => setAccountOpen(event.currentTarget.open)}>
                        <summary className="icon-circle topbar-bell" aria-label="Tài khoản quản trị">
                            <i className="fa-regular fa-user" aria-hidden="true"></i>
                        </summary>
                        <section className="topbar-notice-panel topbar-account-panel" aria-label="Thông tin tài khoản">
                            <h2>{profile?.full_name || "Tài khoản"}</h2>
                            <p>{user?.email}</p>
                            <p className="topbar-account-role">Quản trị viên</p>
                            {accountMessage && <p role="status">{accountMessage}</p>}
                            <button type="button" onClick={() => {
                                account.current.open = false;
                                setAccountMessage("");
                                setChangePassword(true);
                            }}>Đổi mật khẩu</button>
                            <button type="button" onClick={logout} disabled={signingOut}>{signingOut ? "Đang đăng xuất…" : "Đăng xuất"}</button>
                        </section>
                    </details>
                </div>
            </header>
            {changePassword && <AdminPasswordDialog onClose={() => {
                setChangePassword(false);
                account.current?.querySelector("summary")?.focus();
            }} onSaved={() => {
                setChangePassword(false);
                setAccountMessage("Đã đổi mật khẩu.");
                account.current.open = true;
                account.current.querySelector("summary")?.focus();
            }} />}
        </>
    )
}

export default TopBar;
