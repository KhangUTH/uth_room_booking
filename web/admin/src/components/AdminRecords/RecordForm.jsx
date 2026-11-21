import { useState } from "react";
import { dataErrorMessage, entities, equipmentStatuses } from "../../lib/adminData.js";
import DataDialog from "./DataDialog.jsx";

export default function RecordForm({ table, record, references, currentUserId, onSave, onClose }) {
  const [values, setValues] = useState(() => ({
    name: "", email: "", password: "", full_name: "", role: "", student_code: "", lecturer_code: "",
    employee_code: "", faculty: "", location: "", capacity: "", room_id: "", status: "available", note: "", is_active: true,
    ...Object.fromEntries(Object.entries(record ?? {}).map(([key, value]) => [key, value ?? ""])),
  }));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const isSelf = record?.id === currentUserId;
  const set = (name, value) => setValues((previous) => ({ ...previous, [name]: value }));
  const roleOptions = [...new Set([...(references.roles ?? []), ...(record?.role ? [record.role] : [])])];
  const referenceBlocked = table !== "rooms" && (references.loading || Boolean(references.error));

  async function submit(event) {
    event.preventDefault();
    if (saving || referenceBlocked) return;
    setSaving(true);
    setError("");
    try { await onSave(values); }
    catch (requestError) { setError(dataErrorMessage(requestError)); }
    finally { setSaving(false); }
  }

  function field(name, label, { type = "text", required = false, disabled = false, min, max, maxLength = 255, autoComplete = "off" } = {}) {
    return <div className="form-group" key={name}>
      <label htmlFor={`record-${name}`}>{label}{required ? " *" : ""}</label>
      <input id={`record-${name}`} name={name} type={type} required={required} disabled={disabled}
        min={min} max={max} maxLength={maxLength} minLength={name === "password" ? 8 : undefined}
        autoComplete={autoComplete} value={values[name]} onChange={(event) => set(name, event.target.value)} />
    </div>;
  }

  return <DataDialog title={`${record ? "Sửa" : "Thêm"} ${entities[table].singular}`} busy={saving} onClose={onClose}>
    <form onSubmit={submit}>
      <div className="data-dialog-body">
        {error && <p className="data-error" role="alert">{error}</p>}
        {references.error && table !== "rooms" && <p className="data-error" role="alert">{references.error}</p>}
        <fieldset disabled={saving}>
          {table === "profiles" ? <>
            {field("full_name", "Họ và tên", { required: true })}
            {field("email", "Email", { type: "email", required: true, disabled: Boolean(record), autoComplete: "username" })}
            {!record && field("password", "Mật khẩu ban đầu", { type: "password", required: true, autoComplete: "new-password", maxLength: 128 })}
            <div className="form-group">
              <label htmlFor="record-role">Vai trò *</label>
              <select id="record-role" value={values.role} required disabled={isSelf || referenceBlocked} onChange={(event) => set("role", event.target.value)}>
                <option value="">{references.loading ? "Đang tải vai trò…" : "Chọn vai trò"}</option>
                {roleOptions.map((role) => <option key={role} value={role}>{role}</option>)}
              </select>
            </div>
            <div className="data-form-grid">
              {field("student_code", "Mã sinh viên")}
              {field("lecturer_code", "Mã giảng viên")}
              {field("employee_code", "Mã nhân viên")}
              {field("faculty", "Khoa")}
            </div>
            <label className="data-checkbox"><input type="checkbox" checked={values.is_active === true} disabled={isSelf} onChange={(event) => set("is_active", event.target.checked)} />Tài khoản đang hoạt động</label>
            {isSelf && <p className="data-hint">Bạn không thể tự đổi vai trò hoặc vô hiệu hóa tài khoản đang đăng nhập tại đây.</p>}
          </> : <>
            {field("name", table === "rooms" ? "Tên phòng" : "Tên thiết bị", { required: true })}
            {field("location", "Vị trí")}
            {table === "rooms" ? <>
              {field("capacity", "Sức chứa", { type: "number", required: true, min: 1, max: 2147483647 })}
              <label className="data-checkbox"><input type="checkbox" checked={values.is_active === true} onChange={(event) => set("is_active", event.target.checked)} />Phòng đang hoạt động</label>
            </> : <>
              <div className="form-group">
                <label htmlFor="record-room_id">Phòng</label>
                <select id="record-room_id" value={values.room_id} disabled={referenceBlocked} onChange={(event) => set("room_id", event.target.value)}>
                  <option value="">Chưa gán phòng</option>
                  {record?.room_id && !references.rooms.some((room) => room.id === record.room_id)
                    && <option value={record.room_id}>{record.room?.name || "Phòng hiện tại (đã lưu trữ)"}</option>}
                  {references.rooms.map((room) => <option key={room.id} value={room.id}>{room.name}{room.is_active ? "" : " (ngừng hoạt động)"}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label htmlFor="record-status">Trạng thái *</label>
                <select id="record-status" value={values.status} required onChange={(event) => set("status", event.target.value)}>
                  {!equipmentStatuses.some(({ value }) => value === values.status) && <option value={values.status}>{values.status || "Chọn trạng thái"}</option>}
                  {equipmentStatuses.map(({ value, label }) => <option key={value} value={value}>{label}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label htmlFor="record-note">Ghi chú</label>
                <textarea id="record-note" rows={4} maxLength={5000} value={values.note} onChange={(event) => set("note", event.target.value)} />
              </div>
            </>}
          </>}
        </fieldset>
      </div>
      <footer className="data-dialog-footer">
        <button type="button" onClick={onClose} disabled={saving}>Hủy</button>
        <button className="data-primary" type="submit" disabled={saving || referenceBlocked} aria-busy={saving}>{saving ? "Đang lưu…" : record ? "Lưu thay đổi" : "Thêm mới"}</button>
      </footer>
    </form>
  </DataDialog>;
}
