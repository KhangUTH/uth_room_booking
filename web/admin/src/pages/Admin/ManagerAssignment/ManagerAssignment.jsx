import { useEffect, useRef, useState } from "react";
import { useOutletContext, useSearchParams } from "react-router-dom";
import { supabase } from "../../../lib/supabase.js";
import AssignmentTitle from "./AssignmentTitle/AssignmentTitle.jsx";
import AssignmentTable from "./AssignmentTable/AssignmentTable.jsx";
import AssignmentDetail from "./AssignmentDetail/AssignmentDetail.jsx";
import Pagination from "../../../components/Pagination/Pagination.jsx";
import "../../../components/AdminRecords/AdminRecords.css";
import "../../../layouts/FacilitiesLayout.css";

const assetTabs = [
    { value: "", label: "Tất cả tài sản", icon: "fa-solid fa-list" },
    { value: "room", label: "Phòng máy", icon: "fa-solid fa-door-open" },
    { value: "equipment", label: "Thiết bị", icon: "fa-solid fa-hard-drive" },
];

export default function ManagerAssignment() {
    const [params] = useSearchParams();
    const number = params.get("ma");
    const status = params.get("trang-thai");
    const type = params.get("loai");
    const [rows, setRows] = useState([]);
    const [selected, setSelected] = useState(null);
    const [page, setPage] = useState(1);
    const [count, setCount] = useState(0);
    const [search, setSearch] = useState(() => /^\d+$/.test(number ?? "") ? `#SC-${number}` : "");
    const [filter, setFilter] = useState(() => ["open", "in_progress"].includes(status) ? status : "");
    const [assetType, setAssetType] = useState(() => type === "all" ? "" : type === "equipment" ? "equipment" : "room");
    const [revision, setRevision] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const photoCache = useRef(new Map());
    const previousSearch = useRef(search);
    const live = useOutletContext();
    const liveRevision = (live?.all ?? 0) + (live?.incident_reports ?? 0) + (live?.profiles ?? 0)
        + (live?.rooms ?? 0) + (live?.equipment ?? 0);
    const selectedId = selected?.id;
    const selectedNumber = selected?.report_number;

    useEffect(() => {
        const typing = previousSearch.current !== search;
        previousSearch.current = search;
        const controller = new AbortController();
        let active = true;
        const timer = setTimeout(async () => {
            const timeout = setTimeout(() => controller.abort(), 12000);
            setError("");
            try {
                if (!supabase) throw new Error("Supabase chưa được cấu hình.");
                const reports = await supabase.rpc("admin_incident_reports", {
                        page_number: page, search_text: search.trim(), status_filter: filter, asset_filter: assetType,
                    }).abortSignal(controller.signal);
                if (reports.error) throw reports.error;
                if (controller.signal.aborted) {
                    if (active) setError("Kết nối chậm. Bấm Tải lại để thử lại.");
                    return;
                }
                setRows(reports.data.rows);
                setCount(reports.data.count);
            } catch {
                if (active) {
                    setError(controller.signal.aborted
                        ? "Kết nối chậm. Bấm Tải lại để thử lại."
                        : "Không tải được báo cáo. Vui lòng thử lại.");
                }
            } finally {
                clearTimeout(timeout);
                if (active) setLoading(false);
            }
        }, typing ? 250 : 0);
        return () => {
            active = false;
            clearTimeout(timer);
            controller.abort();
        };
    }, [page, search, filter, assetType, revision, liveRevision]);

    useEffect(() => {
        if (!selectedId || selectedNumber == null || !supabase) return;
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 15000);
        supabase.rpc("admin_incident_reports", {
            page_number: 1, search_text: `#SC-${selectedNumber}`, status_filter: "",
        }).abortSignal(controller.signal).then(({ data }) => {
            if (controller.signal.aborted) return;
            const current = data?.rows?.find((report) => report.id === selectedId);
            if (current) setSelected((previous) => previous?.id === selectedId ? current : previous);
        }).catch(() => {}).finally(() => clearTimeout(timeout));
        return () => { clearTimeout(timeout); controller.abort(); };
    }, [selectedId, selectedNumber, liveRevision]);

    const busy = loading;
    return <>
        <AssignmentTitle search={search} filter={filter}
            onSearch={(value) => { setSearch(value); setPage(1); setLoading(true); }}
            onFilter={(value) => { setFilter(value); setPage(1); setLoading(true); }}
            loading={loading}
            onReload={() => {
                setLoading(true);
                setRevision((value) => value + 1);
            }} />
        <section className="content data-management" aria-busy={busy}>
            <div className="facilities-tabs incident-asset-tabs" role="group" aria-label="Loại tài sản báo sự cố">
                {assetTabs.map(({ value, label, icon }) => (
                    <button key={value} type="button"
                        className={`facilities-tab${assetType === value ? " active" : ""}`}
                        aria-pressed={assetType === value}
                        onClick={() => {
                            if (assetType === value) return;
                            setAssetType(value);
                            setPage(1);
                            setRows([]);
                            setCount(0);
                            setError("");
                            setLoading(true);
                        }}>
                        <i className={icon} aria-hidden="true" /> {label}
                    </button>
                ))}
            </div>
            {error && <p role="alert">{error}</p>}
            {loading && <p role="status">Đang tải báo cáo…</p>}
            <AssignmentTable rows={rows} busy={busy} assetType={assetType} onView={setSelected} />
            <Pagination page={page} count={count} busy={busy} label="Phân trang báo cáo"
                onChange={(next) => { setPage(next); setLoading(true); }} />
        </section>
        {selected && <AssignmentDetail key={selected.id} report={selected} photoCache={photoCache} onClose={() => setSelected(null)} />}
    </>;
}
