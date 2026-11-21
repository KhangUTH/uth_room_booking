import { useEffect, useRef, useState } from "react";
import { supabase } from "../../../lib/supabase.js";
import AssignmentTitle from "./AssignmentTitle/AssignmentTitle.jsx";
import AssignmentTable from "./AssignmentTable/AssignmentTable.jsx";
import AssignmentDetail from "./AssignmentDetail/AssignmentDetail.jsx";

export default function ManagerAssignment() {
    const [rows, setRows] = useState([]);
    const [selected, setSelected] = useState(null);
    const [page, setPage] = useState(1);
    const [count, setCount] = useState(0);
    const [search, setSearch] = useState("");
    const [filter, setFilter] = useState("");
    const [revision, setRevision] = useState(0);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState("");
    const [message, setMessage] = useState("");
    const mutation = useRef(false);

    useEffect(() => {
        const controller = new AbortController();
        const timer = setTimeout(async () => {
            setLoading(true);
            setError("");
            try {
                if (!supabase) throw new Error("Supabase chưa được cấu hình.");
                const reports = await supabase.rpc("admin_incident_reports", {
                        page_number: page, search_text: search.trim(), status_filter: filter,
                    }).abortSignal(controller.signal);
                if (reports.error) throw reports.error;
                if (controller.signal.aborted) return;
                setRows(reports.data.rows);
                setCount(reports.data.count);
            } catch {
                if (!controller.signal.aborted) {
                    setRows([]);
                    setError("Không tải được báo cáo. Kiểm tra quyền admin và cấu hình luồng duyệt trên Supabase rồi thử lại.");
                }
            } finally {
                if (!controller.signal.aborted) setLoading(false);
            }
        }, 250);
        return () => { clearTimeout(timer); controller.abort(); };
    }, [page, search, filter, revision]);

    async function approve(row) {
        if (mutation.current || row.approved_at || row.status !== "open") return;
        if (!window.confirm(`Duyệt báo cáo #SC-${String(row.report_number).padStart(4, "0")} để các kỹ thuật viên có thể nhận?`)) return;
        mutation.current = true;
        setSaving(true);
        setError("");
        setMessage("");
        try {
            const { error: failure } = await supabase.rpc("approve_incident_report", {
                report_id: row.id,
            });
            if (failure) throw failure;
            setMessage("Đã duyệt. Công việc đã vào hàng đợi chung cho các kỹ thuật viên.");
            setRevision((value) => value + 1);
        } catch {
            setError("Không duyệt được báo cáo. Báo cáo có thể đã thay đổi hoặc tài khoản không còn quyền. Tải lại để kiểm tra trước khi thử lại.");
        } finally {
            mutation.current = false;
            setSaving(false);
        }
    }

    const busy = loading || saving;
    return <>
        <AssignmentTitle search={search} filter={filter}
            onSearch={(value) => { setSearch(value); setPage(1); setLoading(true); }}
            onFilter={(value) => { setFilter(value); setPage(1); setLoading(true); }} />
        <section className="content" aria-busy={busy}>
            {error && <p role="alert">{error}</p>}
            {message && <p role="status">{message}</p>}
            <button type="button" disabled={busy} onClick={() => setRevision((value) => value + 1)}>Tải lại</button>
            {loading && <p role="status">Đang tải báo cáo…</p>}
            <AssignmentTable rows={rows} busy={busy} onView={setSelected} onApprove={approve} />
            <div className="pagination">
                <button type="button" disabled={busy || page === 1} onClick={() => { setPage(page - 1); setLoading(true); }}>Trước</button>
                <span>Trang {page} / {Math.max(1, Math.ceil(count / 10))} · {count} báo cáo</span>
                <button type="button" disabled={busy || page * 10 >= count} onClick={() => { setPage(page + 1); setLoading(true); }}>Sau</button>
            </div>
        </section>
        {selected && <AssignmentDetail report={selected} onClose={() => setSelected(null)} />}
    </>;
}
