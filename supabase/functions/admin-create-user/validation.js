export function validateCreateUser(body, roles) {
  if (!body || typeof body !== "object") throw new Error("Dữ liệu yêu cầu không hợp lệ.");
  const { email, password, profile } = body;
  if (typeof email !== "string" || email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) throw new Error("Email không hợp lệ.");
  if (typeof password !== "string" || password.length < 8 || password.length > 128) throw new Error("Mật khẩu cần từ 8 đến 128 ký tự.");
  if (!profile || typeof profile.full_name !== "string" || !profile.full_name.trim() || profile.full_name.length > 255) throw new Error("Họ tên không hợp lệ.");
  if (!roles.includes(profile.role)) throw new Error("Vai trò không hợp lệ.");
  if (typeof profile.is_active !== "boolean") throw new Error("Trạng thái tài khoản không hợp lệ.");
  const result = { full_name: profile.full_name.trim(), role: profile.role, is_active: profile.is_active };
  for (const field of ["student_code", "lecturer_code", "employee_code", "faculty"]) {
    const value = profile[field];
    if (value != null && (typeof value !== "string" || value.length > 255)) throw new Error("Mã số hoặc khoa không hợp lệ.");
    result[field] = value?.trim() || null;
  }
  return { email: email.trim(), password, profile: result };
}
