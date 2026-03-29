import 'package:fitness_tracker/data/datasources/remote/noop_social_remote_datasource.dart';
import 'package:fitness_tracker/domain/entities/follow_counts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoopSocialRemoteDataSource', () {
    late NoopSocialRemoteDataSource sut;

    setUp(() => sut = const NoopSocialRemoteDataSource());

    test('isConfigured is false', () => expect(sut.isConfigured, isFalse));

    test('follow completes silently', () async {
      await expectLater(sut.follow('any'), completes);
    });

    test('unfollow completes silently', () async {
      await expectLater(sut.unfollow('any'), completes);
    });

    test('isFollowing returns false', () async {
      expect(await sut.isFollowing('any'), isFalse);
    });

    test('getFollowers returns empty list', () async {
      expect(await sut.getFollowers('any'), isEmpty);
    });

    test('getFollowing returns empty list', () async {
      expect(await sut.getFollowing('any'), isEmpty);
    });

    test('getFollowCounts returns zero counts', () async {
      final counts = await sut.getFollowCounts('any');
      expect(counts, const FollowCounts.zero());
    });
  });
}
