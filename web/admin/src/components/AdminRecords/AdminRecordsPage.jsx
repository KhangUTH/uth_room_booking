import { useState } from "react";
import useAuth from "../../hooks/useAuth.js";
import useAdminRecords from "../../hooks/useAdminRecords.js";
import { supabase } from "../../lib/supabase.js";
import { archiveRecord, dataErrorMessage, deleteRecord, entities, equipmentStatuses, PAGE_SIZE, saveRecord } from "../../lib/adminData.js";
import Title from "../Title/Title.jsx";
import Table from "../Table/Table.jsx";
import RecordForm from "./RecordForm.jsx";
import DataDialog from "./DataDialog.jsx";
import "./AdminRecords.css";

const roleLabels = { admin: "Quản trị viên", student: "Sinh viên", teacher: "Giảng viên", lecturer: "Giảng viên", technician: "Nhân viên kỹ thuật" };
const text = (value) => value || "—";
const activeLabel = (value) => value ? "Hoạt động" : "Ngừng hoạt động";

function columnsFor(table, offset) {
  const common = [{ title: "STT", key: "id", render: (_value, row) => offset + row.rowIndex + 1 }];
  if (table === "profiles") return [...common,
    { title: "Họ và tên", key: "full_name", render: text }, { title: "Email", key: "email" },
    { title: "Vai trò", key: "role", render: (value) => roleLabels[value] || value },
    { title: "Mã số", key: "student_code", render: (_value, row) => row.student_code || row.lecturer_code || row.employee_code || "—" },
    { title: "Khoa", key: "faculty", render: text }, { title: "Trạng thái", key: "is_active", render: activeLabel },
  ];
  if (table === "rooms") return [...common,
    { title: "Tên phòng", key: "name" }, { title: "Vị trí", key: "location", render: text },
    { title: "Sức chứa", key: "capacity" }, { title: "Trạng thái", key: "is_active", render: activeLabel },
    { title: "Lưu trữ", key: "is_archived", render: (value) => value ? "Đã lưu trữ" : "Đang sử dụng" },
  ];
  return [...common,
    { title: "Tên thiết bị", key: "name" },
    { title: "Phòng", key: "room", render: (room) => room?.name || "Chưa gán phòng" },
    { title: "Vị trí", key: "location", render: (value, row) => value || row.room?.location || "—" },
    { title: "Trạng thái", key: "status", render: (value) => equipmentStatuses.find((status) => status.value === value)?.label || value }, { title: "Ghi chú", key: "note", render: text },
  ];
}

export default function AdminRecordsPage({ table }) {
  const config = entities[table];
  const { user, refreshProfile } = useAuth();
  const [query, setQuery] = useState({ page: 1, search: "", filter: "", archived: false });
  const { rows, count, loading, error, references, reload } = useAdminRecords(table, query);
  const [form, setForm] = useState(null);
  const [detail, setDetail] = useState(null);
  const [confirmation, setConfirmation] = useState(null);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState("");
  const [notice, setNotice] = useState("");
  const pageCount = Math.max(1, Math.ceil(count / PAGE_SIZE));
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
      if (confirmation.kind === "delete") await deleteRecord(supabase, table, confirmation.record.id);
      else await archiveRecord(supabase, table, confirmation.record);
      const message = confirmation.kind === "delete" ? `Đã xóa ${config.singular}.`
        : table === "profiles" ? "Đã vô hiệu hóa tài khoản." : "Đã cập nhật trạng thái lưu trữ phòng.";
      setConfirmation(null);
      setNotice(message);
      // Return to page one so archiving the last row cannot leave an invalid page.
      changeQuery({ page: 1 });
      reload();
    } catch (requestError) { setActionError(dataErrorMessage(requestError)); }
    finally { setBusy(false); }
  }

  const actions = [
    { label: "Xem", icon: "fa-regular fa-eye", className: "common-view-button", onClick: setDetail },
    { label: "Sửa", icon: "fa-solid fa-pen-to-square", className: "common-edit-button", onClick: (record) => { setForm({ record }); setNotice(""); } },
  ];
  if (table !== "equipment") actions.push({
    label: table === "profiles" ? "Vô hiệu hóa" : query.archived ? "Khôi phục" : "Lưu trữ",
    icon: "fa-solid fa-box-archive", className: "common-delete-button",
    disabled: (record) => table === "profiles" && (record.id === user?.id || !record.is_active),
    onClick: (record) => { setConfirmation({ record, kind: "archive" }); setActionError(""); },
  });
  if (table !== "profiles") actions.push({
    label: "Xóa", icon: "fa-solid fa-trash-can", className: "common-delete-button",
    onClick: (record) => { setConfirmation({ record, kind: "delete" }); setActionError(""); },
  });

  const detailFields = detail ? (table === "profiles" ? [
    ["Họ và tên", detail.full_name], ["Email", detail.email], ["Vai trò", roleLabels[detail.role] || detail.role],
    ["Mã sinh viên", detail.student_code], ["Mã giảng viên", detail.lecturer_code], ["Mã nhân viên", detail.employee_code],
    ["Khoa", detail.faculty], ["Trạng thái", activeLabel(detail.is_active)],
  ] : table === "rooms" ? [
    ["Tên phòng", detail.name], ["Vị trí", detail.location], ["Sức chứa", detail.capacity],
    ["Trạng thái", activeLabel(detail.is_active)], ["Lưu trữ", detail.is_archived ? "Đã lưu trữ" : "Đang sử dụng"],
  ] : [
    ["Tên thiết bị", detail.name], ["Phòng", detail.room?.name], ["Vị trí", detail.location || detail.room?.location],
    ["Trạng thái", detail.status], ["Ghi chú", detail.note],
  ]) : [];

  return <>
    <Title icon={config.icon} title={config.title} placeholder="Tìm kiếm theo tên, vị trí hoặc mã số…"
      search={query.search} onSearchChange={(search) => changeQuery({ search })}
      buttonText={config.add} onAdd={() => { setForm({ record: null }); setNotice(""); }}>
      <div className="filter-box">
        <select aria-label="Lọc dữ liệu" value={query.filter} onChange={(event) => changeQuery({ filter: event.target.value })}>
          <option value="">{table === "profiles" ? "Tất cả vai trò" : table === "rooms" ? "Tất cả trạng thái" : "Tất cả phòng"}</option>
          {table === "profiles" && references.roles.map((role) => <option key={role} value={role}>{roleLabels[role] || role}</option>)}
          {table === "rooms" && <><option value="active">Hoạt động</option><option value="inactive">Ngừng hoạt động</option></>}
          {table === "equipment" && references.rooms.map((room) => <option key={room.id} value={room.id}>{room.name}</option>)}
        </select>
        <i className="fa-solid fa-chevron-down" aria-hidden="true" />
      </div>
      {table === "rooms" && <label className="data-checkbox"><input type="checkbox" checked={query.archived} onChange={(event) => changeQuery({ archived: event.target.checked })} />Phòng đã lưu trữ</label>}
    </Title>
    <section className="content data-management" aria-busy={loading}>
      {notice && <p className="data-success" role="status">{notice}</p>}
      {error && <p className="data-error" role="alert">{error} <button type="button" onClick={reload}>Thử lại</button></p>}
      {references.error && <p className="data-error" role="alert">Không tải được danh mục lựa chọn. {references.error} <button type="button" onClick={reload}>Thử lại</button></p>}
      {loading ? <p className="data-loading" role="status">Đang tải dữ liệu…</p> : !error && <>
        <Table columns={columnsFor(table, (query.page - 1) * PAGE_SIZE)}
          data={rows.map((row, rowIndex) => ({ ...row, rowIndex }))} actions={actions} busy={busy}
          emptyMessage={query.search || query.filter ? "Không có dữ liệu phù hợp với bộ lọc." : "Chưa có dữ liệu."} />
        <nav className="data-pagination" aria-label="Phân trang">
          <span>{count} bản ghi · Trang {query.page}/{pageCount}</span>
          <button type="button" disabled={query.page <= 1} onClick={() => changeQuery({ page: query.page - 1 })}>Trước</button>
          <button type="button" disabled={query.page >= pageCount} onClick={() => changeQuery({ page: query.page + 1 })}>Sau</button>
        </nav>
      </>}
    </section>
    {form && <RecordForm table={table} record={form.record} references={references} currentUserId={user?.id} onClose={() => setForm(null)} onSave={save} />}
    {detail && <DataDialog title={`Chi tiết ${config.singular}`} onClose={() => setDetail(null)}>
      <dl className="data-details">{[...detailFields, ["ID", detail.id], ["Ngày tạo", detail.created_at ? new Date(detail.created_at).toLocaleString("vi-VN") : "—"]].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value ?? "—"}</dd></div>)}</dl>
    </DataDialog>}
    {confirmation && <DataDialog title="Xác nhận thay đổi" busy={busy} onClose={() => setConfirmation(null)}>
      <div className="data-dialog-body">
        <p>{confirmation.kind === "delete" ? `Xóa vĩnh viễn ${config.singular} ${confirmation.record.name}?`
          : table === "profiles" ? `Vô hiệu hóa tài khoản ${confirmation.record.full_name || confirmation.record.email}?`
            : `${confirmation.record.is_archived ? "Khôi phục" : "Lưu trữ"} phòng ${confirmation.record.name}?`}</p>
        <p className="data-hint">{confirmation.kind === "delete" ? "Thao tác này không thể hoàn tác. Bản ghi đang được tham chiếu sẽ không thể xóa." : "Lịch sử đặt phòng và các dữ liệu liên quan được giữ lại."}</p>
        {actionError && <p className="data-error" role="alert">{actionError}</p>}
      </div>
      <footer className="data-dialog-footer"><button type="button" disabled={busy} onClick={() => setConfirmation(null)}>Hủy</button><button className="data-primary" type="button" disabled={busy} onClick={confirmAction}>{busy ? "Đang xử lý…" : confirmation.kind === "delete" ? "Xóa vĩnh viễn" : "Xác nhận"}</button></footer>
    </DataDialog>}
  </>;
}
