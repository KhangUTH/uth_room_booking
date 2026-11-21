import { validateCreateUser } from "./validation.js";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const reply = (status, message) => new Response(JSON.stringify({ message }), { status, headers });

export function createAdminUserHandler(createClient, readEnv) {
  return async (request) => {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
    if (request.method !== "POST") return reply(405, "Phương thức không được hỗ trợ.");
    const token = request.headers.get("Authorization")?.match(/^Bearer (.+)$/i)?.[1];
    if (!token) return reply(401, "Vui lòng đăng nhập lại.");

    try {
      const url = readEnv("SUPABASE_URL");
      const key = readEnv("SUPABASE_SERVICE_ROLE_KEY");
      if (!url || !key) return reply(500, "Máy chủ chưa được cấu hình đầy đủ.");
      const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
      // Verify the caller against Auth, then check the current database role.
      const { data: { user }, error: authError } = await admin.auth.getUser(token);
      if (authError || !user) return reply(401, "Phiên đăng nhập không hợp lệ.");
      const { data: caller, error: callerError } = await admin.from("profiles").select("role,is_active").eq("id", user.id).maybeSingle();
      if (callerError || caller?.role !== "admin" || caller.is_active !== true) return reply(403, "Bạn không có quyền tạo tài khoản.");

      // Invoke with the caller JWT, so the role-list RPC enforces its admin check.
      const callerClient = createClient(url, key, {
        global: { headers: { Authorization: `Bearer ${token}` } },
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data: roles, error: rolesError } = await callerClient.rpc("admin_user_roles");
      if (rolesError || !Array.isArray(roles)) return reply(500, "Chưa cài đặt danh sách vai trò trên máy chủ.");
      let input;
      try { input = validateCreateUser(await request.json(), roles); }
      catch (error) { return reply(400, error instanceof Error ? error.message : "Dữ liệu không hợp lệ."); }

      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email: input.email, password: input.password, email_confirm: true,
        user_metadata: { full_name: input.profile.full_name },
      });
      if (createError || !created.user) {
        if (["email_exists", "user_already_exists"].includes(createError?.code ?? "")) return reply(409, "Email đã tồn tại trong hệ thống.");
        if (createError?.code === "weak_password") return reply(400, "Mật khẩu chưa đáp ứng chính sách bảo mật của Supabase.");
        return reply(400, "Không thể tạo tài khoản. Vui lòng kiểm tra email, mật khẩu và cấu hình tạo người dùng.");
      }

      // Supports projects where an Auth trigger already created the profile.
      const { error: profileError } = await admin.from("profiles").upsert({
        id: created.user.id, email: created.user.email, ...input.profile,
      }, { onConflict: "id" });
      if (profileError) {
        const { error: cleanupError } = await admin.auth.admin.deleteUser(created.user.id);
        return reply(500, cleanupError
          ? "Tài khoản đã được tạo nhưng chưa lưu được hồ sơ. Hãy liên hệ quản trị viên để kiểm tra trước khi tạo lại."
          : "Không lưu được hồ sơ người dùng. Tài khoản vừa tạo đã được thu hồi; vui lòng kiểm tra mã số và quy tắc dữ liệu.");
      }
      return new Response(JSON.stringify({ id: created.user.id }), { status: 201, headers });
    } catch {
      return reply(500, "Không thể hoàn tất yêu cầu. Vui lòng thử lại sau.");
    }
  };
}
