import { useRef, useState } from "react";
import { authErrorMessage } from "../../lib/authErrors.js";
import { supabase } from "../../lib/supabase.js";
import DataDialog from "../AdminRecords/DataDialog.jsx";
import "../AdminRecords/AdminRecords.css";

const fields = [
    ["current", "Mật khẩu hiện tại", "current-password"],
    ["next", "Mật khẩu mới", "new-password"],
    ["confirmation", "Xác nhận mật khẩu mới", "new-password"],
];

export default function AdminPasswordDialog({ onClose, onSaved }) {
    const pending = useRef(false);
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState("");

    async function submit(event) {
        event.preventDefault();
        if (pending.current) return;
        const data = new FormData(event.currentTarget);
        const current = data.get("current");
        const next = data.get("next");
        if (next !== data.get("confirmation")) {
            setError("Mật khẩu xác nhận không khớp.");
            return;
        }
        if (current === next) {
            setError("Mật khẩu mới phải khác mật khẩu hiện tại.");
            return;
        }
        pending.current = true;
        setBusy(true);
        setError("");
        try {
            const { error: failure } = await supabase.auth.updateUser({ current_password: current, password: next });
            if (failure) throw failure;
            onSaved();
        } catch (failure) {
            setError(authErrorMessage(failure));
        } finally {
            pending.current = false;
            setBusy(false);
        }
    }

    return <DataDialog title="Đổi mật khẩu" busy={busy} onClose={onClose}>
        <form onSubmit={submit}>
            <div className="data-dialog-body">
                <fieldset disabled={busy}>
                    {fields.map(([key, label, autoComplete]) => <div className="form-group" key={key}>
                        <label htmlFor={`admin-password-${key}`}>{label}</label>
                        <input id={`admin-password-${key}`} name={key} type="password"
                            autoComplete={autoComplete} minLength={key === "current" ? undefined : 8} required />
                    </div>)}
                </fieldset>
                {error && <p className="data-error" role="alert">{error}</p>}
            </div>
            <div className="data-dialog-footer">
                <button type="button" disabled={busy} onClick={onClose}>Hủy</button>
                <button type="submit" className="data-primary" disabled={busy}>{busy ? "Đang lưu…" : "Đổi mật khẩu"}</button>
            </div>
        </form>
    </DataDialog>;
}
