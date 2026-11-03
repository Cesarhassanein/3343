import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/wadiq_theme.dart';
import 'core/services/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/wadiq_api_service.dart';
import 'core/services/chat_settings_service.dart';
import 'core/utils/picker_initializer.dart';
import 'features/shell/presentation/screens/main_shell_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupImagePicker();
  await WadiqApiService.instance.init();
  await SupabaseConfig.initialize();
  await AuthService.instance.initSession();
  await ChatSettingsService.instance.init();
  runApp(const WadiqApp());
}

class WadiqApp extends StatelessWidget {
  const WadiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ودق - Wadiq',
      debugShowCheckedModeBanner: false,
      theme: WadiqTheme.darkTheme,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StreamBuilder(
        stream: SupabaseConfig.client?.auth.onAuthStateChange,
        builder: (context, _) => AuthService.instance.isAuthenticated
            ? const MainShellScreen()
            : const LoginScreen(),
      ),
    );
  }
}
