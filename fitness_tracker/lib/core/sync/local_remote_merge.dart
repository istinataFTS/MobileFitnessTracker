import '../enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';

typedef EntityIdGetter<T> = String Function(T entity);
typedef EntityUpdatedAtGetter<T> = DateTime Function(T entity);
typedef EntitySyncMetadataGetter<T> = EntitySyncMetadata Function(T entity);

class LocalRemoteMerge<T> {
  final EntityIdGetter<T> getId;
  final EntityUpdatedAtGetter<T> getUpdatedAt;
  final EntitySyncMetadataGetter<T> getSyncMetadata;

  const LocalRemoteMerge({
    required this.getId,
    required this.getUpdatedAt,
    required this.getSyncMetadata,
  });

  List<T> mergeLists({
    required List<T> localItems,
    required List<T> remoteItems,
  }) {
    final Map<String, T> localById = {
      for (final item in localItems) getId(item): item,
    };

    final Map<String, T> remoteById = {
      for (final item in remoteItems) getId(item): item,
    };

    final Set<String> allIds = <String>{
      ...localById.keys,
      ...remoteById.keys,
    };

    final List<T> merged = <T>[];

    for (final id in allIds) {
      final T? local = localById[id];
      final T? remote = remoteById[id];

      if (local == null && remote != null) {
        merged.add(remote);
        continue;
      }

      if (local != null && remote == null) {
        final localSync = getSyncMetadata(local);

        if (localSync.status == SyncStatus.pendingDelete) {
          continue;
        }

        merged.add(local);
        continue;
      }

      if (local != null && remote != null) {
        merged.add(
          chooseWinner(
            local: local,
            remote: remote,
          ),
        );
      }
    }

    return merged;
  }

  T chooseWinner({
    required T local,
    required T remote,
  }) {
    final localSync = getSyncMetadata(local);

    if (localSync.status == SyncStatus.pendingDelete) {
      return local;
    }

    if (localSync.status == SyncStatus.pendingUpload ||
        localSync.status == SyncStatus.pendingUpdate) {
      return local;
    }

    final localUpdatedAt = getUpdatedAt(local);
    final remoteUpdatedAt = getUpdatedAt(remote);

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      return remote;
    }

    return local;
  }
}