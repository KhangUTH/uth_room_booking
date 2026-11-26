export const PAGE_SIZE = 10;
export const facilityStatusLabel = (active) => active ? "Hoạt động" : "Bảo trì";
export const equipmentStatuses = [
  { value: "available", label: facilityStatusLabel(true) },
  { value: "broken", label: facilityStatusLabel(false) },
];
export const equipmentStatusLabel = (status) =>
  equipmentStatuses.find(({ value }) => value === status)?.label || (status === "in_use" ? "Đang sử dụng (trạng thái cũ)" : "Chưa xác định");
export const profileRoleLabels = { admin: "Quản trị viên", student: "Sinh viên", teacher: "Giảng viên", lecturer: "Giảng viên", technician: "Nhân viên kỹ thuật" };
export const profileCodeFields = {
  student: { key: "student_code", label: "Mã sinh viên" },
  teacher: { key: "lecturer_code", label: "Mã giảng viên" },
  lecturer: { key: "lecturer_code", label: "Mã giảng viên" },
  technician: { key: "employee_code", label: "Mã nhân viên" },
};
export const profileHasFaculty = (role) => ["student", "teacher", "lecturer"].includes(role);

export const entities = {
  profiles: {
    title: "QUẢN LÝ NGƯỜI DÙNG", singular: "người dùng", add: "Thêm người dùng", icon: "fa-solid fa-users",
    columns: "id,email,full_name,student_code,lecturer_code,employee_code,faculty,role,is_active,created_at",
    search: ["full_name", "email", "student_code", "lecturer_code", "employee_code"],
  },
  rooms: {
    title: "QUẢN LÝ PHÒNG", singular: "phòng", add: "Thêm phòng", icon: "fa-solid fa-door-open",
    columns: "id,name,location,capacity,is_active,is_archived,created_at", search: ["name", "location"],
  },
  equipment: {
    title: "QUẢN LÝ THIẾT BỊ", singular: "thiết bị", add: "Thêm thiết bị", icon: "fa-solid fa-hard-drive",
    columns: "id,name,room_id,status,note,location,created_at,room:rooms(id,name,location)", search: ["name", "location", "note"],
  },
};

export function dataErrorMessage(error) {
  if (error?.userMessage) return error.userMessage;
  const messages = {
    "42501": "Bạn không có quyền thao tác dữ liệu này. Vui lòng kiểm tra quyền quản trị và RLS trên Supabase.",
    "23505": "Thông tin đã tồn tại. Vui lòng kiểm tra email, tên hoặc mã số.",
    "23503": "Dữ liệu đang liên kết với bản ghi khác. Vui lòng kiểm tra phòng hoặc tài khoản liên quan.",
    "23514": "Dữ liệu chưa đáp ứng quy tắc của hệ thống. Vui lòng kiểm tra trạng thái, vai trò và các trường bắt buộc.",
    "22P02": "Giá trị nhập không hợp lệ. Vui lòng kiểm tra số, trạng thái hoặc vai trò.",
    "PGRST202": "Chưa cài đặt hàm quản lý trên Supabase. Vui lòng liên hệ quản trị viên.",
    "PGRST204": "Cấu trúc bảng trên Supabase chưa khớp với ứng dụng.",
    "PGRST205": "Không tìm thấy bảng dữ liệu trên Supabase.",
    "PGRST116": "Không thể cập nhật bản ghi. Dữ liệu có thể đã thay đổi hoặc bạn không còn quyền truy cập.",
  };
  return messages[error?.code] || "Không thể hoàn tất yêu cầu. Vui lòng kiểm tra kết nối và thử lại.";
}

export function searchFilter(columns, text) {
  const literal = text.trim().slice(0, 120).replace(/[\\%_]/g, "\\$&");
  return columns.map((column) => `${column}.ilike.${JSON.stringify(`%${literal}%`)}`).join(",");
}

export async function listRecords(client, table, { page = 1, search = "", filter = "", signal } = {}) {
  const config = entities[table];
  if (!config) throw new Error("Unsupported entity");
  let query = client.from(table).select(config.columns, { count: "exact" });
  if (search.trim()) query = query.or(searchFilter(config.search, search));
  if (table === "rooms") query = query.eq("is_archived", false);
  if (filter) {
    if (table === "profiles") query = query.eq("role", filter);
    else if (table === "rooms") query = query.eq("is_active", filter === "active");
    else query = query.eq("room_id", filter);
  }
  const start = (Math.max(1, page) - 1) * PAGE_SIZE;
  if (table === "rooms") query = query.order("is_active", { ascending: false, nullsFirst: false });
  const { data, error, count } = await query.order("created_at", { ascending: false }).order("id").range(start, start + PAGE_SIZE - 1).abortSignal(signal);
  if (error) throw error;
  return { rows: data ?? [], count: count ?? 0 };
}

function optional(value) { return value?.trim() || null; }

export function recordPayload(table, values) {
  if (table === "profiles" && (!values.full_name?.trim() || !values.role)) throw { userMessage: "Vui lòng nhập họ tên và chọn vai trò." };
  if (table !== "profiles" && !values.name?.trim()) throw { userMessage: "Vui lòng nhập tên hợp lệ." };
  if (table === "equipment" && !values.status?.trim()) throw { userMessage: "Vui lòng nhập trạng thái thiết bị." };
  if (table === "equipment" && !equipmentStatuses.some(({ value }) => value === values.status.trim())) throw { userMessage: "Chọn Hoạt động hoặc Bảo trì cho thiết bị." };
  if (table === "profiles") return {
    full_name: values.full_name.trim(), role: values.role, is_active: values.is_active,
    student_code: profileCodeFields[values.role]?.key === "student_code" ? optional(values.student_code) : null,
    lecturer_code: profileCodeFields[values.role]?.key === "lecturer_code" ? optional(values.lecturer_code) : null,
    employee_code: profileCodeFields[values.role]?.key === "employee_code" ? optional(values.employee_code) : null,
    faculty: profileHasFaculty(values.role) ? optional(values.faculty) : null,
  };
  if (table === "rooms") {
    const capacity = Number(values.capacity);
    if (!values.capacity?.toString().trim() || !Number.isInteger(capacity) || capacity < 1 || capacity > 2147483647) {
      throw { userMessage: "Sức chứa phải là số nguyên dương hợp lệ." };
    }
    return { name: values.name.trim(), location: optional(values.location), capacity, is_active: values.is_active };
  }
  if (table === "equipment") return { name: values.name.trim(), room_id: values.room_id || null, status: values.status.trim(), note: optional(values.note), location: optional(values.location) };
  throw new Error("Unsupported entity");
}

export async function saveRecord(client, table, values, id) {
  const payload = recordPayload(table, values);
  if (!id && table === "profiles") {
    const { data, error } = await client.functions.invoke("admin-create-user", {
      body: { email: values.email.trim(), password: values.password, profile: payload },
    });
    if (error) {
      let body;
      try { body = await error.context?.json(); } catch { /* Server may return an empty/non-JSON error. */ }
      throw { userMessage: body?.message || "Không thể tạo tài khoản. Vui lòng kiểm tra hàm tạo người dùng trên Supabase và thử lại." };
    }
    return data;
  }
  const query = id ? client.from(table).update(payload).eq("id", id)
    : client.from(table).insert(table === "rooms" ? { ...payload, is_archived: false } : payload);
  const { data, error } = await query.select(entities[table].columns).single();
  if (error) throw error;
  return data;
}

export async function deleteRecord(client, table, id) {
  if (!["rooms", "equipment"].includes(table) || typeof id !== "string" || !id.trim()) throw new Error("Invalid delete target");
  const { data, error } = await client.from(table).delete().eq("id", id).select("id").single();
  if (error?.code === "23503") throw { userMessage: "Không thể xóa vì phòng hoặc thiết bị còn liên kết với dữ liệu khác, chẳng hạn lịch đặt, báo cáo sự cố hoặc đề xuất bảo trì." };
  if (error?.code === "PGRST116") throw { userMessage: "Không thể xóa: bản ghi có thể đã bị xóa hoặc bạn không còn quyền truy cập." };
  if (error) throw error;
  return data;
}

export async function loadReferences(client, table, signal) {
  if (table === "profiles") {
    const { data, error } = await client.rpc("admin_user_roles").abortSignal(signal);
    if (error) throw error;
    return { roles: data ?? [], rooms: [] };
  }
  if (table !== "equipment") return { roles: [], rooms: [] };
  const rooms = [];
  // Fetch every room option, including databases with more than the default API row limit.
  for (let start = 0; ; start += 500) {
    const { data, error } = await client.from("rooms").select("id,name,location,is_active")
      .eq("is_archived", false).order("name").order("id").range(start, start + 499).abortSignal(signal);
    if (error) throw error;
    rooms.push(...data);
    if (data.length < 500) break;
  }
  return { roles: [], rooms };
}
