# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All Flutter commands run from the `fitness_tracker/` directory. All Deno/backend commands run from `fitness_tracker/supabase/functions/`.

### Flutter (app)

```sh
flutter pub get                         # install dependencies
flutter run                             # run on connected device/emulator
flutter test                            # run all tests
flutter test test/path/to/file_test.dart  # run a single test file
dart format lib test                    # format code
flutter analyze                         # static analysis
```

### Backend (Supabase Edge Functions)

```sh
deno test --allow-all                   # run all backend tests (from supabase/functions/)
deno test --allow-all voice-chat/       # run tests for a single function
deno fmt                                # format Deno code
deno lint                               # lint Deno code
```

### Local Supabase stack

```sh
supabase start                          # start local Postgres + Edge Function runtime
supabase functions serve --env-file .env.local   # serve all edge functions locally
supabase db push                        # apply pending migrations
```

See `supabase/.env.local` (gitignored) for required local env vars — `OPENAI_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.

### Deploy (CI)

Supabase deploy is manual — trigger the `Supabase Deploy` GitHub Action (`workflow_dispatch`) with target `functions`, `migrations`, or `both`. Do not push to production without applying migrations first.

### Flutter compile-time config (`--dart-define`)

All config is injected at build time via `--dart-define`. `EnvConfig` (`lib/config/env_config.dart`) is the single source of truth. Supabase is **off by default** (`ENABLE_SUPABASE=false`). To run with a real backend:

```sh
flutter run \
  --dart-define=ENABLE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Architecture

### Flutter app — Clean Architecture

The app follows a strict three-layer architecture. Presentation never imports data-layer types directly.

```
domain/       — entities, repository interfaces, use cases (pure Dart, no Flutter)
data/         — repository implementations, local datasources (sqflite), remote datasources (Supabase), sync coordinators
features/     — one directory per feature; each contains application/ (BLoC/Cubit), presentation/ (pages, widgets), and a barrel export
core/         — shared utilities, error handling, sync orchestration, auth, logging
injection/    — get_it wiring, split into modules per feature (register_*_module.dart)
```

### State management

All features use `flutter_bloc`. BLoCs and Cubits are registered as **factories** (new instance per page) in `injection/`. Repository and use-case singletons are `registerLazySingleton`.

One-shot side effects (navigation, snackbars) are emitted via `BlocEffectsMixin` — a broadcast `StreamController<Effect>` mixed into a BLoC. Listen in the widget with `bloc.effects.listen(...)`.

### Error handling

All repository methods return `Either<Failure, T>` (via `dartz`). Use `RepositoryGuard.run(() => ...)` to wrap datasource calls — it catches all exceptions and maps them to `Failure` subtypes via `RepositoryErrorMapper`.

### Data / sync architecture

- **Guest mode**: local SQLite only (`sqflite`). No remote calls.
- **Authenticated mode**: offline-first. Local writes are immediately committed; sync runs in the background.
- **Source of truth**: Supabase for authenticated users (`ConflictResolutionStrategy.serverWins`).
- **SyncOrchestrator** (`core/sync/`) runs on `appLaunch`, `appResume`, `connectivityRestored`, `manualRefresh`, `writeThrough`, and `initialSignIn`.
- **Initial sign-in**: guest data is migrated to the authenticated user before any pull (prepare → push → pull, ordered by FK dependency: exercises → meals → workout_sets → nutrition_logs).
- **Post-sync hooks**: after every sync, `MuscleFactorHealHook` runs first (ensures exercise factors are present), then `MuscleStimulusRebuildHook` rebuilds derived stimulus data.

### Local database

SQLite via `sqflite`. Current schema version: **19**. Migration history is documented inline in `EnvConfig.databaseVersion`. Version upgrades are additive; version 15+ rejects incompatible legacy databases rather than destroying data.

### Voice bot

The voice feature (C-1 backend complete) is split across:

- **Flutter side** (`features/voice/`, `data/datasources/remote/supabase_voice_remote_datasource.dart`): `VoiceBloc` orchestrates STT → chat → TTS in sequence. History is capped at the last 3 turns before sending to the API. Guest users cannot use voice.
- **Backend** (`supabase/functions/`): three Deno Edge Functions (`voice-stt`, `voice-chat`, `voice-tts`) backed by OpenAI (Whisper, GPT-4o-mini, TTS-1). Shared modules live in `_shared/`. All calls are logged to `voice_usage_log` for cost monitoring, including failures (`status=<error_code>`, `cost_usd=0`).
- `OPENAI_API_KEY` lives exclusively as a Supabase function secret — it is never present in Flutter client code.
- If Supabase is not configured, the voice module falls back to `NoopVoiceRemoteDataSource` (all calls return `ServerFailure`).

### Feature list

`home`, `log` (workout + nutrition), `history`, `library` (exercises + meals), `profile`, `settings`, `auth` (sign-in, sign-up, OTP), `voice`.

### CI

Two GitHub Actions jobs on push/PR to `main`, `develop`, `feature/**`, `fix/**`, `refactor/**`:
- **Flutter**: format check → `flutter analyze` → `flutter test`
- **Backend**: `deno fmt --check` → `deno lint` → `deno test --allow-all`
