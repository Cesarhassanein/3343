import 'package:flutter/foundation.dart';

import 'supabase_config.dart';

class ModerationService {
  ModerationService._();
  static final ModerationService instance = ModerationService._();

  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String assignedTeam,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('خدمة البلاغات غير مُعدّة؛ لم يتم إرسال البلاغ.');
    }
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول لإرسال بلاغ.');
    }

    const allowedTypes = {'post', 'reel', 'message', 'user', 'conversation', 'channel'};
    if (!allowedTypes.contains(targetType)) {
      throw ArgumentError('نوع المحتوى المُبلّغ عنه غير صالح.');
    }
    final uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    if (!uuidPattern.hasMatch(targetId.trim())) {
      throw ArgumentError('معرّف المحتوى غير صالح؛ لم يتم إرسال البلاغ.');
    }

    try {
      await client.from('moderation_reports').insert({
        'reported_by': user.id,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'team_assigned': assignedTeam,
      });
    } catch (error) {
      debugPrint('Error submitting moderation report: $error');
      rethrow;
    }
  }
}
