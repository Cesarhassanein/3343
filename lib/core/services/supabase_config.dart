import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // Active production Supabase project details
  static const String defaultUrl = 'https://uelyholtcelfgaierkpp.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlbHlob2x0Y2VsZmdhaWVya3BwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMzNjQ1ODQsImV4cCI6MjEwODk0MDU4NH0.CLXb2vGP5mo9-4wNkffm1gN14RFolIkSWh9RqTcKua0';

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _envUrl.isNotEmpty ? _envUrl : defaultUrl;
  static String get supabaseAnonKey =>
      _envAnonKey.isNotEmpty ? _envAnonKey : defaultAnonKey;

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

  static Future<void> initialize() async {
    try {
      if (isConfigured) {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
        );
        debugPrint('Supabase successfully connected to: $supabaseUrl');
      } else {
        debugPrint('Supabase credentials are not configured.');
      }
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

  static SupabaseClient? get client {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static void requireClient() {
    if (client == null) {
      throw StateError('لم يتم إعداد اتصال Supabase.');
    }
  }
}
