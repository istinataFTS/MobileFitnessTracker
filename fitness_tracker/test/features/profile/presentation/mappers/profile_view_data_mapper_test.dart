import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/features/profile/application/profile_cubit.dart';
import 'package:fitness_tracker/features/profile/presentation/mappers/profile_view_data_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps guest profile state into stable view data', () {
    const ProfileState state = ProfileState(
      session: AppSession.guest(),
      isLoading: false,
      hasLoaded: true,
      errorMessage: null,
    );

    final viewData = ProfileViewDataMapper.map(state);

    expect(viewData.title, 'Guest');
    expect(viewData.subtitle, 'Sign in to unlock cloud sync and social features');
    expect(viewData.accountModeTitle, 'Guest account');
    expect(viewData.cloudMigrationSubtitle, 'No initial migration pending');
    expect(viewData.lastSyncSubtitle, 'No successful cloud sync recorded yet');
    expect(viewData.deferredItems, hasLength(1));
    expect(viewData.infoTiles, hasLength(1));
    expect(viewData.isLoading, isFalse);
  });

  test('maps authenticated profile state into stable view data', () {
    final ProfileState state = ProfileState(
      session: AppSession(
        authMode: AuthMode.authenticated,
        user: const AppUser(
          id: 'user-1',
          email: 'marin@test.com',
          displayName: 'Marin Dinchev',
        ),
        requiresInitialCloudMigration: true,
        lastCloudSyncAt: DateTime(2026, 3, 18, 14, 45),
      ),
      isLoading: false,
      hasLoaded: true,
      errorMessage: null,
    );

    final viewData = ProfileViewDataMapper.map(state);

    expect(viewData.title, 'Marin Dinchev');
    expect(viewData.subtitle, 'marin@test.com');
    expect(viewData.accountModeTitle, 'Cloud account');
    expect(
      viewData.accountModeSubtitle,
      'Data is owned and synced with your authenticated account',
    );
    expect(
      viewData.cloudMigrationSubtitle,
      'Waiting to upload local data to the cloud',
    );
    expect(viewData.lastSyncSubtitle, '2026-03-18 14:45');
  });

  test('keeps loading visible only before first successful load', () {
    const ProfileState state = ProfileState(
      session: AppSession.guest(),
      isLoading: true,
      hasLoaded: false,
      errorMessage: null,
    );

    final viewData = ProfileViewDataMapper.map(state);

    expect(viewData.isLoading, isTrue);
  });
}