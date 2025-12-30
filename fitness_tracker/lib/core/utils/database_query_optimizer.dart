import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Database query optimization utilities
class DatabaseQueryOptimizer {
  DatabaseQueryOptimizer._();

  /// Analyze query performance and return execution time
  /// 
  /// Usage:
  /// ```dart
  /// final duration = await DatabaseQueryOptimizer.analyzeQuery(
  ///   db,
  ///   'SELECT * FROM workout_sets WHERE date > ?',
  ///   ['2024-01-01'],
  /// );
  /// ```
  static Future<Duration> analyzeQuery(
    Database db,
    String sql,
    List<Object?>? arguments,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await db.rawQuery(sql, arguments);
    } finally {
      stopwatch.stop();
    }
    
    return stopwatch.elapsed;
  }

  /// Explain query plan to identify optimization opportunities
  /// 
  /// Returns the query plan showing how SQLite will execute the query
  static Future<List<Map<String, Object?>>> explainQuery(
    Database db,
    String sql,
    List<Object?>? arguments,
  ) async {
    // Build EXPLAIN QUERY PLAN statement
    final explainSql = 'EXPLAIN QUERY PLAN $sql';
    
    try {
      final results = await db.rawQuery(explainSql, arguments);
      
      if (kDebugMode) {
        debugPrint('📊 Query Plan for: $sql');
        for (final row in results) {
          debugPrint('  ${row['detail']}');
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('❌ Failed to explain query: $e');
      return [];
    }
  }

  /// Check if a specific index exists
  static Future<bool> indexExists(Database db, String indexName) async {
    final results = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      [indexName],
    );
    
    return results.isNotEmpty;
  }

  /// List all indexes for a table
  static Future<List<String>> getIndexesForTable(
    Database db,
    String tableName,
  ) async {
    final results = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=? AND name NOT LIKE 'sqlite_%'",
      [tableName],
    );
    
    return results.map((r) => r['name'] as String).toList();
  }

  /// Verify query uses an index (not doing a full table scan)
  /// 
  /// Returns true if query uses an index, false if it's a table scan
  static Future<bool> queryUsesIndex(
    Database db,
    String sql,
    List<Object?>? arguments,
  ) async {
    final plan = await explainQuery(db, sql, arguments);
    
    // Check if any step in the plan uses an index
    for (final row in plan) {
      final detail = (row['detail'] as String? ?? '').toLowerCase();
      if (detail.contains('using index') || 
          detail.contains('search using')) {
        return true;
      }
    }
    
    return false;
  }

  /// Run ANALYZE to update query planner statistics
  /// 
  /// Should be run periodically (e.g., weekly) or after bulk inserts
  static Future<void> analyzeDatabase(Database db) async {
    try {
      await db.execute('ANALYZE');
      if (kDebugMode) {
        debugPrint('✅ Database statistics updated (ANALYZE complete)');
      }
    } catch (e) {
      debugPrint('❌ Failed to analyze database: $e');
    }
  }

  /// Vacuum database to reclaim space and optimize performance
  /// 
  /// WARNING: This can take time on large databases
  /// Only run during low-usage periods
  static Future<void> vacuumDatabase(Database db) async {
    try {
      final stopwatch = Stopwatch()..start();
      await db.execute('VACUUM');
      stopwatch.stop();
      
      if (kDebugMode) {
        debugPrint('✅ Database vacuumed in ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      debugPrint('❌ Failed to vacuum database: $e');
    }
  }

  /// Get database size information
  static Future<Map<String, dynamic>> getDatabaseStats(Database db) async {
    try {
      // Get page count and page size
      final pageCount = Sqflite.firstIntValue(
        await db.rawQuery('PRAGMA page_count'),
      ) ?? 0;
      
      final pageSize = Sqflite.firstIntValue(
        await db.rawQuery('PRAGMA page_size'),
      ) ?? 0;
      
      final sizeBytes = pageCount * pageSize;
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
      
      // Get table counts
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      
      return {
        'size_bytes': sizeBytes,
        'size_mb': sizeMB,
        'page_count': pageCount,
        'page_size': pageSize,
        'table_count': tables.length,
      };
    } catch (e) {
      debugPrint('❌ Failed to get database stats: $e');
      return {};
    }
  }

  /// Batch insert optimization helper
  /// 
  /// Uses a single transaction for multiple inserts
  /// Much faster than individual inserts
  static Future<void> batchInsert(
    Database db,
    String table,
    List<Map<String, Object?>> rows, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (rows.isEmpty) return;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final row in rows) {
        batch.insert(
          table,
          row,
          conflictAlgorithm: conflictAlgorithm,
        );
      }
      
      await batch.commit(noResult: true);
    });
  }

  /// Batch update optimization helper
  static Future<void> batchUpdate(
    Database db,
    String table,
    List<Map<String, Object?>> rows,
    String whereColumn,
  ) async {
    if (rows.isEmpty) return;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final row in rows) {
        final id = row[whereColumn];
        if (id == null) continue;
        
        batch.update(
          table,
          row,
          where: '$whereColumn = ?',
          whereArgs: [id],
        );
      }
      
      await batch.commit(noResult: true);
    });
  }

  /// Profile a query and log if it's slow
  /// 
  /// Threshold in milliseconds (default: 100ms)
  static Future<T> profileQuery<T>(
    String queryName,
    Future<T> Function() queryFn, {
    int slowThresholdMs = 100,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      return await queryFn();
    } finally {
      stopwatch.stop();
      
      if (stopwatch.elapsedMilliseconds > slowThresholdMs) {
        debugPrint(
          '⚠️ Slow query detected: $queryName took ${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
  }
}