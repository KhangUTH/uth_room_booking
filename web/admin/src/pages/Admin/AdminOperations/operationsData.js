import { searchFilter } from "../../../lib/adminData.js";

export const bookingStatuses = {
  pending: { label: "Chờ duyệt", tone: "amber" },
  approved: { label: "Đã duyệt", tone: "green" },
  rejected: { label: "Từ chối", tone: "red" },
  completed: { label: "Hoàn thành", tone: "blue" },
  cancelled: { label: "Đã hủy", tone: "neutral" },
};

export const supportStatuses = {
  new: { label: "Chờ phản hồi", tone: "amber" },
  replied: { label: "Đã phản hồi", tone: "green" },
};

export const pageSize = 10;
export const bookingTable = "uth_admin_bookings";
export const supportTable = "support_requests";
const bookingColumns = "id,status,start_time,end_time,created_at,room_id,equipment_id,room_name,equipment_name,requester_name,requester_role";
const supportColumns = "id,subject,message,reply,created_at,requester:profiles!support_requests_user_id_fkey(full_name,email)";
const zone = "Asia/Ho_Chi_Minh";
const dateFormat = new Intl.DateTimeFormat("vi-VN", { dateStyle: "short", timeZone: zone });
const timeFormat = new Intl.DateTimeFormat("vi-VN", { hour: "2-digit", minute: "2-digit", timeZone: zone });
const dateTimeFormat = new Intl.DateTimeFormat("vi-VN", { dateStyle: "short", timeStyle: "short", timeZone: zone });
export const displayDate = (value) => dateFormat.format(new Date(value));
export const displayTime = (value) => timeFormat.format(new Date(value));
export const displayDateTime = (value) => dateTimeFormat.format(new Date(value));

function localDay(date) {
  return new Date(date.getTime() + 7 * 3600000).toISOString().slice(0, 10);
}

function addDays(day, count) {
  const date = new Date(`${day}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + count);
  return date.toISOString().slice(0, 10);
}

const startOfDay = (day) => `${day}T00:00:00+07:00`;

export function bookingWeek(previous, now = new Date()) {
  const today = localDay(now);
  const weekday = new Date(`${today}T00:00:00Z`).getUTCDay();
  const monday = addDays(today, -((weekday + 6) % 7) - (previous ? 7 : 0));
  const days = Array.from({ length: 7 }, (_, index) => addDays(monday, index));
  return { days, label: `${displayDate(startOfDay(monday))} – ${displayDate(startOfDay(days[6]))}` };
}

async function countRows(query, signal) {
  const { count, error } = await query.abortSignal(signal);
  if (error) throw error;
  return count;
}

function exactCount(client, table) {
  return client.from(table).select("id", { head: true, count: "exact" });
}

async function pageOf(query, page, signal) {
  const start = (page - 1) * pageSize;
  const { data, count, error } = await query.order("created_at", { ascending: false }).order("id")
    .range(start, start + pageSize - 1).abortSignal(signal);
  if (error) throw error;
  return { rows: data, count };
}

export function bookingAsset(row) {
  return [row.room_name, row.equipment_name].filter(Boolean).join(" · ") || "—";
}

export function bookingType(row) {
  if (row.room_id && row.equipment_id) return "Phòng và thiết bị";
  return row.room_id ? "Phòng" : "Thiết bị";
}

export function listBookings(client, { status, type, date, search, page }, signal) {
  let query = client.from(bookingTable).select(bookingColumns, { count: "exact" });
  if (status) query = query.eq("status", status);
  if (type) query = query.not(type, "is", null);
  if (date) query = query.gte("start_time", startOfDay(date)).lt("start_time", startOfDay(addDays(date, 1)));
  if (search.trim()) query = query.or(searchFilter(["booking_code", "requester_name", "room_name", "equipment_name"], search));
  return pageOf(query, page, signal);
}

export function countBookings(client, signal) {
  return Promise.all([
    countRows(exactCount(client, bookingTable), signal),
    countRows(exactCount(client, bookingTable).eq("status", "pending"), signal),
    countRows(exactCount(client, bookingTable).eq("status", "approved"), signal),
  ]);
}

export async function readBooking(client, id, signal) {
  if (!/^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$/i.test(id)) return null;
  const { data, error } = await client.from(bookingTable)
    .select(`${bookingColumns},purpose,student_count,teaching_section_code,teaching_section_name`)
    .eq("id", id).maybeSingle().abortSignal(signal);
  if (error?.code === "42703" || error?.code === "PGRST204") {
    throw { userMessage: "Supabase chưa cập nhật cấu trúc dữ liệu đăng ký lịch. Hãy áp dụng migration duyệt lịch rồi tải lại." };
  }
  if (error) throw error;
  return data;
}

export async function decideBooking(client, id, decision) {
  const { error } = await client.rpc("uth_admin_decide_booking", { booking_id: id, decision })
    .abortSignal(AbortSignal.timeout(15000));
  if (error?.code === "P0002") throw { userMessage: "Đăng ký đã thay đổi. Hãy đóng và mở lại chi tiết để xem trạng thái mới." };
  if (error?.code === "23514" && error.message === "booking_asset_unavailable") {
    throw { userMessage: "Phòng hoặc thiết bị hiện không khả dụng. Bạn vẫn có thể từ chối đăng ký." };
  }
  if (error?.code === "23514" && error.message === "booking_already_started") {
    throw { userMessage: "Ca đăng ký đã bắt đầu. Bạn vẫn có thể từ chối đăng ký." };
  }
  if (error) throw error;
}

export function listSupport(client, { status, search, page }, signal) {
  let query = client.from(supportTable).select(supportColumns, { count: "exact" });
  if (status === "new") query = query.is("reply", null);
  if (status === "replied") query = query.not("reply", "is", null);
  if (search.trim()) query = query.or(searchFilter(["subject", "message"], search));
  return pageOf(query, page, signal);
}

export function countPendingSupport(client, signal) {
  return countRows(exactCount(client, supportTable).is("reply", null), signal);
}

export async function readSupport(client, id, signal) {
  if (!/^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$/i.test(id)) return null;
  const { data, error } = await client.from(supportTable).select(supportColumns).eq("id", id).maybeSingle().abortSignal(signal);
  if (error) throw error;
  return data;
}

export async function replyToSupport(client, id, reply) {
  const { error } = await client.from(supportTable).update({ reply }).eq("id", id).is("reply", null)
    .select("id").single().abortSignal(AbortSignal.timeout(15000));
  if (error?.code === "PGRST116") throw { userMessage: "Yêu cầu đã thay đổi. Hãy tải lại hộp thư để xem phản hồi hiện tại." };
  if (error) throw error;
}

export function loadOverviewCounts(client, signal) {
  return Promise.allSettled([
    Promise.all([
      countRows(exactCount(client, "rooms").eq("is_archived", false).eq("is_active", true), signal),
      countRows(exactCount(client, "rooms").eq("is_archived", false), signal),
    ]),
    Promise.all([
      countRows(exactCount(client, "equipment").eq("status", "available"), signal),
      countRows(exactCount(client, "equipment"), signal),
    ]),
    countRows(exactCount(client, bookingTable).eq("status", "pending"), signal),
    countPendingSupport(client, signal),
  ]);
}

export async function loadBookingBars(client, days, signal) {
  const counts = new Map(days.map((day) => [day, [0, 0]]));
  const batchSize = 200;
  for (let start = 0; ; start += batchSize) {
    const { data, error } = await client.from(bookingTable).select("created_at,room_id,equipment_id")
      .gte("created_at", startOfDay(days[0])).lt("created_at", startOfDay(addDays(days.at(-1), 1)))
      .order("created_at").order("id").range(start, start + batchSize - 1).abortSignal(signal);
    if (error) throw error;
    for (const row of data) {
      const totals = counts.get(localDay(new Date(row.created_at)));
      if (row.room_id) totals[0]++;
      else if (row.equipment_id) totals[1]++;
    }
    if (data.length < batchSize) break;
  }
  return [...counts.values()];
}

export async function loadRecentActivity(client, signal) {
  async function latest(table, columns) {
    const { data, error } = await client.from(table).select(columns).order("created_at", { ascending: false })
      .order("id").limit(3).abortSignal(signal);
    if (error) throw error;
    return data;
  }

  const [bookings, support] = await Promise.allSettled([
    latest(bookingTable, "id,created_at,room_name,equipment_name,requester_name"),
    latest(supportTable, "id,subject,created_at"),
  ]);
  const rows = [
    ...(bookings.value ?? []).map((row) => ({
      id: row.id, createdAt: row.created_at, title: `Đăng ký ${bookingAsset(row)}`, description: row.requester_name,
      path: `/managercalendar?ma=${row.id}`, tone: "blue", icon: "calendar-plus",
    })),
    ...(support.value ?? []).map((row) => ({
      id: row.id, createdAt: row.created_at, title: row.subject, description: "Yêu cầu hỗ trợ",
      path: `/managersupport?ma=${row.id}`, tone: "violet", icon: "message",
    })),
  ].sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt)).slice(0, 3);
  return { rows, error: bookings.reason || support.reason };
}
