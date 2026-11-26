import { useState } from "react";
import { dataErrorMessage, entities, equipmentStatuses, facilityStatusLabel, profileCodeFields, profileHasFaculty, profileRoleLabels } from "../../lib/adminData.js";
import DataDialog from "./DataDialog.jsx";

export default function RecordForm({ table, record, references, currentUserId, onSave, onClose }) {
  const [values, setValues] = useState(() => ({
    name: "", email: "", password: "", full_name: "", role: "", student_code: "", lecturer_code: "",
    employee_code: "", faculty: "", location: "", capacity: "", room_id: "", status: "available", note: "", is_active: true,
    ...Object.fromEntries(Object.entries(record ?? {}).map(([key, value]) => [key, value ?? ""])),
  }));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [statusConfirmed, setStatusConfirmed] = useState(false);
  const [fixedEquipment, setFixedEquipment] = useState(Boolean(record?.room_id));
  const isSelf = Boolean(record && record.id === currentUserId);
  const set = (name, value) => setValues((previous) => ({ ...previous, [name]: value }));
  const roleOptions = [...new Set([...(references.roles ?? []), ...(record?.role ? [record.role] : [])])];
  const referenceBlocked = table !== "rooms" && (references.loading || Boolean(references.error));
  const code = profileCodeFields[values.role];
  const statusChanged = table === "profiles" && record && !isSelf && (record.is_active === true) !== (values.is_active === true);
  const statusUnconfirmed = statusChanged && !statusConfirmed;

  async function submit(event) {
    event.preventDefault();
    if (saving || referenceBlocked || statusUnconfirmed) return;
    setSaving(true);
    setError("");
    try {
      if (table === "equipment" && fixedEquipment && !values.room_id) {
        setError("Vui lòng chọn phòng gắn thiết bị.");
        return;
      }
      await onSave(values);
    }
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
                {roleOptions.map((role) => <option key={role} value={role}>{profileRoleLabels[role] || role}</option>)}
              </select>
            </div>
            {code && field(code.key, code.label)}
            {profileHasFaculty(values.role) && field("faculty", "Khoa")}
            {record && <div className="data-account-status">
            <label className="data-checkbox"><input type="checkbox" checked={values.is_active === true} disabled={isSelf}
              onChange={(event) => { set("is_active", event.target.checked); setStatusConfirmed(false); }} />Tài khoản đang hoạt động</label>
            {statusChanged && <label className="data-checkbox"><input type="checkbox" checked={statusConfirmed}
              onChange={(event) => setStatusConfirmed(event.target.checked)} />
              {values.is_active ? "Xác nhận mở lại tài khoản" : "Xác nhận vô hiệu hóa tài khoản"}
            </label>}
            </div>}
            {isSelf && <p className="data-hint">Bạn không thể tự đổi vai trò hoặc vô hiệu hóa tài khoản đang đăng nhập tại đây.</p>}
          </> : <>
            {field("name", table === "rooms" ? "Tên phòng" : "Tên thiết bị", { required: true })}
            {table === "rooms" && field("location", "Vị trí")}
            {table === "rooms" ? <>
              {field("capacity", "Sức chứa", { type: "number", required: true, min: 1, max: 2147483647 })}
              <div className="form-group">
                <label htmlFor="record-room-status">Trạng thái</label>
                <select id="record-room-status" value={String(values.is_active === true)} onChange={(event) => set("is_active", event.target.value === "true")}>
                  <option value="true">{facilityStatusLabel(true)}</option>
                  <option value="false">{facilityStatusLabel(false)}</option>
                </select>
              </div>
            </> : <>
              <div className="form-group">
                <label htmlFor="record-equipment-placement">Phạm vi sử dụng</label>
                <select id="record-equipment-placement" value={fixedEquipment ? "fixed" : "shared"} onChange={(event) => {
                  const fixed = event.target.value === "fixed";
                  setFixedEquipment(fixed);
                  if (!fixed) set("room_id", "");
                }}>
                  <option value="shared">Thiết bị dùng chung</option>
                  <option value="fixed">Thiết bị gắn cố định trong phòng</option>
                </select>
                <p className="data-hint">{fixedEquipment
                  ? "Thiết bị gắn phòng sẽ ẩn khỏi danh mục thiết bị trên mobile."
                  : "Thiết bị xuất hiện trong danh mục mobile. Ghi nơi đặt hoặc nhận thiết bị ở ô Vị trí."}</p>
              </div>
              {fixedEquipment && <div className="form-group">
                <label htmlFor="record-room_id">Phòng *</label>
                <select id="record-room_id" value={values.room_id} required disabled={referenceBlocked} onChange={(event) => set("room_id", event.target.value)}>
                  <option value="">Chọn phòng</option>
                  {record?.room_id && !references.rooms.some((room) => room.id === record.room_id)
                    && <option value={record.room_id}>{record.room?.name || "Phòng hiện tại (đã lưu trữ)"}</option>}
                  {references.rooms.map((room) => <option key={room.id} value={room.id}>{room.name}{room.is_active ? "" : ` (${facilityStatusLabel(false)})`}</option>)}
                </select>
              </div>}
              {field("location", "Vị trí")}
              <div className="form-group">
                <label htmlFor="record-status">Trạng thái *</label>
                <select id="record-status" value={values.status === "in_use" ? "" : values.status} required onChange={(event) => set("status", event.target.value)}>
                  {record?.status === "in_use" && <option value="" disabled>Đang sử dụng (trạng thái cũ) · Chọn trạng thái mới</option>}
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
        <button className="data-primary" type="submit" disabled={saving || referenceBlocked || statusUnconfirmed} aria-busy={saving}>{saving ? "Đang lưu…" : record ? "Lưu thay đổi" : "Thêm mới"}</button>
      </footer>
    </form>
  </DataDialog>;
}
