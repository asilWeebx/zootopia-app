import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../services/feeding.dart';
import '../services/storage.dart';

/// Tashrif buyuruvchi kalkulyatorga hayvoni haqida oxirgi aytgani — keyingi
/// safarga saqlanadi.
class FeedingProfile extends FeedingInput {
  /// Hayvonning ismi ("Mosh"), natijani unga atash uchun.
  final String petName;
  /// Tashrif buyuruvchi biror narsa kiritganmi (sukut emas).
  final bool touched;

  const FeedingProfile({
    super.species = Species.cat,
    super.weightKg = 4,
    super.stage = Stage.adult,
    super.neutered = true,
    super.activity = Activity.normal,
    super.pouchesPerDay = 0,
    super.days = 30,
    this.petName = '',
    this.touched = false,
  });

  Map<String, dynamic> toJson() => {
        'species': species.name,
        'weightKg': weightKg,
        'stage': stage.name,
        'neutered': neutered,
        'activity': activity.name,
        'pouchesPerDay': pouchesPerDay,
        'days': days,
        'petName': petName,
        'touched': touched,
      };

  /// Saqlangan qiymat eski versiyadan bo'lishi mumkin — har maydon tekshiriladi.
  static FeedingProfile sanitize(Object? saved) {
    if (saved is! Map) return const FeedingProfile();
    final species = saved['species'] == 'dog' ? Species.dog : Species.cat;
    final limits = kWeightLimits[species]!;
    final weight = saved['weightKg'] is num ? (saved['weightKg'] as num).toDouble() : double.nan;
    final days = saved['days'] is num ? (saved['days'] as num).toInt() : 30;
    final pouches = saved['pouchesPerDay'] is num ? (saved['pouchesPerDay'] as num).round() : 0;
    final name = saved['petName'] is String ? saved['petName'] as String : '';
    return FeedingProfile(
      species: species,
      weightKg: weight >= limits.min && weight <= limits.max ? weight : (species == Species.dog ? 10 : 4),
      stage: Stage.values.where((s) => s.name == saved['stage']).firstOrNull ?? Stage.adult,
      neutered: saved['neutered'] != false,
      activity: Activity.values.where((a) => a.name == saved['activity']).firstOrNull ?? Activity.normal,
      pouchesPerDay: pouches.clamp(0, 6),
      days: const [7, 14, 30].contains(days) ? days : 30,
      petName: name.length > 30 ? name.substring(0, 30) : name,
      touched: saved['touched'] == true,
    );
  }
}

/// Bosh sahifadagi qisqa kalkulyator va kalkulyator sahifasi bitta profilni
/// o'qiydi — biri ikkinchisidan davom etadi.
class FeedingController extends ChangeNotifier {
  FeedingController({this.persist = true});
  final bool persist;

  FeedingProfile _profile = const FeedingProfile();
  bool _ready = false;

  FeedingProfile get profile => _profile;
  bool get ready => _ready;

  Future<void> load() async {
    if (persist) _profile = FeedingProfile.sanitize(await Storage.loadFeeding());
    _ready = true;
    notifyListeners();
  }

  void update({
    Species? species,
    double? weightKg,
    Stage? stage,
    bool? neutered,
    Activity? activity,
    int? pouchesPerDay,
    int? days,
    String? petName,
  }) {
    final json = _profile.toJson()
      ..addAll({
        'species': ?species?.name,
        'weightKg': ?weightKg,
        'stage': ?stage?.name,
        'neutered': ?neutered,
        'activity': ?activity?.name,
        'pouchesPerDay': ?pouchesPerDay,
        'days': ?days,
        'petName': ?petName,
        'touched': true,
      });
    _profile = FeedingProfile.sanitize(json);
    notifyListeners();
    if (persist) Storage.saveFeeding(_profile.toJson());
  }
}
