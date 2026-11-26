import { StatusBadge } from "../../../components/Table/Table.jsx";
import { dataErrorMessage } from "../../../lib/adminData.js";
import { bookingStatuses } from "./operationsData.js";

export function Icon({ name }) {
  return <i className={`fa-solid fa-${name}`} aria-hidden="true" />;
}

export function Status({ kind, statuses = bookingStatuses }) {
  const { label, tone } = Object.hasOwn(statuses, kind) ? statuses[kind] : { label: kind || "—", tone: "neutral" };
  return <StatusBadge tone={tone}>{label}</StatusBadge>;
}

export function Heading({ title, description, children }) {
  return <header className="pv-heading">
    <div><h1>{title}</h1><p className="pv-subtitle">{description}</p></div>
    {children}
  </header>;
}

export function QueryError({ error, setup, retry }) {
  const missingTable = error.code === "PGRST205" || error.code === "42P01";
  return <div className="pv-error" role="alert">
    <p>{missingTable && setup ? setup : dataErrorMessage(error)}</p>
    {retry && <button className="pv-button" type="button" onClick={retry}>Tải lại</button>}
  </div>;
}
