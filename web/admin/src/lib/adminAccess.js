export async function loadProfile(client, userId, signal) {
  const { data, error } = await client
    .from("profiles")
    .select("id, email, full_name, role, is_active")
    .eq("id", userId)
    .abortSignal(signal)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export function getAdminAccess(userId, profile, loadError = null) {
  if (loadError) return { isAdmin: false, accessError: "Không thể kiểm tra quyền truy cập. Vui lòng thử lại hoặc liên hệ quản trị viên." };
  if (!profile || profile.id !== userId) return { isAdmin: false, accessError: "Không tìm thấy hồ sơ tài khoản. Vui lòng liên hệ quản trị viên để được cấp quyền." };
  if (profile.is_active !== true) return { isAdmin: false, accessError: "Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên." };
  if (profile.role !== "admin") return { isAdmin: false, accessError: "Tài khoản của bạn không có quyền truy cập trang quản trị." };
  return { isAdmin: true, accessError: null };
}
