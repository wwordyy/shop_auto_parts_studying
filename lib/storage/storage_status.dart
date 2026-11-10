import 'package:shared_preferences/shared_preferences.dart';

class StorageStatus {
  static const noticeKey = 'storage_notice_v1';

  StorageStatus(this._prefs);

  final SharedPreferences _prefs;
  bool resetHappened = false;

  void markReset(String key) {
    resetHappened = true;
    final previous = _prefs.getString(noticeKey) ?? '';
    final line = 'Ключ $key: данные старого формата сброшены к начальному набору.';
    _prefs.setString(noticeKey, previous.isEmpty ? line : '$previous\n$line');
  }

  String? takeNotice() {
    final notice = _prefs.getString(noticeKey);
    if (notice == null || notice.isEmpty) return null;
    _prefs.remove(noticeKey);
    return notice;
  }
}
