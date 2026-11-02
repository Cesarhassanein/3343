# Wadiq (ودق)

Flutter social and learning platform prototype.

## Flutter setup

Provide the Supabase project URL and public anon key at run time. Never place the service-role key or AI provider key in the Flutter app.

```bash
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

## Supabase database

- For a **new test project**, apply `supabase/schema.sql` in the Supabase SQL Editor.
- For a project that already applied the earlier schema, review and apply `supabase/migrations/20261025_security_and_social.sql`.
- Do not run migrations against production without reviewing a backup and testing on staging first.
- After applying the schema/migration, run `supabase/tests/security_regression.sql` in the SQL Editor to check key security invariants.

The migration is designed not to delete application rows. It converts old placeholder messages marked as voice without a media URL back to ordinary messages.

## AI tutor Edge Function

The Flutter client invokes a Supabase Edge Function named `ai-tutor`. The function source is in `supabase/functions/ai-tutor/index.ts`. Deploy it and configure the provider secret on the server:

```bash
supabase secrets set OPENAI_API_KEY=YOUR_PROVIDER_KEY
supabase functions deploy ai-tutor
```

Optionally set `OPENAI_MODEL` as a Supabase secret to choose a supported model. Keep JWT verification enabled for the function. If the function or provider secret is missing, the app displays an explicit error rather than returning canned responses as if they came from a live model.

## Tests

```bash
flutter analyze
flutter test
```

The Flutter tests cover the current role-normalization and voice-message representation safeguards. They do not replace an end-to-end test against a real staging Supabase project. No real Supabase project was available in this workspace, so the SQL regression script has not been executed here.
