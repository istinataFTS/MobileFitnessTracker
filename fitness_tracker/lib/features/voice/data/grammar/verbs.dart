/// Grammar data for spoken action-verb recognition.
///
/// Each set contains all inflected forms and synonyms that should
/// trigger the corresponding offline intent category.
/// All entries are lowercase; callers must normalise before lookup.
abstract final class VoiceVerbGrammar {
  VoiceVerbGrammar._();

  /// Verbs that indicate a "log / create" intent.
  static const Set<String> logVerbs = {
    'log',
    'logged',
    'add',
    'added',
    'record',
    'recorded',
    'track',
    'tracked',
    'did',
    'done',
    'do',
    'save',
    'saved',
    'note',
    'noted',
    'jot',
    'jotted',
    'put',
    'mark',
    'marked',
    'enter',
    'entered',
  };

  /// Verbs that indicate an "edit / update" intent.
  static const Set<String> editVerbs = {
    'edit',
    'edited',
    'update',
    'updated',
    'change',
    'changed',
    'fix',
    'fixed',
    'correct',
    'corrected',
    'adjust',
    'adjusted',
    'modify',
    'modified',
    'replace',
    'replaced',
    'alter',
    'altered',
    'set',
    'revise',
    'revised',
  };

  /// Verbs that indicate a "delete / remove" intent.
  static const Set<String> deleteVerbs = {
    'delete',
    'deleted',
    'remove',
    'removed',
    'undo',
    'cancel',
    'cancelled',
    'scratch',
    'forget',
    'erase',
    'erased',
    'clear',
    'cleared',
    'drop',
    'dropped',
    'discard',
    'discarded',
    'take back',
  };

  /// Words that indicate a "query / question" intent.
  static const Set<String> queryWords = {
    'what',
    "what's",
    'whats',
    'how',
    'show',
    'tell',
    'get',
    'check',
    'display',
    'give',
    'list',
    'see',
    'view',
    'find',
    'report',
  };
}
