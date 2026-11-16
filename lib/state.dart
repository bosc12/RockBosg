import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/achievements.dart';
import 'data/db.dart';
import 'data/specimen.dart';

enum AppMode { explorer, geologist }

/// Estado global de la app: preferencias + colección.
class AppState extends ChangeNotifier {
  AppState._(this.db, this._prefs);

  final LocalDb db;
  final SharedPreferences _prefs;
  List<Specimen> specimens = [];
  late Stats stats = Stats(const []);

  static Future<AppState> load() async {
    final s =
        AppState._(await LocalDb.open(), await SharedPreferences.getInstance());
    await s.reload();
    return s;
  }

  // ── Preferencias ──
  String? get userName => _prefs.getString('userName');
  AppMode? get mode => switch (_prefs.getString('mode')) {
        'explorer' => AppMode.explorer,
        'geologist' => AppMode.geologist,
        _ => null,
      };
  bool get isGeologist => mode == AppMode.geologist;

  ThemeMode get themeMode => switch (_prefs.getString('theme')) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.light, // por defecto claro: se lee mejor al sol
      };

  bool get largeText => _prefs.getBool('largeText') ?? isGeologist;

  Future<void> setProfile(String name, AppMode m) async {
    await _prefs.setString('userName', name.trim());
    await _prefs.setString('mode', m.name);
    notifyListeners();
  }

  Future<void> setMode(AppMode m) async {
    await _prefs.setString('mode', m.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode t) async {
    await _prefs.setString('theme', t == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLargeText(bool v) async {
    await _prefs.setBool('largeText', v);
    notifyListeners();
  }

  // ── Colección ──
  Future<void> reload() async {
    specimens = await db.all();
    stats = Stats(specimens);
    notifyListeners();
  }

  Future<void> save(Specimen s) async {
    await db.upsert(s);
    await reload();
  }

  Future<void> remove(Specimen s) async {
    await db.delete(s);
    await reload();
  }

  List<Specimen> specimensOf(String mineralId) =>
      specimens.where((s) => s.mineralId == mineralId).toList();
}

/// Acceso al estado desde cualquier widget.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
