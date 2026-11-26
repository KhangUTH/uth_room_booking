import { useCallback, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { supabase } from "../../../lib/supabase.js";
import { bookingSetup, bookingWeek, displayDate, displayDateTime, loadBookingBars, loadOverviewCounts, loadRecentActivity, vietnameseNumber } from "./operationsData.js";
import { Heading, Icon, QueryError } from "./OperationsUi.jsx";
import useAdminQuery from "./useAdminQuery.js";

const fetchOverview = (signal) => loadOverviewCounts(supabase, signal);
const fetchActivity = (signal) => loadRecentActivity(supabase, signal);

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

function OverviewMetrics({ title, metrics, loading }) {
  return <section aria-label={title} aria-busy={loading}>
    <h2 className="pv-overview-section-title">{title}</h2>
    <div className={metrics.length === 2 ? "pv-metrics pv-metrics-pair" : "pv-metrics"}>
      {metrics.map(({ name, count, note, icon, tone, path }) => <Link className="pv-metric" key={name} to={path}>
        <span className={`pv-icon pv-${tone}`}><Icon name={icon} /></span>
        <span className="pv-metric-name">{name}</span>
        <strong>{count == null ? "—" : vietnameseNumber.format(count)}</strong>
        <span className="pv-secondary">{count == null ? loading ? "Đang tải…" : "Chưa có số liệu" : note}</span>
      </Link>)}
    </div>
  </section>;
}

export default function Overview() {
  const counts = useAdminQuery(fetchOverview, 0, ["bookings", "rooms", "equipment", "maintenance_proposals", "incident_reports"]);
  const activity = useAdminQuery(fetchActivity, 0, ["bookings", "profiles", "rooms", "equipment", "maintenance_proposals", "incident_reports"]);
  const [rooms, equipment, bookings, proposals, open, inProgress] = counts.data ?? [];
  const countError = counts.error || counts.data?.find((entry) => entry.status === "rejected")?.reason;
  const totalLabel = (total, text) => total == null ? "" : `Trên tổng số ${vietnameseNumber.format(total)} ${text}`;
  const queue = [
    { name: "Đăng ký chờ duyệt", count: bookings?.value, note: "Phòng và thiết bị", icon: "calendar-check", tone: "amber", path: "/managercalendar?trang-thai=pending" },
    { name: "Đề xuất bảo trì chờ duyệt", count: proposals?.value, note: "Đề xuất từ nhân viên kỹ thuật", icon: "clipboard-list", tone: "violet", path: "/equipment-proposals?trang-thai=pending&loai=all" },
  ];
  const operations = [
    { name: "Phòng đang hoạt động", count: rooms?.value?.[0], note: totalLabel(rooms?.value?.[1], "phòng"), icon: "door-open", tone: "green", path: "/facilities/rooms" },
    { name: "Thiết bị sẵn sàng", count: equipment?.value?.[0], note: totalLabel(equipment?.value?.[1], "thiết bị"), icon: "desktop", tone: "blue", path: "/facilities/equipment" },
    { name: "Sự cố chờ nhận", count: open?.value, note: "Chưa có kỹ thuật viên nhận", icon: "screwdriver-wrench", tone: "amber", path: "/managerassignment?loai=all&trang-thai=open" },
    { name: "Sự cố đang xử lý", count: inProgress?.value, note: "Đã có kỹ thuật viên nhận", icon: "screwdriver-wrench", tone: "blue", path: "/managerassignment?loai=all&trang-thai=in_progress" },
  ];

  return <>
    <Heading title="Tổng quan" description="Theo dõi phòng, thiết bị và các yêu cầu cần xử lý.">
      <span className="pv-date-chip"><Icon name="calendar-days" /> {displayDate(new Date())}</span>
    </Heading>
    <OverviewMetrics title="Cần xử lý" metrics={queue} loading={counts.loading} />
    <OverviewMetrics title="Theo dõi vận hành" metrics={operations} loading={counts.loading} />
    {countError && <QueryError error={countError} setup="Một số nguồn dữ liệu quản trị chưa được cấu hình trên Supabase." retry={counts.reload} />}

    <div className="pv-overview-grid">
      <BookingChart />
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
    </div>
    <Link className="pv-text-button" to="/managersupport">Hộp thư hỗ trợ</Link>
  </>;
}
