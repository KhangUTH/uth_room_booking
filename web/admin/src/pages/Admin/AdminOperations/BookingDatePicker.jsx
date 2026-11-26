import { useEffect, useRef, useState } from "react";
import { localDay } from "./operationsData.js";

const weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
const monthFormat = new Intl.DateTimeFormat("vi-VN", { month: "long", year: "numeric", timeZone: "UTC" });
const dayFormat = new Intl.DateTimeFormat("vi-VN", { dateStyle: "full", timeZone: "UTC" });
const parseDay = (value) => new Date(`${value}T00:00:00Z`);
const dayKey = (date) => date.toISOString().slice(0, 10);
const monthOf = (value) => `${value.slice(0, 7)}-01`;

export default function BookingDatePicker({ value, onChange }) {
  const today = localDay(new Date());
  const picker = useRef(null);
  const trigger = useRef(null);
  const [open, setOpen] = useState(false);
  const [month, setMonth] = useState(() => monthOf(value || today));
  const first = parseDay(month);
  const year = first.getUTCFullYear();
  const monthIndex = first.getUTCMonth();
  const offset = (first.getUTCDay() + 6) % 7;
  const days = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();

  useEffect(() => {
    if (!open) return;
    function dismiss(event) {
      if (event.type === "keydown" ? event.key !== "Escape" : picker.current?.contains(event.target)) return;
      picker.current.open = false;
      if (event.type === "keydown") trigger.current?.focus();
    }
    document.addEventListener("pointerdown", dismiss);
    document.addEventListener("keydown", dismiss);
    return () => {
      document.removeEventListener("pointerdown", dismiss);
      document.removeEventListener("keydown", dismiss);
    };
  }, [open]);

  function choose(next) {
    onChange(next);
    picker.current.open = false;
    trigger.current?.focus();
  }

  return <div className="pv-field">
    <span>Ngày báo cáo</span>
    <details className="pv-date-picker" ref={picker} onToggle={(event) => setOpen(event.currentTarget.open)}>
      <summary className="pv-date-trigger" ref={trigger} aria-label={value ? `Ngày báo cáo, ${dayFormat.format(parseDay(value))}` : "Chọn ngày báo cáo"}>
        <span>{value ? value.split("-").reverse().join("/") : "Chọn ngày"}</span>
        <i className="fa-regular fa-calendar" aria-hidden="true" />
      </summary>
      <section className="pv-date-calendar" aria-label="Lịch chọn ngày báo cáo">
        <div className="pv-date-month">
          <button type="button" className="pv-button" aria-label="Tháng trước" onClick={() => setMonth(dayKey(new Date(Date.UTC(year, monthIndex - 1, 1))))}>‹</button>
          <strong aria-live="polite">{monthFormat.format(first)}</strong>
          <button type="button" className="pv-button" aria-label="Tháng sau" onClick={() => setMonth(dayKey(new Date(Date.UTC(year, monthIndex + 1, 1))))}>›</button>
        </div>
        <div className="pv-date-grid">
          {weekdays.map((weekday) => <span key={weekday}>{weekday}</span>)}
          {Array.from({ length: offset }, (_, index) => <span key={`empty-${index}`} aria-hidden="true" />)}
          {Array.from({ length: days }, (_, index) => {
            const number = index + 1;
            const date = new Date(Date.UTC(year, monthIndex, number));
            const key = dayKey(date);
            return <button type="button" key={key} aria-label={dayFormat.format(date)}
              aria-pressed={value === key} aria-current={today === key ? "date" : undefined}
              onClick={() => choose(key)}>{number}</button>;
          })}
        </div>
        <div className="pv-date-footer">
          <button type="button" className="pv-text-button" disabled={!value} onClick={() => choose("")}>Bỏ lọc</button>
          <button type="button" className="pv-text-button" onClick={() => { setMonth(monthOf(today)); choose(today); }}>Hôm nay</button>
        </div>
      </section>
    </details>
  </div>;
}
