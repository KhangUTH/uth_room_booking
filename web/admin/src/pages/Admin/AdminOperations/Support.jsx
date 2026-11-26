import { useCallback, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { StatusBadge } from "../../../components/Table/Table.jsx";
import Pagination from "../../../components/Pagination/Pagination.jsx";
import { supabase } from "../../../lib/supabase.js";
import { countPendingSupport, displayDate, displayDateTime, emptyPage, listSupport, pageSize, readSupport, replyToSupport, supportStatuses } from "./operationsData.js";
import { Heading, Icon, QueryError, Status } from "./OperationsUi.jsx";
import useAdminQuery from "./useAdminQuery.js";

const fetchSupportCount = (signal) => countPendingSupport(supabase, signal);
const supportSetup = "Chưa cấu hình hộp thư hỗ trợ trên Supabase (SQL bước 07).";

function TicketDetail({ ticket, onSaved, headingRef }) {
  const [reply, setReply] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function save(event) {
    event.preventDefault();
    if (!reply.trim() || busy) return;
    setBusy(true);
    setError(null);
    try {
      await replyToSupport(supabase, ticket.id, reply.trim());
      onSaved(ticket.id);
    } catch (error) {
      setError(error);
    } finally {
      setBusy(false);
    }
  }

  return <article className="pv-panel pv-ticket-detail" aria-labelledby="pv-ticket-title">
    <div className="pv-panel-header">
      <div><p className="pv-section-label" title={ticket.id}>{ticket.id.slice(0, 8)}</p><h2 id="pv-ticket-title" ref={headingRef} tabIndex={-1}>{ticket.subject}</h2></div>
      <Status kind={ticket.reply ? "replied" : "new"} statuses={supportStatuses} />
    </div>
    <div className="pv-ticket-body">
      <div className="pv-sender"><span className="pv-icon pv-blue"><Icon name="user" /></span>
        <div><strong>{ticket.requester?.full_name || "Người gửi"}</strong>{ticket.requester?.email && <small>{ticket.requester.email}</small>}</div>
        <time dateTime={ticket.created_at}>{displayDateTime(ticket.created_at)}</time>
      </div>
      <p className="pv-message">{ticket.message}</p>
      {ticket.reply ? <div className="pv-reply"><h3>Phản hồi của bộ phận hỗ trợ</h3><p>{ticket.reply}</p></div> :
        <form className="pv-reply" onSubmit={save}>
          <label className="pv-field">Nội dung phản hồi<textarea required maxLength={2000} rows={4} placeholder="Nhập hướng dẫn cho người gửi…" value={reply} onChange={(event) => setReply(event.target.value)} disabled={busy} /></label>
          {error && <QueryError error={error} />}
          <button type="submit" className="pv-button pv-button-primary" disabled={!reply.trim() || busy}>{busy ? "Đang lưu…" : "Lưu phản hồi"}</button>
        </form>}
    </div>
  </article>;
}

export default function Support() {
  const [params, setParams] = useSearchParams();
  const initialStatus = params.get("trang-thai");
  const linkedId = params.get("ma");
  const [filters, setFilters] = useState(() => ({ status: Object.hasOwn(supportStatuses, initialStatus) ? initialStatus : "", search: "", page: 1 }));
  const [selectedId, setSelectedId] = useState(linkedId);
  const [notice, setNotice] = useState("");
  const headingRef = useRef(null);
  const load = useCallback((signal) => listSupport(supabase, filters, signal), [filters]);
  const loadLinked = useCallback((signal) => linkedId ? readSupport(supabase, linkedId, signal) : null, [linkedId]);
  const listing = useAdminQuery(load, 200, ["support_requests", "profiles"]);
  const linked = useAdminQuery(loadLinked, 0, ["support_requests", "profiles"]);
  const pending = useAdminQuery(fetchSupportCount, 0, ["support_requests"]);
  const { rows, count } = listing.data ?? emptyPage;
  const selected = rows.find(({ id }) => id === selectedId) ?? (linkedId === selectedId ? linked.data : null) ?? rows[0];

  function updateFilters(patch) {
    if (linkedId) {
      const next = new URLSearchParams(params);
      next.delete("ma");
      setParams(next, { replace: true });
    }
    setFilters((current) => ({ ...current, page: 1, ...patch }));
  }

  function openTicket(id) {
    setSelectedId(id);
    if (window.matchMedia("(max-width: 820px)").matches) requestAnimationFrame(() => headingRef.current?.focus());
  }

  function finishReply(id) {
    setSelectedId(id);
    setNotice("Đã lưu phản hồi.");
    if (filters.status === "new") updateFilters({ status: "" });
    listing.reload();
    linked.reload();
    pending.reload();
  }

  return <>
    <Heading title="Trợ giúp" description="Đọc yêu cầu, xem thông tin người gửi và lưu phản hồi.">
      {pending.data != null && <StatusBadge tone="amber">{pending.data} yêu cầu chờ phản hồi</StatusBadge>}
    </Heading>
    {notice && <p className="pv-notice" role="status">{notice}</p>}
    {pending.error && !listing.error && <QueryError error={pending.error} setup={supportSetup} retry={pending.reload} />}
    <div className="pv-inbox">
      <section className="pv-panel pv-ticket-list" aria-labelledby="pv-inbox-title" aria-busy={listing.loading}>
        <div className="pv-panel-header"><h2 id="pv-inbox-title">Hộp thư hỗ trợ</h2></div>
        <div className="pv-inbox-filters">
          <label className="pv-field">Tìm yêu cầu<input type="search" placeholder="Tiêu đề hoặc nội dung" value={filters.search} onChange={(event) => updateFilters({ search: event.target.value })} /></label>
          <div className="pv-segmented" aria-label="Lọc trạng thái hỗ trợ">
            {[["", "Tất cả"], ["new", "Chờ phản hồi"], ["replied", "Đã phản hồi"]].map(([value, label]) => <button key={label} type="button" aria-pressed={filters.status === value} onClick={() => updateFilters({ status: value })}>{label}</button>)}
          </div>
        </div>
        {listing.loading && <p className="pv-empty" role="status">Đang tải yêu cầu…</p>}
        {listing.error && <QueryError error={listing.error} setup={supportSetup} retry={() => { updateFilters({ page: 1 }); listing.reload(); pending.reload(); }} />}
        {listing.data && <>
          <ul>
            {rows.map((ticket) => <li key={ticket.id}><button type="button" className="pv-ticket-item" aria-pressed={selected?.id === ticket.id} onClick={() => openTicket(ticket.id)}>
              <span className="pv-ticket-meta"><span title={ticket.id}>{ticket.id.slice(0, 8)}</span><time dateTime={ticket.created_at}>{displayDate(ticket.created_at)}</time></span><strong>{ticket.subject}</strong>
              {ticket.requester?.full_name && <span className="pv-secondary">{ticket.requester.full_name}</span>}<Status kind={ticket.reply ? "replied" : "new"} statuses={supportStatuses} />
            </button></li>)}
          </ul>
          {rows.length === 0 && <p className="pv-empty" role="status">
            {filters.search || filters.status ? "Không tìm thấy yêu cầu phù hợp." : "Chưa có yêu cầu hỗ trợ."}
          </p>}
          <Pagination page={filters.page} count={count} pageSize={pageSize} onChange={(page) => updateFilters({ page })} label="Phân trang hỗ trợ" />
        </>}
      </section>
      {selected && <TicketDetail key={selected.id} ticket={selected} onSaved={finishReply} headingRef={headingRef} />}
      {linkedId && linked.error && !listing.error && <QueryError error={linked.error} setup={supportSetup} retry={linked.reload} />}
    </div>
  </>;
}
