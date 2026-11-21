export function authErrorMessage(error) {
  const messages = {
    invalid_credentials: "Email hoặc mật khẩu không chính xác.",
    email_not_confirmed: "Vui lòng xác nhận email trước khi đăng nhập.",
    over_request_rate_limit: "Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.",
    over_email_send_rate_limit: "Vui lòng đợi một lúc trước khi yêu cầu gửi lại email.",
    weak_password: "Mật khẩu chưa đáp ứng yêu cầu bảo mật của hệ thống.",
    same_password: "Mật khẩu mới phải khác mật khẩu hiện tại.",
    otp_expired: "Liên kết đã hết hạn. Vui lòng yêu cầu một liên kết mới.",
    session_not_found: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
    user_banned: "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.",
  };
  if (messages[error?.code]) return messages[error.code];
  if (error?.name === "AuthRetryableFetchError" || error instanceof TypeError) {
    return "Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.";
  }
  return "Không thể hoàn tất yêu cầu. Vui lòng thử lại sau hoặc liên hệ quản trị viên.";
}
