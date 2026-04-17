# Implementation Plan — Critical Persistence & Muscle-Map Bugs

**Status:** Draft — 2026-04-17
**Severity:** P0 (data loss + broken core visualisation)
**Target branch:** `fix/muscle-tracking-and-factors` (current) → PR into `main`

---

## 1. Observed symptoms

| # | Symptom | Screenshots |
|---|---------|-------------|
| A | After logging 2 × Arnold Press (Shoulders, 12 reps @ 15 kg), the **Fatigue** view shows `Muscles fully recovered`, `0 Muscles`, `Target –`, and the front/back human models are completely unlit. | Screenshot 2 |
| B | The **Progress / Today** (Volume) view shows `2 Sets` but `0 Muscles`, `No training load yet`, and unlit human models. | Screenshot 3 |
| C | After **logout → login**, the history entry for *Friday, Apr 17* collapses from `2 workouts / 2 sets logged` to `0 workouts / 0 sets logged`. All muscle-map data is also gone. | Screenshots 1 vs 4 |

(A) and (B) are the same bug (muscle-stimulus pipeline produces no records). (C) is an independent but equally critical defect in the local-first sync architecture.

---

## 2. Architecture recap (what exists today)

The codebase is a well-layered Flutter app with Clean-Architecture-style separation:

```
lib/
├── app/               app shell, bootstrap, cross-bloc effect listeners
├── core/              logging, errors, sync primitives, constants, session
├── data/              datasources (local sqflite / remote Supabase), repos, sync coordinators
├── domain/            entities, repositories (interfaces), use cases
├── features/          auth · home · log · library · targets · history · settings
└── injection/         GetIt DI modules
```

- **State management:** `flutter_bloc` with a `BlocEffectsMixin` for one-shot effects (`WorkoutLoggedEffect`, `NutritionLogSuccessEffect`, …).
- **Cross-bloc coordination:** [`app_domain_effects_listener.dart`](lib/app/listeners/app_domain_effects_listener.dart) listens to effects and dispatches refresh events to Home/History/MuscleVisual blocs.
- **Persistence:** local `sqflite` via `DatabaseHelper` for all entities; Supabase for a subset (exercises, meals, workout_sets, nutrition_logs, targets, user_profiles, user_auth_sessions).
- **Auth/session:** `AuthSessionServiceImpl` + `SessionSyncServiceImpl` ([lib/core/session/session_sync_service_impl.dart](lib/core/session/session_sync_service_impl.dart)).
- **Sync orchestration:** `SyncOrchestratorImpl` runs registered `SyncFeature`s per trigger (initial sign-in, manual refresh, …). Each feature wraps a `SyncCoordinator`. Coordinators extend `BaseEntitySyncCoordinator` ([lib/data/sync/base_entity_sync_coordinator.dart](lib/data/sync/base_entity_sync_coordinator.dart)).

---

## 3. Root-cause analysis

### 3.1 Bug C (data loss on logout → login) — *architectural, single root cause*

The sync system is **upload-only**. There is no code path that *pulls* records from Supabase into the local database.

Evidence:

- `BaseEntitySyncCoordinator.syncPendingChanges()` only iterates `getPendingSyncEntities()` and calls `upsertRemote()` (push). There is no `downloadAll`, `pullFromRemote`, or equivalent — a grep for those names returns zero hits in `lib/`.
  - [base_entity_sync_coordinator.dart:191-232](lib/data/sync/base_entity_sync_coordinator.dart:191)
- `SyncFeature` only exposes `syncPendingChanges` (see registrations in [injection_container.dart:122-145](lib/injection/injection_container.dart:122)).
- On sign-out, `SessionSyncServiceImpl._clearAllLocalUserData()` wipes local data for: meals, nutrition_logs, targets, workout_sets, user-owned exercises, and muscle_stimulus. This is correct for privacy/device sharing, but...
  - [session_sync_service_impl.dart:191-220](lib/core/session/session_sync_service_impl.dart:191)
- On re-sign-in, `SessionSyncServiceImpl.establishAuthenticatedSession()` calls `syncOrchestrator.run(SyncTrigger.initialSignIn)` which only pushes pending changes (there are none — local is empty). The data on Supabase is never re-downloaded.
  - [session_sync_service_impl.dart:65-97](lib/core/session/session_sync_service_impl.dart:65)

**Net effect:** workout_sets, meals, logs, and targets survive on Supabase but the UI shows them as gone, because the local mirror is empty and nothing replenishes it.

### 3.2 Bug A/B (muscle map never highlights trained muscles) — *multiple contributing causes, need to isolate*

The data flow for the muscle map is:

```
WorkoutBloc.AddWorkoutSetEvent
  → addWorkoutSet()                            [persists workout_sets row]
  → recordWorkoutSet(userId, exerciseId, …)    [writes muscle_stimulus rows]
  → emitEffect(WorkoutLoggedEffect)
AppDomainEffectsListener (already wired ✓)
  → MuscleVisualBloc ← RefreshVisualsEvent
  → GetMuscleVisualData(period, userId)
  → Home mapper → body overlays
```

The cross-bloc refresh *is* wired correctly ([app_domain_effects_listener.dart:42-46](lib/app/listeners/app_domain_effects_listener.dart:42)), so the bug is **not** stale-cache; the muscle-stimulus rows themselves are either not being written, or not being read back with the right userId.

Candidate causes (investigate in order):

1. **`CalculateMuscleStimulus` returns empty map.** `calculateForSet()` returns `Right({})` when `factors.isEmpty` ([calculate_muscle_stimulus.dart:38-40](lib/domain/usecases/muscle_stimulus/calculate_muscle_stimulus.dart:38)). If the seeded muscle_factor rows for *Arnold Press* are missing — e.g., because the exercise id used at log-time is a server id rather than the seeded local id, or because an earlier migration dropped the table without re-seeding — we silently record nothing.
2. **`userId` mismatch between write and read.** `WorkoutBloc._onAddWorkoutSet` falls back to `''` when the session lookup fails ([workout_bloc.dart:110-114](lib/features/log/application/workout_bloc.dart:110)). `MuscleVisualBloc` reads with `user?.id`. If the two ever disagree (guest → authed transition, or vice-versa), no rows are visible to the reader.
3. **Exercise muscleGroups normalisation.** `AddExercise` lowercases muscle-group strings; historical rows created before that commit may have `"Shoulders"` while `MuscleGroups.isValid()` requires `"shoulders"`. The home mapper silently drops invalid groups ([home_view_data_mapper.dart:455-484](lib/features/home/presentation/mappers/home_view_data_mapper.dart:455)).
4. **Case-sensitive factor → display mapping.** `getDisplayName()` was recently patched, but the underlying key must match `MuscleGroups` constants exactly.

> Only (1) and (2) can produce a *fully blank* map with 0 muscles; (3) and (4) can only drop *some* muscles. So triage starts with (1) and (2).

---

## 4. Cross-cutting design principles for the fix

Before we touch code, lock these in so every change respects them:

- **Local-first, eventually consistent.** Local SQLite is the source of truth for the running app. Supabase is the durable mirror. Logout should NOT be the only moment we trust the remote — every sync pass should be bi-directional.
- **Derived data is recomputable.** `muscle_stimulus` is a projection of `workout_sets` + `exercise_muscle_factors`. Treat it as a cache: rebuild whenever its sources change, and don't bother syncing it.
- **Boundaries validate, internals trust.** System boundary = auth callbacks, Supabase responses, DB reads. Validate there. Don't sprinkle null-checks in internal methods.
- **No backwards-compat shims.** We're pre-GA. If an old record shape is invalid, fix the migration, don't branch on it at read-time.
- **One refresh contract.** `*Effect → AppDomainEffectsListener → RefreshXxxEvent` is already the pattern — use it; do not introduce a second.
- **Testable seams.** Every new use case gets a pure domain interface + unit test; the integration test covers the full logout→login→data-restored path.

---

## 5. Fix plan

### Phase 0 — Instrumentation (half-day, do first)

Goal: confirm the diagnoses in §3.2 before writing the fix.

1. In `RecordWorkoutSet.call()` and `CalculateMuscleStimulus.calculateForSet()`, add `AppLogger.info` lines that dump `{exerciseId, userId, factorCount, muscleStimuli}`. These are temporary and will be removed.
   - [record_workout_set.dart:28-87](lib/domain/usecases/muscle_stimulus/record_workout_set.dart:28)
   - [calculate_muscle_stimulus.dart:16-61](lib/domain/usecases/muscle_stimulus/calculate_muscle_stimulus.dart:16)
2. Run the repro (log Arnold Press), capture logs, and answer: *"were factors found?"* and *"what userId was the row written with?"*.
3. Run `SELECT COUNT(*) FROM exercise_muscle_factors WHERE exercise_id = '<arnold-press-id>'` against the on-device DB via `adb shell run-as` to confirm factors actually exist.
4. Record findings in this document under §6.

This phase is non-negotiable: it's the difference between fixing the real bug vs shipping a guess.

### Phase 1 — Bug A/B fix: muscle-stimulus pipeline

Precise edits depend on Phase 0, but the likely set is:

#### 1a. Make `RecordWorkoutSet` surface "no factors" as a real failure, not a silent empty.

- Change `calculate_muscle_stimulus.dart:38-40` to return `Left(ValidationFailure('no muscle factors for exerciseId=$exerciseId'))` instead of `Right({})`.
- `RecordWorkoutSet` already folds on failure; confirm it logs at `warning` level so this is visible in production.
- `WorkoutBloc._onAddWorkoutSet` should surface this to the user as a non-fatal banner ("logged, but we couldn't map it to muscles — please re-seed") rather than a silent success.

#### 1b. Require a real `userId` in `AddWorkoutSetEvent`.

- Drop the `(_) => ''` fallback in [workout_bloc.dart:110-114](lib/features/log/application/workout_bloc.dart:110).
- If there is no session user, either (a) abort with a `WorkoutError`, or (b) use a well-defined `guestUserId` constant and apply the same constant on read. Pick (a) — a guest can still go through the normal auth flow.
- Apply the same rule to `MuscleVisualBloc` and any other reader: reject calls before auth is ready instead of defaulting to `''`.

#### 1c. Normalise muscle-group keys at a single boundary.

- In `MuscleFactorModel.fromMap` (the boundary where SQLite rows enter the domain), lowercase+trim the `muscle_group` column.
- In `Exercise.fromMap` / remote-to-local mappers, same treatment for `muscleGroups`.
- Do this once; remove scattered `.toLowerCase().trim()` calls in `AddExercise` etc.

#### 1d. Re-seed factors if they're missing.

- `AppDataSeeder` already re-runs seeding on migration ([app_data_seeder.dart](lib/app/bootstrap/app_data_seeder.dart)). Add a defensive check in app startup: if `SELECT COUNT(*) FROM exercise_muscle_factors = 0`, re-run `SeedExerciseFactors` even without a schema bump.
- After re-seeding, call `RebuildMuscleStimulusFromWorkoutHistory(userId)` so past workouts are reflected.

### Phase 2 — Bug C fix: bi-directional sync

This is the big one and deserves its own design review before implementation.

#### 2a. Introduce a `pullSince(DateTime? since)` coordinator method.

Add a new abstract method to `BaseEntitySyncCoordinator`:

```dart
/// Downloads remote rows modified since [since] (or all rows if null) and
/// upserts them into the local store, respecting conflict rules.
Future<void> pullRemoteChanges({DateTime? since});
```

- Each coordinator implements it by calling a new `remoteDataSource.fetchSince(userId, since)` method returning `List<T>`.
- Conflict rule: remote wins when local has no pending-modification flag; local wins (stays pending) otherwise. This keeps offline edits safe.
- Server must be queried with `ownerUserId = currentUser.id` (RLS already enforces this, but belt-and-braces).

#### 2b. Add `pullRemoteChanges` to each coordinator

Order of implementation matches FK order already encoded in `_registerAppComposition` (exercises → meals → workout_sets → nutrition_logs → targets).

Each Supabase remote datasource gains a `fetchSince` method:

```dart
Future<List<WorkoutSetModel>> fetchSince({
  required String userId,
  DateTime? updatedSince,
});
```

Use `updated_at > since` in the query. Cursor storage (for incremental sync) goes in a new `sync_cursors` table keyed on `(userId, entityType)`.

#### 2c. Extend `SyncFeature` and `SyncOrchestrator`

```dart
class SyncFeature {
  final String name;
  final Future<void> Function() syncPendingChanges;  // existing (push)
  final Future<void> Function() pullRemoteChanges;   // new (pull)
}
```

`SyncOrchestratorImpl.run(trigger)` runs features in FK order. For each feature, it **pulls first**, then pushes. This ensures:
- Fresh login: pull hydrates local from empty → then push no-ops.
- Active user offline edits: pull refreshes → push uploads the offline work.

#### 2d. Rebuild muscle-stimulus at the end of initial sign-in sync

In `SessionSyncServiceImpl.establishAuthenticatedSession`, after `syncOrchestrator.run` completes successfully, call:

```dart
await rebuildMuscleStimulusFromWorkoutHistory(user.id);
```

This is the keystone: it turns freshly-downloaded `workout_sets` back into the `muscle_stimulus` projection that powers the body map. No need to sync `muscle_stimulus` itself.

Inject `RebuildMuscleStimulusFromWorkoutHistory` into `SessionSyncServiceImpl` via its constructor (extend the DI wiring in [injection_container.dart:157-169](lib/injection/injection_container.dart:157)).

#### 2e. Clarify the initial-cloud-migration semantics

`prepareForInitialCloudMigration` is currently invoked only on the *first* sign-in per install, to upload guest-mode data. That behaviour should stay. But document clearly in the coordinator headers and in [docs/architecture/](docs/architecture/) that:

- **Initial migration** = guest→authed one-time upload.
- **Pull** = every authed sync, both initial and subsequent.
- **Push** = every authed sync, bidirectional with pull.

### Phase 3 — Hardening & cleanup

#### 3a. Consolidate muscle-group constants

Single source of truth for the slug set (`shoulders`, `front-delts`, `side-delts`, …) in [muscle_stimulus_constants.dart](lib/core/constants/muscle_stimulus_constants.dart). Every mapper imports from there — no string literals in `HomeViewDataMapper` or `MuscleBodyAssets`.

#### 3b. Replace `MuscleVisualBloc`'s 5-minute cache with event-driven invalidation

The cache is only useful *between refresh signals*. Since we already fire `RefreshVisualsEvent` from every mutating effect, shorten the cache TTL to something nominal (e.g. 30 s) or remove it entirely. The added DB hit per screen mount is negligible and eliminates an entire class of staleness bugs.

- [muscle_visual_bloc.dart:140-147](lib/features/home/application/muscle_visual_bloc.dart:140)

#### 3c. Add a guardrail test for the full lifecycle

Integration test in `test/integration/` that:

1. Boots with a fake Supabase client,
2. Logs a workout,
3. Asserts muscle-stimulus rows exist and the map has ≥1 trained muscle,
4. Signs out (asserts local is cleared),
5. Signs in (asserts pull ran, stimulus rebuilt),
6. Re-asserts map state matches step 3.

This is the test that would have caught both bugs.

#### 3d. Opportunistic issues caught during exploration (decide per-issue: fix now vs backlog)

| Issue | File | Severity | Recommendation |
|---|---|---|---|
| `userId` defaults to `''` in several blocs | `workout_bloc.dart`, `muscle_visual_bloc.dart`, others | Med | Fold into 1b |
| `_clearAllLocalUserData` swallows exceptions with a warning | [session_sync_service_impl.dart:214-218](lib/core/session/session_sync_service_impl.dart:214) | Low | Keep behaviour but surface a `Failure` in the return so the UI can show "partial sign-out" |
| `calculate_muscle_stimulus.dart` returns `Right({})` on missing factors | see 1a | High | Fix in 1a |
| `MuscleVisualBloc` cache has no invalidation on period change | `muscle_visual_bloc.dart` | Low | Cache key should include `(period, userId)`; inspect when tackling 3b |
| No `muscle_stimulus` rebuild on app resume when device clock crosses midnight | `apply_daily_decay.dart` / bootstrap | Low | Separate ticket |
| Home mapper drops invalid muscle groups silently | [home_view_data_mapper.dart:457-461](lib/features/home/presentation/mappers/home_view_data_mapper.dart:457) | Low | Log at debug; data fix lives in 1c |

---

## 6. Investigation log (fill in during Phase 0)

- [ ] Factor count for seeded "Arnold Press" in on-device DB: _____
- [ ] `userId` passed to `recordWorkoutSet` at log time: _____
- [ ] `userId` used by `GetMuscleVisualData` on the same session: _____
- [ ] Muscle-group strings actually stored on the factor rows: _____
- [ ] Does Supabase still have the workout_sets rows after logout? (run `SELECT * FROM workout_sets WHERE owner_user_id = '<uid>'` in Supabase SQL editor): _____

---

## 7. Rollout & verification

1. Phase 0 → commit instrumentation, merge, capture logs, **revert instrumentation** before the real fix lands.
2. Phase 1 → PR with unit tests for each changed use case.
3. Phase 2 → PR with:
   - `pullRemoteChanges` abstract + 5 implementations
   - `sync_cursors` migration
   - `SessionSyncServiceImpl` change
   - Integration test from 3c
   - Manual QA: the exact repro from §1 passes on a physical device.
4. Phase 3 → follow-up PR(s); not blocking for the user-facing fix.

### Acceptance criteria

- ✅ Logging Arnold Press lights up Shoulders (front-delts, side-delts, triceps, upper-traps) in both Fatigue and Volume views within one refresh cycle.
- ✅ `History → Friday, Apr 17` still shows `2 workouts / 2 sets logged` after logout → login.
- ✅ Muscle map on the new session reflects the same muscles as before logout.
- ✅ Offline → go online still uploads pending workouts without duplicating them.
- ✅ `flutter test` passes; new integration test passes; no new lints.

---

## 8. Out of scope (explicit non-goals for this plan)

- Real-time (`.stream`) Supabase subscriptions.
- Syncing `muscle_stimulus` remotely — it's derived, not durable.
- Multi-device conflict UX beyond "last write wins on clean local / keep local on dirty local".
- Schema changes to Supabase beyond adding `sync_cursors`.
