import { useCallback, useState } from "react";
import { useSearchParams } from "react-router-dom";
import DataDialog from "../../../components/AdminRecords/DataDialog.jsx";
import Pagination from "../../../components/Pagination/Pagination.jsx";
import { profileRoleLabels } from "../../../lib/adminData.js";
import { supabase } from "../../../lib/supabase.js";
import BookingDatePicker from "./BookingDatePicker.jsx";
import { bookingAsset, bookingSetup, bookingStatuses, bookingType, countBookings, decideBooking, displayDate, displayDateTime, displayTime, emptyPage, listBookings, pageSize, readBooking, vietnameseNumber } from "./operationsData.js";
import { Heading, Icon, QueryError, Status } from "./OperationsUi.jsx";
import useAdminQuery from "./useAdminQuery.js";

const fetchBookingCounts = (signal) => countBookings(supabase, signal);
const bookingDetailsSources = ["bookings", "profiles", "rooms", "equipment"];

function BookingDetail({ id, onClose, onSaved }) {
  const load = useCallback((signal) => readBooking(supabase, id, signal), [id]);
  const { data: booking, loading, error, reload } = useAdminQuery(load, 0, bookingDetailsSources);
  const [decision, setDecision] = useState("");
  const [busy, setBusy] = useState(false);
  const [saveError, setSaveError] = useState(null);

  async function save(event) {
    event.preventDefault();
    if (busy || !decision) return;
    setBusy(true);
    setSaveError(null);
    try {
      await decideBooking(supabase, id, decision);
      onSaved(decision);
    } catch (error) {
      setSaveError(error);
    } finally {
      setBusy(false);
    }
  }

  return <DataDialog title={`Đăng ký ${id.slice(0, 8)}`} busy={busy} onClose={onClose}>
    {loading && <p className="pv-empty" role="status">Đang tải chi tiết…</p>}
    {error && <QueryError error={error} setup={bookingSetup} retry={reload} />}
    {booking === null && <p className="pv-empty">Không tìm thấy đăng ký.</p>}
    {booking && <form className="pv-dialog-body" onSubmit={save}>
      <div className="pv-dialog-summary"><h3>{bookingAsset(booking)}</h3><Status kind={booking.status} /></div>
      <dl className="pv-detail-grid">
        <div><dt>Người đăng ký</dt><dd>{booking.requester_name || "—"}{booking.requester_role && ` · ${profileRoleLabels[booking.requester_role] || booking.requester_role}`}</dd></div>
        <div><dt>Loại đăng ký</dt><dd>{bookingType(booking)}</dd></div>
        <div><dt>Bắt đầu</dt><dd>{displayDateTime(booking.start_time)}</dd></div>
        <div><dt>Kết thúc</dt><dd>{displayDateTime(booking.end_time)}</dd></div>
        {booking.student_count != null && <div><dt>Số người tham gia</dt><dd>{booking.student_count} người</dd></div>}
        {booking.teaching_section_code && <div className="pv-full"><dt>Lớp học phần</dt><dd>{booking.teaching_section_code} · {booking.teaching_section_name}</dd></div>}
        {booking.purpose && <div className="pv-full"><dt>Mục đích sử dụng</dt><dd>{booking.purpose}</dd></div>}
      </dl>
      {decision === "approved" && <p>Xác nhận duyệt đăng ký này?</p>}
      {decision === "rejected" && <p className="pv-reject-confirmation">Xác nhận từ chối đăng ký này?</p>}
      {saveError && <QueryError error={saveError} />}
      <div className="pv-dialog-actions">
        {booking.status === "pending" ? decision ? <>
          <button className="pv-button" type="button" disabled={busy} onClick={() => { setDecision(""); setSaveError(null); }}>Quay lại</button>
          <button className={`pv-button ${decision === "approved" ? "pv-button-primary" : "pv-button-danger"}`} type="submit" disabled={busy}>{busy ? "Đang lưu…" : "Xác nhận"}</button>
        </> : <>
          <button className="pv-button" type="button" onClick={() => setDecision("rejected")}>Từ chối</button>
          <button className="pv-button pv-button-primary" type="button" onClick={() => setDecision("approved")}>Duyệt</button>
        </> : <button className="pv-button" type="button" onClick={onClose}>Đóng chi tiết</button>}
      </div>
    </form>}
  </DataDialog>;
}

export default function Bookings() {
  const [params, setParams] = useSearchParams();
  const initialStatus = params.get("trang-thai");
  const activeId = params.get("ma");
  const [filters, setFilters] = useState(() => ({
    status: Object.hasOwn(bookingStatuses, initialStatus) ? initialStatus : "", search: "", type: "", date: "", page: 1,
  }));
  const [notice, setNotice] = useState("");
  const load = useCallback((signal) => listBookings(supabase, filters, signal), [filters]);
  const listing = useAdminQuery(load, 200, bookingDetailsSources);
  const summary = useAdminQuery(fetchBookingCounts);
  const { rows, count } = listing.data ?? emptyPage;
  const [total, pending, approved] = summary.data ?? [];

  function updateFilters(patch) {
    setFilters((current) => ({ ...current, page: 1, ...patch }));
  }

  function showDetail(id) {
    const next = new URLSearchParams(params);
    if (id) next.set("ma", id);
    else next.delete("ma");
    setParams(next, { replace: true });
  }

  function finishDecision(decision) {
    setNotice(decision === "approved" ? "Đã duyệt đăng ký." : "Đã từ chối đăng ký.");
    showDetail(null);
    updateFilters({ page: 1 });
    summary.reload();
    listing.reload();
  }

  return <>
    <Heading title="Đăng ký lịch" description="Tra cứu và xử lý yêu cầu đặt phòng hoặc mượn thiết bị." />
    <div className="pv-booking-summary" aria-label="Lọc theo nhóm đăng ký" aria-busy={summary.loading}>
      {[["", "Tất cả đăng ký", total, "list", "blue"], ["pending", "Chờ duyệt", pending, "clock", "amber"], ["approved", "Đã duyệt", approved, "circle-check", "green"]].map(([value, label, number, icon, tone]) =>
        <button type="button" className="pv-summary-button" key={label} aria-pressed={filters.status === value} onClick={() => updateFilters({ status: value })}>
          <span className={`pv-icon pv-${tone}`}><Icon name={icon} /></span><span>{label}<strong>{number ?? "—"}</strong></span>
        </button>)}
    </div>
    {summary.error && !listing.error && <QueryError error={summary.error} setup={bookingSetup} retry={summary.reload} />}
    {notice && <p className="pv-notice" role="status">{notice}</p>}
    <section className="pv-panel pv-booking-panel" aria-labelledby="pv-bookings-title" aria-busy={listing.loading}>
      <div className="pv-panel-header"><div><h2 id="pv-bookings-title">Danh sách đăng ký</h2>
        {listing.data && <p className="pv-secondary" role="status">{vietnameseNumber.format(count)} kết quả</p>}
      </div></div>
      <div className="pv-filters">
        <label className="pv-field">Tìm kiếm<input type="search" placeholder="Mã, người đặt hoặc tài nguyên" value={filters.search} onChange={(event) => updateFilters({ search: event.target.value })} /></label>
        <label className="pv-field">Trạng thái<select className="pv-select" value={filters.status} onChange={(event) => updateFilters({ status: event.target.value })}>
          <option value="">Tất cả trạng thái</option>{Object.entries(bookingStatuses).map(([value, { label }]) => <option key={value} value={value}>{label}</option>)}
        </select></label>
        <label className="pv-field">Loại đăng ký<select className="pv-select" value={filters.type} onChange={(event) => updateFilters({ type: event.target.value })}><option value="">Phòng và thiết bị</option><option value="room_id">Phòng</option><option value="equipment_id">Thiết bị</option></select></label>
        <BookingDatePicker value={filters.date} onChange={(date) => updateFilters({ date })} />
      </div>
      {listing.loading && <p className="pv-empty" role="status">Đang tải đăng ký…</p>}
      {listing.error && <QueryError error={listing.error} setup={bookingSetup} retry={() => { updateFilters({ page: 1 }); listing.reload(); summary.reload(); }} />}
      {listing.data && <>
        <div className="pv-table-wrap" tabIndex={0} role="region" aria-label="Bảng đăng ký lịch">
          <table className="admin-table">
            <thead><tr><th scope="col">Mã đăng ký</th><th scope="col">Người đăng ký</th><th scope="col">Tài nguyên</th><th scope="col">Ngày và giờ</th><th scope="col">Trạng thái</th><th scope="col">Chi tiết</th></tr></thead>
            <tbody>
              {rows.map((row) => <tr key={row.id}>
                <td className="pv-id" title={row.id}>{row.id.slice(0, 8)}</td>
                <td><strong>{row.requester_name || "—"}</strong><small>{profileRoleLabels[row.requester_role] || row.requester_role}</small></td>
                <td><strong>{bookingAsset(row)}</strong><small>{bookingType(row)}</small></td>
                <td>{displayDate(row.start_time)}<small>{displayTime(row.start_time)} – {displayTime(row.end_time)}</small></td>
                <td><Status kind={row.status} /></td>
                <td>
                  <div className="common-table-actions">
                    <button className="common-view-button" type="button" aria-label={`Xem đăng ký ${row.id.slice(0, 8)}`} onClick={() => showDetail(row.id)}>
                      <i className="fa-regular fa-eye" aria-hidden="true" /> Xem
                    </button>
                  </div>
                </td>
              </tr>)}
              {rows.length === 0 && <tr><td colSpan={6} className="pv-empty">
                {filters.search || filters.status || filters.type || filters.date ? "Không tìm thấy đăng ký phù hợp." : "Chưa có đăng ký lịch."}
              </td></tr>}
            </tbody>
          </table>
        </div>
        <Pagination page={filters.page} count={count} pageSize={pageSize} onChange={(page) => updateFilters({ page })} label="Phân trang đăng ký" />
      </>}
    </section>
    {activeId && <BookingDetail key={activeId} id={activeId} onClose={() => showDetail(null)} onSaved={finishDecision} />}
  </>;
}
