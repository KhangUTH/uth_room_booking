import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import DataDialog from "../../../components/AdminRecords/DataDialog.jsx";
import { dataErrorMessage } from "../../../lib/adminData.js";
import { supabase } from "../../../lib/supabase.js";
import {
  bookingAsset, bookingStatuses, bookingType, bookingWeek, countBookings, countPendingSupport, decideBooking,
  displayDate, displayDateTime, displayTime, listBookings, listSupport, loadBookingBars, loadOverviewCounts,
  loadRecentActivity, pageSize, readBooking, readSupport, replyToSupport, supportStatuses,
} from "./operationsData.js";
import "./AdminOperations.css";

const fetchOverview = (signal) => loadOverviewCounts(supabase, signal);
const fetchActivity = (signal) => loadRecentActivity(supabase, signal);
const fetchBookingCounts = (signal) => countBookings(supabase, signal);
const fetchSupportCount = (signal) => countPendingSupport(supabase, signal);
const vietnameseNumber = new Intl.NumberFormat("vi-VN");
const roleLabels = { admin: "Quản trị viên", student: "Sinh viên", teacher: "Giảng viên", lecturer: "Giảng viên", technician: "Nhân viên kỹ thuật" };
const emptyPage = { rows: [], count: 0 };

function useAdminQuery(load, delay = 0) {
  const [version, setVersion] = useState(0);
  const [result, setResult] = useState(null);
  useEffect(() => {
    const controller = new AbortController();
    let active = true;
    const timer = setTimeout(async () => {
      const timeout = setTimeout(() => controller.abort(), 15000);
      try {
        const data = await load(controller.signal);
        if (active) setResult({ load, version, data });
      } catch (error) {
        if (active) setResult({ load, version, error });
      } finally {
        clearTimeout(timeout);
      }
    }, delay);
    return () => {
      active = false;
      clearTimeout(timer);
      controller.abort();
    };
  }, [load, version, delay]);
  const current = result?.load === load && result.version === version ? result : null;
  return { data: current?.data, error: current?.error, loading: !current, reload: () => setVersion((value) => value + 1) };
}

function Icon({ name }) {
  return <i className={`fa-solid fa-${name}`} aria-hidden="true" />;
}

function Status({ kind, statuses = bookingStatuses }) {
  const { label, tone } = Object.hasOwn(statuses, kind) ? statuses[kind] : { label: kind || "—", tone: "neutral" };
  return <span className={`pv-status pv-${tone}`}>{label}</span>;
}

function Heading({ title, description, children }) {
  return <header className="pv-heading">
    <div><h1>{title}</h1><p className="pv-subtitle">{description}</p></div>
    {children}
  </header>;
}

function QueryError({ error, setup, retry }) {
  const missingTable = error.code === "PGRST205" || error.code === "42P01";
  return <div className="pv-error" role="alert">
    <p>{missingTable && setup ? setup : dataErrorMessage(error)}</p>
    {retry && <button className="pv-button" type="button" onClick={retry}>Tải lại</button>}
  </div>;
}

function Pagination({ page, count, onChange, label }) {
  const pages = Math.max(1, Math.ceil(count / pageSize));
  if (pages === 1 && page === 1) return null;
  return <nav className="pv-pagination" aria-label={label}>
    <span>Trang {page}/{pages}</span>
    <button className="pv-button" type="button" disabled={page <= 1} onClick={() => onChange(page - 1)}>Trước</button>
    <button className="pv-button" type="button" disabled={page >= pages} onClick={() => onChange(page + 1)}>Sau</button>
  </nav>;
}

const bookingSetup = "Chưa áp dụng migration duyệt đăng ký lịch trên Supabase.";
const supportSetup = "Chưa cấu hình hộp thư hỗ trợ trên Supabase (SQL bước 07).";

function BookingChart() {
  const [previous, setPrevious] = useState(false);
  const week = useMemo(() => bookingWeek(previous), [previous]);
  const load = useCallback((signal) => loadBookingBars(supabase, week.days, signal), [week]);
  const chart = useAdminQuery(load);
  const bars = chart.data ?? [];
  const dailyTotals = bars.map(([rooms, equipment]) => rooms + equipment);
  const total = dailyTotals.reduce((sum, count) => sum + count, 0);
  const scale = Math.min(9, 114 / Math.max(1, ...dailyTotals));

  return <section className="pv-panel" aria-labelledby="pv-chart-title">
    <div className="pv-panel-header">
      <div><h2 id="pv-chart-title">Lượt đăng ký</h2><p className="pv-secondary">{chart.data && `${vietnameseNumber.format(total)} lượt · `}{week.label}</p></div>
      <select className="pv-select" aria-label="Tuần thống kê" value={previous ? "previous" : "current"} onChange={(event) => setPrevious(event.target.value === "previous")}>
        <option value="current">Tuần này</option><option value="previous">Tuần trước</option>
      </select>
    </div>
    {chart.loading && <p className="pv-empty" role="status">Đang tải thống kê…</p>}
    {chart.error && <QueryError error={chart.error} setup={bookingSetup} retry={chart.reload} />}
    {chart.data && <>
      <div className="pv-chart" aria-label="Số lượt đăng ký theo ngày gửi">
        {bars.map(([rooms, equipment], index) => {
          const day = index === 6 ? "CN" : `T${index + 2}`;
          return <div className="pv-chart-day" key={day}>
            <div className="pv-chart-track">
              <div className="pv-chart-stack" role="img" aria-label={`${day}, ${rooms} lượt đặt phòng và ${equipment} lượt đặt thiết bị`}>
                <span className="pv-bar-total" aria-hidden="true">{dailyTotals[index]}</span>
                <span className="pv-bar-equipment" style={{ height: equipment * scale }} />
                <span className="pv-bar-rooms" style={{ height: rooms * scale }} />
              </div>
            </div>
            <span aria-hidden="true">{day}</span>
          </div>;
        })}
      </div>
      <div className="pv-chart-legend"><span>Phòng</span><span>Thiết bị</span></div>
    </>}
  </section>;
}

function Overview() {
  const counts = useAdminQuery(fetchOverview);
  const activity = useAdminQuery(fetchActivity);
  const [rooms, equipment, bookings, support] = counts.data ?? [];
  const pending = bookings?.value;
  const awaitingReply = support?.value;
  const countError = counts.error || counts.data?.find((entry) => entry.status === "rejected")?.reason;
  const totalLabel = (total, text) => total == null ? "" : `Trên tổng số ${vietnameseNumber.format(total)} ${text}`;
  const metrics = [
    { name: "Phòng đang hoạt động", count: rooms?.value?.[0], note: totalLabel(rooms?.value?.[1], "phòng"), icon: "door-open", tone: "green", path: "/facilities/rooms" },
    { name: "Thiết bị sẵn sàng", count: equipment?.value?.[0], note: totalLabel(equipment?.value?.[1], "thiết bị"), icon: "desktop", tone: "blue", path: "/facilities/equipment" },
    { name: "Đăng ký chờ duyệt", count: pending, note: "Phòng và thiết bị", icon: "calendar-check", tone: "amber", path: "/managercalendar?trang-thai=pending" },
    { name: "Yêu cầu cần phản hồi", count: awaitingReply, note: "Trong hộp thư hỗ trợ", icon: "headset", tone: "violet", path: "/managersupport?trang-thai=new" },
  ];

  return <>
    <Heading title="Tổng quan" description="Theo dõi phòng, thiết bị và các yêu cầu cần xử lý.">
      <span className="pv-date-chip"><Icon name="calendar-days" /> {displayDate(new Date())}</span>
    </Heading>
    <section className="pv-metrics" aria-label="Chỉ số vận hành" aria-busy={counts.loading}>
      {metrics.map(({ name, count, note, icon, tone, path }) => <Link className="pv-metric" key={name} to={path}>
        <span className={`pv-icon pv-${tone}`}><Icon name={icon} /></span>
        <span className="pv-metric-name">{name}</span>
        <strong>{count == null ? "—" : vietnameseNumber.format(count)}</strong>
        <span className="pv-secondary">{count == null ? counts.loading ? "Đang tải…" : "Chưa có số liệu" : note}</span>
      </Link>)}
    </section>
    {countError && <QueryError error={countError} setup="Một số nguồn dữ liệu quản trị chưa được cấu hình trên Supabase." retry={counts.reload} />}
    <div className="pv-overview-grid">
      <BookingChart />
      <section className="pv-panel" aria-labelledby="pv-queue-title">
        <div className="pv-panel-header"><div><h2 id="pv-queue-title">Cần xử lý</h2>
          {pending != null && awaitingReply != null && <p className="pv-secondary">{vietnameseNumber.format(pending + awaitingReply)} yêu cầu đang chờ</p>}
        </div></div>
        <div className="pv-queue">
          <Link to="/managercalendar?trang-thai=pending"><span className="pv-icon pv-amber"><Icon name="calendar-check" /></span><span><strong>Duyệt đăng ký lịch</strong><small>Phòng và thiết bị</small></span><b>{pending ?? "—"}</b></Link>
          <Link to="/managersupport?trang-thai=new"><span className="pv-icon pv-violet"><Icon name="headset" /></span><span><strong>Phản hồi hỗ trợ</strong><small>Yêu cầu từ người dùng</small></span><b>{awaitingReply ?? "—"}</b></Link>
          <Link to="/managerassignment"><span className="pv-icon pv-green"><Icon name="screwdriver-wrench" /></span><span><strong>Phân công sự cố</strong><small>Mở trang quản lý</small></span></Link>
        </div>
      </section>
    </div>
    <section className="pv-panel" aria-labelledby="pv-activity-title">
      <div className="pv-panel-header"><h2 id="pv-activity-title">Hoạt động gần đây</h2></div>
      {activity.loading && <p className="pv-empty" role="status">Đang tải hoạt động…</p>}
      {(activity.error || activity.data?.error) && <QueryError error={activity.error || activity.data.error} setup="Một số hoạt động cần cấu hình thêm trên Supabase." retry={activity.reload} />}
      {activity.data?.rows.length > 0 && <ul className="pv-activity">
        {activity.data.rows.map((row) => <li key={row.path}>
          <span className={`pv-icon pv-${row.tone}`}><Icon name={row.icon} /></span><div><Link to={row.path}>{row.title}</Link>{row.description && <small>{row.description}</small>}</div>
          <time dateTime={row.createdAt}>{displayDateTime(row.createdAt)}</time>
        </li>)}
      </ul>}
      {activity.data && !activity.data.error && activity.data.rows.length === 0 && <p className="pv-empty">Chưa có hoạt động.</p>}
    </section>
  </>;
}

function BookingDetail({ id, onClose, onSaved }) {
  const load = useCallback((signal) => readBooking(supabase, id, signal), [id]);
  const { data: booking, loading, error, reload } = useAdminQuery(load);
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
        <div><dt>Người đăng ký</dt><dd>{booking.requester_name || "—"}{booking.requester_role && ` · ${roleLabels[booking.requester_role] || booking.requester_role}`}</dd></div>
        <div><dt>Loại đăng ký</dt><dd>{bookingType(booking)}</dd></div>
        <div><dt>Bắt đầu</dt><dd>{displayDateTime(booking.start_time)}</dd></div>
        <div><dt>Kết thúc</dt><dd>{displayDateTime(booking.end_time)}</dd></div>
        {booking.student_count != null && <div><dt>Số người tham gia</dt><dd>{booking.student_count} người</dd></div>}
        {booking.teaching_section_code && <div className="pv-full"><dt>Lớp học phần</dt><dd>{booking.teaching_section_code} · {booking.teaching_section_name}</dd></div>}
        {booking.purpose && <div className="pv-full"><dt>Mục đích sử dụng</dt><dd>{booking.purpose}</dd></div>}
      </dl>
      {decision && <p>{decision === "approved" ? "Xác nhận duyệt đăng ký này?" : "Xác nhận từ chối đăng ký này?"}</p>}
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

function Bookings() {
  const [params, setParams] = useSearchParams();
  const initialStatus = params.get("trang-thai");
  const activeId = params.get("ma");
  const [filters, setFilters] = useState(() => ({
    status: Object.hasOwn(bookingStatuses, initialStatus) ? initialStatus : "", search: "", type: "", date: "", page: 1,
  }));
  const [notice, setNotice] = useState("");
  const load = useCallback((signal) => listBookings(supabase, filters, signal), [filters]);
  const listing = useAdminQuery(load, 200);
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
        <label className="pv-field">Ngày sử dụng<input type="date" value={filters.date} onChange={(event) => updateFilters({ date: event.target.value })} /></label>
      </div>
      {listing.loading && <p className="pv-empty" role="status">Đang tải đăng ký…</p>}
      {listing.error && <QueryError error={listing.error} setup={bookingSetup} retry={() => { updateFilters({ page: 1 }); listing.reload(); summary.reload(); }} />}
      {listing.data && <>
        <div className="pv-table-wrap" tabIndex={0} role="region" aria-label="Bảng đăng ký lịch">
          <table className="pv-table">
            <thead><tr><th scope="col">Mã đăng ký</th><th scope="col">Người đăng ký</th><th scope="col">Tài nguyên</th><th scope="col">Ngày và giờ</th><th scope="col">Trạng thái</th><th scope="col">Chi tiết</th></tr></thead>
            <tbody>
              {rows.map((row) => <tr key={row.id}>
                <td className="pv-id" title={row.id}>{row.id.slice(0, 8)}</td>
                <td><strong>{row.requester_name || "—"}</strong><small>{roleLabels[row.requester_role] || row.requester_role}</small></td>
                <td><strong>{bookingAsset(row)}</strong><small>{bookingType(row)}</small></td>
                <td>{displayDate(row.start_time)}<small>{displayTime(row.start_time)} – {displayTime(row.end_time)}</small></td>
                <td><Status kind={row.status} /></td>
                <td><button className="pv-text-button" type="button" aria-label={`Xem đăng ký ${row.id.slice(0, 8)}`} onClick={() => showDetail(row.id)}>Xem</button></td>
              </tr>)}
              {rows.length === 0 && <tr><td colSpan={6} className="pv-empty">
                {filters.search || filters.status || filters.type || filters.date ? "Không tìm thấy đăng ký phù hợp." : "Chưa có đăng ký lịch."}
              </td></tr>}
            </tbody>
          </table>
        </div>
        <Pagination page={filters.page} count={count} onChange={(page) => updateFilters({ page })} label="Phân trang đăng ký" />
      </>}
    </section>
    {activeId && <BookingDetail key={activeId} id={activeId} onClose={() => showDetail(null)} onSaved={finishDecision} />}
  </>;
}

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

function Support() {
  const [params, setParams] = useSearchParams();
  const initialStatus = params.get("trang-thai");
  const linkedId = params.get("ma");
  const [filters, setFilters] = useState(() => ({ status: Object.hasOwn(supportStatuses, initialStatus) ? initialStatus : "", search: "", page: 1 }));
  const [selectedId, setSelectedId] = useState(linkedId);
  const [notice, setNotice] = useState("");
  const headingRef = useRef(null);
  const load = useCallback((signal) => listSupport(supabase, filters, signal), [filters]);
  const loadLinked = useCallback((signal) => linkedId ? readSupport(supabase, linkedId, signal) : null, [linkedId]);
  const listing = useAdminQuery(load, 200);
  const linked = useAdminQuery(loadLinked);
  const pending = useAdminQuery(fetchSupportCount);
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
      {pending.data != null && <span className="pv-status pv-amber">{pending.data} yêu cầu chờ phản hồi</span>}
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
          <Pagination page={filters.page} count={count} onChange={(page) => updateFilters({ page })} label="Phân trang hỗ trợ" />
        </>}
      </section>
      {selected && <TicketDetail key={selected.id} ticket={selected} onSaved={finishReply} headingRef={headingRef} />}
      {linkedId && linked.error && !listing.error && <QueryError error={linked.error} setup={supportSetup} retry={linked.reload} />}
    </div>
  </>;
}

const screens = { overview: Overview, bookings: Bookings, support: Support };

export default function AdminOperations({ screen }) {
  const Screen = screens[screen];
  return <div className="pv-page"><div className="pv-container"><Screen /></div></div>;
}
