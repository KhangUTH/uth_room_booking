import { useState } from "react";
import useAuth from "../../hooks/useAuth.js";
import useAdminRecords from "../../hooks/useAdminRecords.js";
import { supabase } from "../../lib/supabase.js";
import { dataErrorMessage, deleteRecord, entities, equipmentStatusLabel, facilityStatusLabel, PAGE_SIZE, profileCodeFields, profileHasFaculty, profileRoleLabels, saveRecord } from "../../lib/adminData.js";
import Title from "../Title/Title.jsx";
import Table, { StatusBadge } from "../Table/Table.jsx";
import Pagination from "../Pagination/Pagination.jsx";
import RecordForm from "./RecordForm.jsx";
import DataDialog from "./DataDialog.jsx";
import "./AdminRecords.css";

const text = (value) => value || "—";
const activeLabel = (value) => value ? "Hoạt động" : "Ngừng hoạt động";
const accountStatus = (value) => <StatusBadge tone={value ? "green" : "neutral"}>{activeLabel(value)}</StatusBadge>;
const facilityStatus = (value) => <StatusBadge tone={value ? "green" : "amber"}>{facilityStatusLabel(value)}</StatusBadge>;
const equipmentStatus = (value) => <StatusBadge tone={value === "available" ? "green" : value === "broken" ? "amber" : "neutral"}>{equipmentStatusLabel(value)}</StatusBadge>;

function columnsFor(table, offset) {
  const common = [{ title: "STT", key: "id", render: (_value, row) => offset + row.rowIndex + 1 }];
  if (table === "profiles") return [
    { title: "Người dùng", key: "full_name", render: (name, row) => <div className="data-user-identity"><strong>{text(name)}</strong><span>{text(row.email)}</span></div> },
    { title: "Mã số", key: "student_code", render: (_value, row) => text(row[profileCodeFields[row.role]?.key]) },
    { title: "Vai trò", key: "role", render: (value) => profileRoleLabels[value] || value },
    { title: "Trạng thái", key: "is_active", render: accountStatus },
  ];
  if (table === "rooms") return [...common,
    { title: "Tên phòng", key: "name" }, { title: "Vị trí", key: "location", render: text },
    { title: "Sức chứa", key: "capacity" }, { title: "Trạng thái", key: "is_active", render: facilityStatus },
  ];
  return [...common,
    { title: "Tên thiết bị", key: "name" },
    { title: "Phạm vi", key: "room", render: (room, row) => room?.name || (row.room_id ? "Thiết bị gắn phòng" : "Thiết bị dùng chung") },
    { title: "Vị trí", key: "location", render: (value, row) => value || row.room?.location || "—" },
    { title: "Trạng thái", key: "status", render: equipmentStatus }, { title: "Ghi chú", key: "note", render: text },
  ];
}

export default function AdminRecordsPage({ table }) {
  const config = entities[table];
  const { user, refreshProfile } = useAuth();
  const [query, setQuery] = useState({ page: 1, search: "", filter: "" });
  const { rows, count, loading, error, references, reload } = useAdminRecords(table, query);
  const [form, setForm] = useState(null);
  const [detail, setDetail] = useState(null);
  const [confirmation, setConfirmation] = useState(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState("");
  const [notice, setNotice] = useState("");
  function changeQuery(patch) { setQuery((previous) => ({ ...previous, page: 1, ...patch })); }

  async function save(values) {
    await saveRecord(supabase, table, values, form.record?.id);
    const editedSelf = table === "profiles" && form.record?.id === user.id;
    setForm(null);
    setNotice("Đã lưu dữ liệu thành công.");
    setActionError("");
    if (editedSelf) refreshProfile();
    reload();
  }

  async function confirmAction() {
    if (busy) return;
    setBusy(true);
    setActionError("");
    try {
      await deleteRecord(supabase, table, confirmation.id);
      setConfirmation(null);
      setNotice(`Đã xóa ${config.singular}.`);
      changeQuery({ page: 1 });
      reload();
    } catch (requestError) { setActionError(dataErrorMessage(requestError)); }
    finally { setBusy(false); }
  }

  const actions = [
    { label: "Xem", icon: "fa-regular fa-eye", className: "common-view-button", onClick: setDetail },
    { label: "Sửa", icon: "fa-solid fa-pen-to-square", className: "common-edit-button", onClick: (record) => { setForm({ record }); setNotice(""); } },
  ];
  if (table !== "profiles") actions.push({
    label: "Xóa", icon: "fa-solid fa-trash-can", className: "common-delete-button",
    onClick: (record) => { setConfirmation(record); setActionError(""); },
  });

  const detailCode = profileCodeFields[detail?.role];
  const detailFields = detail ? (table === "profiles" ? [
    ["Họ và tên", detail.full_name], ["Email", detail.email], ["Vai trò", profileRoleLabels[detail.role] || detail.role],
    ...(detailCode ? [[detailCode.label, detail[detailCode.key]]] : []),
    ...(profileHasFaculty(detail.role) ? [["Khoa", detail.faculty]] : []),
    ["Trạng thái", accountStatus(detail.is_active)],
  ] : table === "rooms" ? [
    ["Tên phòng", detail.name], ["Vị trí", detail.location], ["Sức chứa", detail.capacity],
    ["Trạng thái", facilityStatus(detail.is_active)],
  ] : [
    ["Tên thiết bị", detail.name], ["Phạm vi", detail.room_id ? "Thiết bị gắn phòng" : "Thiết bị dùng chung"],
    ...(detail.room_id ? [["Phòng", detail.room?.name]] : []),
    ["Vị trí", detail.location || detail.room?.location],
    ["Trạng thái", equipmentStatus(detail.status)], ["Ghi chú", detail.note],
  ]) : [];

  return <>
    <Title icon={config.icon} title={config.title} placeholder={table === "profiles" ? "Tìm theo tên, email hoặc mã số…" : "Tìm kiếm theo tên, vị trí hoặc mã số…"}
      search={query.search} onSearchChange={(search) => changeQuery({ search })}
      buttonText={config.add} onAdd={() => { setForm({ record: null }); setNotice(""); }}>
      <div className="filter-box">
        <select aria-label="Lọc dữ liệu" value={query.filter} onChange={(event) => changeQuery({ filter: event.target.value })}>
          <option value="">{table === "profiles" ? "Tất cả vai trò" : table === "rooms" ? "Tất cả trạng thái" : "Tất cả phòng"}</option>
          {table === "profiles" && references.roles.map((role) => <option key={role} value={role}>{profileRoleLabels[role] || role}</option>)}
          {table === "rooms" && <><option value="active">{facilityStatusLabel(true)}</option><option value="inactive">{facilityStatusLabel(false)}</option></>}
          {table === "equipment" && references.rooms.map((room) => <option key={room.id} value={room.id}>{room.name}</option>)}
        </select>
        <i className="fa-solid fa-chevron-down" aria-hidden="true" />
      </div>
    </Title>
    <section className="content data-management" aria-busy={loading}>
      {notice && <p className="data-success" role="status">{notice}</p>}
      {error && <p className="data-error" role="alert">{error} <button type="button" onClick={reload}>Thử lại</button></p>}
      {references.error && <p className="data-error" role="alert">Không tải được danh mục lựa chọn. {references.error} <button type="button" onClick={reload}>Thử lại</button></p>}
      {loading ? <p className="data-loading" role="status">Đang tải dữ liệu…</p> : !error && <>
        <Table columns={columnsFor(table, (query.page - 1) * PAGE_SIZE)}
          data={rows.map((row, rowIndex) => ({ ...row, rowIndex }))} actions={actions} busy={busy}
          emptyMessage={query.search || query.filter ? "Không có dữ liệu phù hợp với bộ lọc." : "Chưa có dữ liệu."} />
        <Pagination page={query.page} count={count} pageSize={PAGE_SIZE} busy={busy}
          onChange={(page) => changeQuery({ page })} />
      </>}
    </section>
    {form && <RecordForm table={table} record={form.record} references={references} currentUserId={user?.id} onClose={() => setForm(null)} onSave={save} />}
    {detail && <DataDialog title={`Chi tiết ${config.singular}`} onClose={() => setDetail(null)}>
      <dl className="data-details">{[...detailFields, ...(table === "profiles" ? [] : [["ID", detail.id]]), ["Ngày tạo", detail.created_at ? new Date(detail.created_at).toLocaleString("vi-VN") : "—"]].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value ?? "—"}</dd></div>)}</dl>
    </DataDialog>}
    {confirmation && <DataDialog title="Xác nhận thay đổi" busy={busy} onClose={() => setConfirmation(null)}>
      <div className="data-dialog-body">
        <p>Xóa vĩnh viễn {config.singular} {confirmation.name}?</p>
        <p className="data-hint">Thao tác này không thể hoàn tác. Bản ghi đang được tham chiếu sẽ không thể xóa.</p>
        {actionError && <p className="data-error" role="alert">{actionError}</p>}
      </div>
      <footer className="data-dialog-footer"><button type="button" disabled={busy} onClick={() => setConfirmation(null)}>Hủy</button><button className="data-primary" type="button" disabled={busy} onClick={confirmAction}>{busy ? "Đang xử lý…" : "Xóa vĩnh viễn"}</button></footer>
    </DataDialog>}
  </>;
}
