import 'night.dart';
import 'sky_geometry.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _adjectives = [
  'Quiet', 'Silver', 'Wandering', 'Hidden', 'Patient', 'Northern', 'Distant',
  'Sleeping', 'Lantern', 'Salt', 'Amber', 'Winter', 'Harbour', 'Hollow',
  'Restless', 'Old', 'Lonely', 'Gentle', 'Western', 'Folded',
];

const _nouns = [
  'Heron', 'Anchor', 'Shepherd', 'Willow', 'Compass', 'Kettle', 'Ferry',
  'Owl', 'Bell', 'Ladder', 'Spindle', 'Orchard', 'Sparrow', 'Gate', 'Oar',
  'Lantern', 'Weaver', 'Harp', 'Bridge', 'Comet',
];

/// The date-seeded "Tonight's Sky": the same night for every player on a
/// given day, fully offline. The mechanic rotates through the week.
Night dailyNight(DateTime date) {
  final base = date.year * 10000 + date.month * 100 + date.day;
  final rng = SeededRng(base * 7 + 3);
  final adj = _adjectives[rng.intRange(0, _adjectives.length - 1)];
  var noun = _nouns[rng.intRange(0, _nouns.length - 1)];
  if (noun == adj) noun = 'Crown';
  final name = 'The $adj $noun';
  final weekday = date.weekday; // 1 = Monday
  final rotation = rng.range(-150, 150).roundToDouble();

  for (var attempt = 0; attempt < 50; attempt++) {
    final seed = base * 31 + attempt;
    final g = FigureGenerator(seed);
    try {
      switch (weekday % 3) {
        case 1: // Mon, Thu, Sun: guided with decoys
          final f = g.path(7 + weekday % 3 + (weekday == 7 ? 1 : 0));
          final edges = pathEdges(f.path);
          return Night(
            id: 0,
            chapter: 1,
            name: name,
            myth: 'Charted on ${dateKey(date)}.',
            mode: TraceMode.guided,
            stars: f.stars,
            edges: edges,
            path: f.path,
            decoys: g.decoys(f.stars, edges, 4),
          );
        case 2: // Tue, Fri: chart card
          final f = g.path(7);
          final edges = pathEdges(f.path);
          return Night(
            id: 0,
            chapter: 2,
            name: name,
            myth: 'Charted on ${dateKey(date)}.',
            mode: TraceMode.chart,
            stars: f.stars,
            edges: edges,
            path: f.path,
            decoys: g.decoys(f.stars, edges, 6),
            rotationDegrees: rotation == 0 ? 45 : rotation,
          );
        default: // Wed, Sat: one stroke
          final f = g.trail(8, 3);
          return Night(
            id: 0,
            chapter: 3,
            name: name,
            myth: 'Charted on ${dateKey(date)}.',
            mode: TraceMode.oneStroke,
            stars: f.stars,
            edges: f.edges,
            decoys: g.decoys(f.stars, f.edges, 3),
            rotationDegrees: rotation,
          );
      }
    } on StateError {
      continue;
    }
  }
  throw StateError('no daily sky for ${dateKey(date)}');
}
