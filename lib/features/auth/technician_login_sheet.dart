import "package:flutter/material.dart";
import "package:uth_room_booking/theme/app_colors.dart";

/// Mở bottom sheet đăng nhập dành cho kỹ thuật viên.
///
/// Trả về mã nhân viên (String) khi đăng nhập thành công,
/// hoặc null nếu người dùng đóng sheet.
Future<String?> showTechnicianLoginSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // để sheet đẩy lên theo bàn phím
    useSafeArea: true,
    backgroundColor: Colors.white,
    clipBehavior: Clip.antiAlias,
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const TechnicianLoginSheet(),
  );
}

class TechnicianLoginSheet extends StatefulWidget {
  const TechnicianLoginSheet({super.key});

  @override
  State<TechnicianLoginSheet> createState() => _TechnicianLoginSheetState();
}

class _TechnicianLoginSheetState extends State<TechnicianLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // DEMO: chưa có database, nhập gì cũng vào được (miễn không để trống).
  // Sau này thay đoạn này bằng gọi API / Firebase Auth.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _idCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    // Đẩy nội dung lên khi bàn phím mở.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 14),
            _buildLogo(),
            const SizedBox(height: 18),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  // ==== THANH KÉO ====
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD5DCDB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  // ==== LOGO ====
  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo/logo.jpg',
            height: 33,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, size: 33, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trường Đại học Giao Thông Vận Tải\nThành phố Hồ Chí Minh',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ==== FORM ====
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng nhập dành cho',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          const Text(
            'Kỹ thuật viên',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tài khoản hỗ trợ kỹ thuật và quản lý hệ thống',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          _label('Mã nhân viên'),
          TextFormField(
            controller: _idCtrl,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Nhập mã nhân viên'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập mã nhân viên'
                : null,
          ),
          const SizedBox(height: 14),
          _label('Mật khẩu'),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _remember,
                  side: const BorderSide(color: Color(0xFFB8C4C3), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nhớ mật khẩu',
                style: TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {}, // TODO: quên mật khẩu
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    ),
  );
}
