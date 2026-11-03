import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/wadiq_colors.dart';

/// Model representing a chat folder
class ChatFolderModel {
  final String id;
  String name;
  List<String> includedChatIds; // conversation IDs or usernames

  ChatFolderModel({
    required this.id,
    required this.name,
    this.includedChatIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'includedChatIds': includedChatIds,
  };

  factory ChatFolderModel.fromMap(Map<String, dynamic> map) => ChatFolderModel(
    id: map['id']?.toString() ?? 'folder_${DateTime.now().millisecondsSinceEpoch}',
    name: map['name']?.toString() ?? 'مجلد جديد',
    includedChatIds: (map['includedChatIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );
}

/// Color theme preset for chat bubbles
class ChatColorTheme {
  final String id;
  final String name;
  final Color senderBubbleColor;
  final Color receiverBubbleColor;
  final Color senderTextColor;
  final Color receiverTextColor;
  final Color accentColor;
  final Color borderColor;

  const ChatColorTheme({
    required this.id,
    required this.name,
    required this.senderBubbleColor,
    required this.receiverBubbleColor,
    required this.senderTextColor,
    required this.receiverTextColor,
    required this.accentColor,
    required this.borderColor,
  });
}

class ChatSettingsService extends ChangeNotifier {
  ChatSettingsService._();
  static final ChatSettingsService instance = ChatSettingsService._();

  static const String _keyFontSize = 'wadiq_chat_font_size';
  static const String _keyBubbleRadius = 'wadiq_chat_bubble_radius';
  static const String _keyWallpaper = 'wadiq_chat_wallpaper';
  static const String _keyColorTheme = 'wadiq_chat_color_theme';
  static const String _keyListPreviewMode = 'wadiq_chat_list_preview_mode';
  static const String _keyFolders = 'wadiq_chat_folders';

  // --- 1. Font Size (12.0 to 24.0, default: 15.0) ---
  double _fontSize = 15.0;
  double get fontSize => _fontSize;

  // --- 2. Bubble Corner Radius (4.0 to 28.0, default: 16.0) ---
  double _bubbleRadius = 16.0;
  double get bubbleRadius => _bubbleRadius;

  // --- 3. Chat Wallpaper (null = default dark, or 'preset_X', or base64 data URL) ---
  String? _wallpaper;
  String? get wallpaper => _wallpaper;

  // --- 4. Color Theme ---
  String _colorThemeId = 'amber_classic';
  String get colorThemeId => _colorThemeId;

  // --- 5. Chat List Preview Mode ---
  // 0: اسم الحساب فقط بدون رسائل
  // 1: اسم الحساب مع رسالة واحدة
  // 2: اسم الحساب مع رسالتين
  int _listPreviewMode = 1;
  int get listPreviewMode => _listPreviewMode;

  // --- 6. Chat Folders ---
  List<ChatFolderModel> _folders = [
    ChatFolderModel(id: 'all', name: 'الكل', includedChatIds: []),
    ChatFolderModel(id: 'academic', name: 'قنوات ودق', includedChatIds: []),
    ChatFolderModel(id: 'groups', name: 'المجموعات', includedChatIds: []),
    ChatFolderModel(id: 'direct', name: 'محادثات خاصة', includedChatIds: []),
  ];
  List<ChatFolderModel> get folders => _folders;

  static const List<ChatColorTheme> availableThemes = [
    ChatColorTheme(
      id: 'amber_classic',
      name: 'العنبر الملكي (افتراضي)',
      senderBubbleColor: Color(0xFF262118),
      receiverBubbleColor: Color(0xFF1E1E1E),
      senderTextColor: Colors.white,
      receiverTextColor: Colors.white,
      accentColor: WadiqColors.primaryAmber,
      borderColor: Color(0xFFD49B35),
    ),
    ChatColorTheme(
      id: 'emerald_academic',
      name: 'الزمرد الأكاديمي',
      senderBubbleColor: Color(0xFF132B20),
      receiverBubbleColor: Color(0xFF1A1F1C),
      senderTextColor: Colors.white,
      receiverTextColor: Colors.white,
      accentColor: Color(0xFF10B981),
      borderColor: Color(0xFF059669),
    ),
    ChatColorTheme(
      id: 'sapphire_night',
      name: 'الياقوت الليلي',
      senderBubbleColor: Color(0xFF17253B),
      receiverBubbleColor: Color(0xFF181B22),
      senderTextColor: Colors.white,
      receiverTextColor: Colors.white,
      accentColor: Color(0xFF38BDF8),
      borderColor: Color(0xFF0284C7),
    ),
    ChatColorTheme(
      id: 'amethyst_purple',
      name: 'الأرجواني الهادئ',
      senderBubbleColor: Color(0xFF281C38),
      receiverBubbleColor: Color(0xFF1C1822),
      senderTextColor: Colors.white,
      receiverTextColor: Colors.white,
      accentColor: Color(0xFFA855F7),
      borderColor: Color(0xFF9333EA),
    ),
    ChatColorTheme(
      id: 'crimson_sunset',
      name: 'شفق وادي',
      senderBubbleColor: Color(0xFF331A1E),
      receiverBubbleColor: Color(0xFF201718),
      senderTextColor: Colors.white,
      receiverTextColor: Colors.white,
      accentColor: Color(0xFFF43F5E),
      borderColor: Color(0xFFE11D48),
    ),
    ChatColorTheme(
      id: 'slate_monochrome',
      name: 'الرمادي الاحترافي',
      senderBubbleColor: Color(0xFF2A2E35),
      receiverBubbleColor: Color(0xFF1C1E22),
      senderTextColor: Colors.white,
      receiverTextColor: Colors.white,
      accentColor: Color(0xFF94A3B8),
      borderColor: Color(0xFF64748B),
    ),
  ];

  ChatColorTheme get activeTheme {
    return availableThemes.firstWhere(
      (t) => t.id == _colorThemeId,
      orElse: () => availableThemes[0],
    );
  }

  static const List<Map<String, String>> presetWallpapers = [
    {
      'id': 'preset_obsidian',
      'title': 'الظلام الماسي',
      'colors': '0xFF0D0E11,0xFF14171E',
      'desc': 'تدرج كلاسيكي مريح للعين'
    },
    {
      'id': 'preset_amber_glow',
      'title': 'وهج العنبر',
      'colors': '0xFF1A1208,0xFF0A0804',
      'desc': 'أجواء أكاديمية دافئة'
    },
    {
      'id': 'preset_midnight_blue',
      'title': 'سماء بغداد الليلية',
      'colors': '0xFF0A1220,0xFF050810',
      'desc': 'أزرق داكن فخم'
    },
    {
      'id': 'preset_forest_dark',
      'title': 'واحة دجلة',
      'colors': '0xFF091A12,0xFF040A07',
      'desc': 'أخضر هادئ ومريح'
    },
    {
      'id': 'preset_purple_mist',
      'title': 'أثير الحكمة',
      'colors': '0xFF160E22,0xFF07040B',
      'desc': 'تدرج بنفسجي راقٍ'
    },
    {
      'id': 'preset_geometric_pattern',
      'title': 'نقوش أكاديمية',
      'colors': '0xFF1A1C23,0xFF0F1015',
      'desc': 'مظهر رقمي حديث'
    },
  ];

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble(_keyFontSize) ?? 15.0;
      _bubbleRadius = prefs.getDouble(_keyBubbleRadius) ?? 16.0;
      _wallpaper = prefs.getString(_keyWallpaper);
      _colorThemeId = prefs.getString(_keyColorTheme) ?? 'amber_classic';
      _listPreviewMode = prefs.getInt(_keyListPreviewMode) ?? 1;

      final foldersJson = prefs.getString(_keyFolders);
      if (foldersJson != null && foldersJson.isNotEmpty) {
        try {
          final list = jsonDecode(foldersJson);
          if (list is List && list.isNotEmpty) {
            _folders = list.map((e) => ChatFolderModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
          }
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 24.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, _fontSize);
  }

  Future<void> setBubbleRadius(double radius) async {
    _bubbleRadius = radius.clamp(4.0, 28.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBubbleRadius, _bubbleRadius);
  }

  Future<void> setWallpaper(String? wallpaperIdOrUrl) async {
    _wallpaper = wallpaperIdOrUrl;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_wallpaper == null) {
      await prefs.remove(_keyWallpaper);
    } else {
      await prefs.setString(_keyWallpaper, _wallpaper!);
    }
  }

  Future<void> setColorTheme(String themeId) async {
    _colorThemeId = themeId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorTheme, _colorThemeId);
  }

  Future<void> setListPreviewMode(int mode) async {
    _listPreviewMode = mode.clamp(0, 2);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyListPreviewMode, _listPreviewMode);
  }

  Future<void> saveFolders() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final list = _folders.map((f) => f.toMap()).toList();
    await prefs.setString(_keyFolders, jsonEncode(list));
  }

  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, item);
    await saveFolders();
  }

  Future<void> addFolder({required String name, required List<String> includedChatIds}) async {
    final newId = 'folder_${DateTime.now().millisecondsSinceEpoch}';
    _folders.add(ChatFolderModel(
      id: newId,
      name: name.trim().isNotEmpty ? name.trim() : 'مجلد جديد',
      includedChatIds: includedChatIds,
    ));
    await saveFolders();
  }

  Future<void> updateFolder({required String id, required String name, required List<String> includedChatIds}) async {
    final idx = _folders.indexWhere((f) => f.id == id);
    if (idx != -1) {
      _folders[idx].name = name.trim();
      _folders[idx].includedChatIds = includedChatIds;
      await saveFolders();
    }
  }

  Future<void> deleteFolder(String id) async {
    _folders.removeWhere((f) => f.id == id);
    await saveFolders();
  }
}
