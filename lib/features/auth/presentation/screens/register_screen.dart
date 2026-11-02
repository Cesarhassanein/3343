import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _avatarBase64;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final List<String> _presetAvatars = const [
    'https://api.dicebear.com/7.x/bottts/png?seed=WadiqStudent1',
    'https://api.dicebear.com/7.x/bottts/png?seed=WadiqStudent2',
    'https://api.dicebear.com/7.x/bottts/png?seed=WadiqStudent3',
    'https://api.dicebear.com/7.x/bottts/png?seed=WadiqStudent4',
    'https://api.dicebear.com/7.x/bottts/png?seed=WadiqStudent5',
    'https://api.dicebear.com/7.x/bottts/png?seed=WadiqStudent6',
  ];

  Future<void> _pickAvatarFromGallery() async {
    try {
      XFile? img;
      try {
        img = await _picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        img = await _picker.pickMedia();
      }
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() {
          _avatarBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح المعرض: $e. يمكنك اختيار شخصية رمزية جاهزة أدناه.'),
            backgroundColor: WadiqColors.alert,
          ),
        );
      }
    }
  }

  void _showAvatarOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("اختيار صورة للملف الشخصي", style: WadiqTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: WadiqColors.primaryAmber),
              ),
              title: Text("اختيار صورة من هاتفك / حاسوبك", style: WadiqTypography.bodyLarge),
              subtitle: Text("من المعرض أو الملفات المحفوظة", style: WadiqTypography.caption),
              onTap: _pickAvatarFromGallery,
            ),
            const Divider(color: WadiqColors.surfaceBorder, height: 28),
            Text("أو اختر شخصية رمزية جاهزة بنقرة واحدة:", style: WadiqTypography.bodyMedium.copyWith(color: Colors.white70)),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final url = _presetAvatars[i];
                  final isSelected = _avatarBase64 == url;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _avatarBase64 = url;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder,
                          width: isSelected ? 2.5 : 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: WadiqColors.primaryAmber),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    if (_avatarBase64 == null) {
      return const Center(
        child: Icon(
          Icons.add_a_photo_outlined,
          size: 34,
          color: WadiqColors.primaryAmber,
        ),
      );
    }
    if (_avatarBase64!.startsWith('data:image')) {
      try {
        final comma = _avatarBase64!.indexOf(',');
        final base64Data = comma != -1 ? _avatarBase64!.substring(comma + 1) : _avatarBase64!;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: WadiqColors.primaryAmber),
        );
      } catch (_) {}
    }
    return Image.network(
      _avatarBase64!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: WadiqColors.primaryAmber),
    );
  }

  void _register() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.replaceAll('@', '').trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_avatarBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى اختيار صورة للملف الشخصي لإتمام إنشاء الحساب 📷"),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    if (fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى ملء جميع الحقول المطلوبة"),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    if (!AuthService.isPasswordStrong(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("كلمة المرور يجب أن تتكون من 6 خانات على الأقل وتجمع بين الحروف والأرقام."),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload avatar via backend API → Telegram (if it's a Base64 data URL)
      String? finalAvatarUrl = _avatarBase64;
      if (_avatarBase64 != null && _avatarBase64!.startsWith('data:image')) {
        final uploadedUrl = await WadiqApiService.instance.uploadBase64Image(
          _avatarBase64!,
          fileName: 'avatar_${username}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ownerUsername: username,
        );
        if (uploadedUrl != null) {
          finalAvatarUrl = uploadedUrl;
        }
        // If upload fails, keep the Base64 as fallback
      }

      final success = await AuthService.instance.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        role: 'طالب',
        avatarUrl: finalAvatarUrl,
      );

      if (!mounted) return;
      if (!success) throw StateError('تعذر إنشاء الحساب.');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('StateError: ', '').replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: WadiqColors.alert,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("إنشاء حساب جديد", style: WadiqTypography.titleLarge),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("انضم إلى مجتمع ودق 🚀", style: WadiqTypography.displayMedium.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text("أنشئ حسابك الأكاديمي وشارك المعرفة مع زملائك", style: WadiqTypography.bodyMedium),
              const SizedBox(height: 24),

              // Profile Image Selector
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _showAvatarOptionsModal,
                      borderRadius: BorderRadius.circular(50),
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: WadiqColors.cardSurface,
                              border: Border.all(
                                color: _avatarBase64 != null ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder,
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildAvatarWidget(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: WadiqColors.primaryAmber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _avatarBase64 != null ? "تم اختيار صورة الحساب ✓" : "اضغط لاختيار صورة الحساب (مطلوبة)",
                      style: WadiqTypography.caption.copyWith(
                        color: _avatarBase64 != null ? WadiqColors.success : WadiqColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Role Selector (Only Student active; Instructor is Coming Soon)
              Text("نوع الحساب:", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: WadiqColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WadiqColors.primaryAmber, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school_outlined, color: WadiqColors.primaryAmber, size: 26),
                          const SizedBox(height: 8),
                          Text("حساب طالب", style: WadiqTypography.titleMedium.copyWith(fontSize: 14, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text("للدراسة والتفاعل الأكاديمي", style: WadiqTypography.caption.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: 0.6,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: WadiqColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: WadiqColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.cast_for_education, color: WadiqColors.textMuted, size: 26),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: WadiqColors.elevatedSurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("قريباً", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("حساب أستاذ", style: WadiqTypography.titleMedium.copyWith(fontSize: 14, color: Colors.white60)),
                            const SizedBox(height: 2),
                            Text("للكادر التدريسي المعتمد", style: WadiqTypography.caption.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Full Name
              _buildInputField(
                controller: _fullNameController,
                hint: "الاسم الكامل (أي اسم تختاره)",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              // Username
              _buildInputField(
                controller: _usernameController,
                hint: "اسم المستخدم (Username فريد)",
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 14),

              // Email
              _buildInputField(
                controller: _emailController,
                hint: "البريد الإلكتروني",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password
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
                    hintText: "كلمة المرور القوية",
                    hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "شرط: يجب أن تحتوي كلمة المرور على 6 خانات وتجمع بين الحروف والأرقام.",
                  style: WadiqTypography.caption.copyWith(fontSize: 11, color: Colors.white38),
                ),
              ),

              const SizedBox(height: 28),

              // Register Button
              WadiqButton(
                text: "تأكيد وإنشاء الحساب",
                width: double.infinity,
                height: 52,
                isLoading: _isLoading,
                onPressed: _register,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: WadiqTypography.bodyMedium.copyWith(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: WadiqColors.textMuted, size: 20),
          hintText: hint,
          hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
