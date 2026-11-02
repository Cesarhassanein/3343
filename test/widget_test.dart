import 'package:flutter_test/flutter_test.dart';
import 'package:wadiq/core/services/auth_service.dart';
import 'package:wadiq/core/services/chat_service.dart';
import 'package:wadiq/main.dart';

void main() {
  testWidgets('WadiqApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WadiqApp());
    expect(find.byType(WadiqApp), findsOneWidget);
  });

  group('profile role safeguards', () {
    test('signup accepts student role only (instructor coming soon)', () {
      expect(AuthService.normalizeSignupRole('طالب'), 'طالب');
      expect(AuthService.normalizeSignupRole('أستاذ'), 'طالب');
      expect(AuthService.normalizeSignupRole('مشرف'), 'طالب');
      expect(AuthService.normalizeSignupRole('موثق'), 'طالب');
      expect(AuthService.normalizeSignupRole('service_role'), 'طالب');
    });
  });

  group('voice message representation', () {
    test('does not treat a text placeholder as a real voice message', () {
      final message = MessageModel.fromMap({
        'id': 'message-id',
        'conversation_id': 'conversation-id',
        'sender_id': 'sender-id',
        'content': '[صوت] مقطع صوتي (0:18)',
        'is_voice': true,
        'voice_duration_seconds': 18,
        'media_url': null,
        'reactions': <dynamic>[],
        'created_at': '2026-10-25T12:00:00Z',
      }, 'current-user');

      expect(message.isVoice, isFalse);
      expect(message.voiceDuration, isNull);
    });

    test('accepts voice metadata only when an actual media URL exists', () {
      final message = MessageModel.fromMap({
        'id': 'message-id',
        'conversation_id': 'conversation-id',
        'sender_id': 'current-user',
        'content': '',
        'is_voice': true,
        'voice_duration_seconds': 78,
        'media_url': 'https://storage.example.test/voice.ogg',
        'reactions': <dynamic>[],
        'created_at': '2026-10-25T12:00:00Z',
      }, 'current-user');

      expect(message.isVoice, isTrue);
      expect(message.voiceDuration, '1:18');
    });
  });
}
