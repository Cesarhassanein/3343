import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/auth_service.dart';
import 'register_screen.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال اسم المستخدم/البريد الإلكتروني وكلمة المرور"),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.instance.login(
        usernameOrEmail: identifier,
        password: password,
      );

      if (!mounted) return;
      if (!success) throw StateError('تعذر تسجيل الدخول.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('StateError: ', '').replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: WadiqColors.alert,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final identifierController = TextEditingController(text: _identifierController.text);
    final newPasswordController = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: WadiqColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: WadiqColors.primaryAmber),
              const SizedBox(width: 8),
              Text("استعادة كلمة المرور", style: WadiqTypography.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "أدخل اسم المستخدم أو البريد المسجل لتحديث كلمة المرور:",
                style: WadiqTypography.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: WadiqColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WadiqColors.surfaceBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: identifierController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "اسم المستخدم أو البريد",
                    hintStyle: TextStyle(color: WadiqColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: WadiqColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WadiqColors.surfaceBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "كلمة المرور الجديدة (أحرف وأرقام)",
                    hintStyle: TextStyle(color: WadiqColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: WadiqColors.primaryAmber),
              onPressed: isResetting
                  ? null
                  : () async {
                      final id = identifierController.text.trim();
                      final pwd = newPasswordController.text.trim();
                      if (id.isEmpty || pwd.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى ملء كافة الحقول.')),
                        );
                        return;
                      }
                      setDialogState(() => isResetting = true);
                      try {
                        await AuthService.instance.resetPassword(
                          usernameOrEmail: id,
                          newPassword: pwd,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول بها.'),
                            backgroundColor: WadiqColors.success,
                          ),
                        );
                      } catch (err) {
                        setDialogState(() => isResetting = false);
                        final msg = err.toString().replaceFirst('StateError: ', '');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg), backgroundColor: WadiqColors.alert),
                        );
                      }
                    },
              child: isResetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("تعيين كلمة المرور", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo & Glow
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: WadiqColors.amberGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: WadiqColors.amberGlow,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "و",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text("منصة ودق", style: WadiqTypography.displayLarge),
                const SizedBox(height: 6),
                Text(
                  "المنصة الاجتماعية والتعليمية المتكاملة",
                  style: WadiqTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Identifier field (Username or Email)
                Container(
                  decoration: BoxDecoration(
                    color: WadiqColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WadiqColors.surfaceBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    style: WadiqTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      icon: const Icon(Icons.person_outline_rounded, color: WadiqColors.textMuted, size: 20),
                      hintText: "اسم المستخدم أو البريد الإلكتروني",
                      hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Password field
                Container(
                  decoration: BoxDecoration(
                    color: WadiqColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WadiqColors.surfaceBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: WadiqTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      icon: const Icon(Icons.lock_outline, color: WadiqColors.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: WadiqColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      hintText: "كلمة المرور",
                      hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Forgot Password Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      "نسيت كلمة المرور؟",
                      style: WadiqTypography.caption.copyWith(
                        color: WadiqColors.primaryAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Button
                WadiqButton(
                  text: "تسجيل الدخول",
                  width: double.infinity,
                  height: 50,
                  isLoading: _isLoading,
                  onPressed: _login,
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ليس لديك حساب؟", style: WadiqTypography.bodyMedium),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        "إنشاء حساب جديد",
                        style: WadiqTypography.titleMedium.copyWith(
                          color: WadiqColors.primaryAmber,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
