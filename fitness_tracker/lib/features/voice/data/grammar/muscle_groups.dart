import '../../../../core/constants/muscle_stimulus_constants.dart';

/// Grammar data for spoken muscle-group name resolution.
///
/// Maps every common spoken alias (singular, plural, slang) to its
/// canonical kebab-case [MuscleStimulus] string.
/// All keys are lowercase; callers must normalise before lookup.
abstract final class VoiceMuscleGroupGrammar {
  VoiceMuscleGroupGrammar._();

  static const Map<String, String> _spokenToCanonical = {
    // ── Chest ─────────────────────────────────────────────
    'chest': MuscleStimulus.midChest,
    'pec': MuscleStimulus.midChest,
    'pecs': MuscleStimulus.midChest,
    'upper chest': MuscleStimulus.upperChest,
    'upper pec': MuscleStimulus.upperChest,
    'upper pecs': MuscleStimulus.upperChest,
    'lower chest': MuscleStimulus.lowerChest,
    'lower pec': MuscleStimulus.lowerChest,
    'lower pecs': MuscleStimulus.lowerChest,

    // ── Back / lats ────────────────────────────────────────
    'back': MuscleStimulus.lats,
    'lat': MuscleStimulus.lats,
    'lats': MuscleStimulus.lats,
    'latissimus': MuscleStimulus.lats,

    // ── Shoulders / delts ──────────────────────────────────
    'shoulder': MuscleStimulus.sideDelts,
    'shoulders': MuscleStimulus.sideDelts,
    'delt': MuscleStimulus.sideDelts,
    'delts': MuscleStimulus.sideDelts,
    'deltoid': MuscleStimulus.sideDelts,
    'deltoids': MuscleStimulus.sideDelts,
    'side delt': MuscleStimulus.sideDelts,
    'side delts': MuscleStimulus.sideDelts,
    'lateral delt': MuscleStimulus.sideDelts,
    'lateral delts': MuscleStimulus.sideDelts,
    'front delt': MuscleStimulus.frontDelts,
    'front delts': MuscleStimulus.frontDelts,
    'anterior delt': MuscleStimulus.frontDelts,
    'anterior delts': MuscleStimulus.frontDelts,
    'rear delt': MuscleStimulus.rearDelts,
    'rear delts': MuscleStimulus.rearDelts,
    'posterior delt': MuscleStimulus.rearDelts,
    'posterior delts': MuscleStimulus.rearDelts,

    // ── Traps ──────────────────────────────────────────────
    'trap': MuscleStimulus.upperTraps,
    'traps': MuscleStimulus.upperTraps,
    'trapezius': MuscleStimulus.upperTraps,
    'upper trap': MuscleStimulus.upperTraps,
    'upper traps': MuscleStimulus.upperTraps,
    'middle trap': MuscleStimulus.middleTraps,
    'middle traps': MuscleStimulus.middleTraps,
    'lower trap': MuscleStimulus.lowerTraps,
    'lower traps': MuscleStimulus.lowerTraps,

    // ── Arms: biceps ───────────────────────────────────────
    'bicep': MuscleStimulus.biceps,
    'biceps': MuscleStimulus.biceps,
    'arms': MuscleStimulus.biceps,
    'arm': MuscleStimulus.biceps,
    'guns': MuscleStimulus.biceps,

    // ── Arms: triceps ──────────────────────────────────────
    'tricep': MuscleStimulus.triceps,
    'triceps': MuscleStimulus.triceps,
    'tris': MuscleStimulus.triceps,
    'tri': MuscleStimulus.triceps,

    // ── Arms: forearms ─────────────────────────────────────
    'forearm': MuscleStimulus.forearms,
    'forearms': MuscleStimulus.forearms,
    'wrist': MuscleStimulus.forearms,
    'wrists': MuscleStimulus.forearms,

    // ── Core: abs ──────────────────────────────────────────
    'ab': MuscleStimulus.abs,
    'abs': MuscleStimulus.abs,
    'core': MuscleStimulus.abs,
    'abdominal': MuscleStimulus.abs,
    'abdominals': MuscleStimulus.abs,
    'stomach': MuscleStimulus.abs,
    'belly': MuscleStimulus.abs,

    // ── Core: obliques ─────────────────────────────────────
    'oblique': MuscleStimulus.obliques,
    'obliques': MuscleStimulus.obliques,
    'side': MuscleStimulus.obliques,
    'sides': MuscleStimulus.obliques,

    // ── Lower back ─────────────────────────────────────────
    'lower back': MuscleStimulus.lowerBack,
    'lumbar': MuscleStimulus.lowerBack,
    'erectors': MuscleStimulus.lowerBack,
    'erector': MuscleStimulus.lowerBack,

    // ── Legs: glutes ───────────────────────────────────────
    'glute': MuscleStimulus.glutes,
    'glutes': MuscleStimulus.glutes,
    'butt': MuscleStimulus.glutes,
    'bum': MuscleStimulus.glutes,
    'booty': MuscleStimulus.glutes,

    // ── Legs: quads ────────────────────────────────────────
    'quad': MuscleStimulus.quads,
    'quads': MuscleStimulus.quads,
    'quadricep': MuscleStimulus.quads,
    'quadriceps': MuscleStimulus.quads,
    'thigh': MuscleStimulus.quads,
    'thighs': MuscleStimulus.quads,
    'leg': MuscleStimulus.quads,
    'legs': MuscleStimulus.quads,

    // ── Legs: hamstrings ───────────────────────────────────
    'hamstring': MuscleStimulus.hamstrings,
    'hamstrings': MuscleStimulus.hamstrings,
    'hams': MuscleStimulus.hamstrings,
    'ham': MuscleStimulus.hamstrings,

    // ── Legs: calves ───────────────────────────────────────
    'calf': MuscleStimulus.calves,
    'calves': MuscleStimulus.calves,
    'gastrocnemius': MuscleStimulus.calves,

    // ── Hip adductors ──────────────────────────────────────
    'adductor': MuscleStimulus.hipadductors,
    'adductors': MuscleStimulus.hipadductors,
    'inner thigh': MuscleStimulus.hipadductors,
    'inner thighs': MuscleStimulus.hipadductors,
    'groin': MuscleStimulus.hipadductors,
  };

  /// Returns the canonical [MuscleStimulus] string for a spoken alias,
  /// or null if the alias is not recognised.
  static String? resolve(String spoken) =>
      _spokenToCanonical[spoken.trim().toLowerCase()];
}
