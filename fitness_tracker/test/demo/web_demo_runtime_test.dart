import 'package:fitness_tracker/core/constants/muscle_stimulus_constants.dart'
    as stimulus_constants;
import 'package:fitness_tracker/demo/web_demo_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded web demo stimulus matches seeded workout history for today', () {
    final store = WebDemoStore.seeded();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final todayQuads = store.muscleStimulusRecords.where(
      (record) =>
          record.muscleGroup == stimulus_constants.MuscleStimulus.quads &&
          record.date == todayStart,
    );

    final todayChest = store.muscleStimulusRecords.where(
      (record) =>
          record.muscleGroup == stimulus_constants.MuscleStimulus.midChest &&
          record.date == todayStart,
    );

    expect(todayQuads, isNotEmpty);
    expect(todayQuads.single.dailyStimulus, 0);
    expect(todayChest, isNotEmpty);
    expect(todayChest.single.dailyStimulus, greaterThan(0));
  });
}
