import '../core/night.dart';
import '../core/sky_geometry.dart';

/// The four chapters of the campaign.
class Chapter {
  const Chapter(this.index, this.name, this.numeral, this.lesson);

  final int index;
  final String name;
  final String numeral;

  /// One line shown in the Observation Log about what this chapter teaches.
  final String lesson;
}

const chapters = [
  Chapter(0, 'First Light', 'I', 'The next star glows. Follow it.'),
  Chapter(1, 'Wandering Stars', 'II',
      'Loose stars drift between yours. Touch one and the line breaks.'),
  Chapter(2, 'Turning Skies', 'III',
      'Your stars are no longer marked. Find the figure on your chart card, turned somewhere in the sky.'),
  Chapter(3, 'The Unbroken Line', 'IV',
      'Draw every faint line in one stroke, never the same line twice.'),
];

List<Pt> _p(List<List<double>> xy) => [for (final v in xy) Pt(v[0], v[1])];

class _Spec {
  const _Spec(this.name, this.myth);
  final String name;
  final String myth;
}

Night _guidedHand({
  required int id,
  required int chapter,
  required _Spec spec,
  required List<List<double>> stars,
  List<List<double>> decoys = const [],
  TraceMode mode = TraceMode.guided,
  double rotation = 0,
  int extraDecoys = 0,
  int seed = 0,
  bool finale = false,
}) {
  final fit = fitFigure(_p(stars), _p(decoys), radius: 0.43);
  final path = List.generate(stars.length, (i) => i);
  final edges = pathEdges(path);
  final extra = extraDecoys == 0
      ? <Pt>[]
      : FigureGenerator(seed).decoys(fit.stars, edges, extraDecoys);
  return Night(
    id: id,
    chapter: chapter,
    name: spec.name,
    myth: spec.myth,
    mode: mode,
    stars: fit.stars,
    edges: edges,
    path: path,
    decoys: [...fit.decoys, ...extra],
    rotationDegrees: rotation,
    finale: finale,
  );
}

Night _pathGen({
  required int id,
  required int chapter,
  required _Spec spec,
  required int seed,
  required int stars,
  required int decoys,
  TraceMode mode = TraceMode.guided,
  double rotation = 0,
  bool finale = false,
}) {
  final g = FigureGenerator(seed);
  final f = g.path(stars);
  final edges = pathEdges(f.path);
  return Night(
    id: id,
    chapter: chapter,
    name: spec.name,
    myth: spec.myth,
    mode: mode,
    stars: f.stars,
    edges: edges,
    path: f.path,
    decoys: g.decoys(f.stars, edges, decoys),
    rotationDegrees: rotation,
    finale: finale,
  );
}

Night _strokeHand({
  required int id,
  required _Spec spec,
  required List<List<double>> stars,
  required List<List<int>> edges,
  int decoys = 0,
  int seed = 0,
  double rotation = 0,
}) {
  final fit = fitFigure(_p(stars), const [], radius: 0.42);
  final e = [for (final v in edges) Edge(v[0], v[1])];
  return Night(
    id: id,
    chapter: 3,
    name: spec.name,
    myth: spec.myth,
    mode: TraceMode.oneStroke,
    stars: fit.stars,
    edges: e,
    decoys: decoys == 0 ? const [] : FigureGenerator(seed).decoys(fit.stars, e, decoys),
    rotationDegrees: rotation,
  );
}

Night _strokeGen({
  required int id,
  required _Spec spec,
  required int seed,
  required int stars,
  required int loops,
  required int decoys,
  double rotation = 0,
  bool finale = false,
}) {
  final g = FigureGenerator(seed);
  final f = g.trail(stars, loops);
  return Night(
    id: id,
    chapter: 3,
    name: spec.name,
    myth: spec.myth,
    mode: TraceMode.oneStroke,
    stars: f.stars,
    edges: f.edges,
    decoys: g.decoys(f.stars, f.edges, decoys),
    rotationDegrees: rotation,
    finale: finale,
  );
}

/// All 40 campaign nights, in order.
final List<Night> nights = _build();

List<Night> _build() {
  var id = 0;
  int next() => ++id;
  return [
    // ── Chapter I · First Light — guided, no decoys ─────────────────────
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec("The Apprentice's Needle",
            'Every master cartographer began by finding true north.'),
        stars: [[0.46, 0.18], [0.48, 0.38], [0.50, 0.58], [0.53, 0.80]]),
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec('The Three Hearthstones',
            'Winter nights are warmer when you know where home sits in the sky.'),
        stars: [[0.50, 0.22], [0.28, 0.66], [0.72, 0.66], [0.50, 0.46]]),
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec('The Quiet Gate',
            'Pass through only when the lines are true.'),
        stars: [[0.28, 0.66], [0.34, 0.40], [0.50, 0.26], [0.66, 0.40], [0.72, 0.66]]),
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec('The Silver Ladle',
            'Shepherds drank from it long before maps were drawn.'),
        stars: [[0.16, 0.30], [0.30, 0.38], [0.44, 0.44], [0.58, 0.40], [0.74, 0.40], [0.78, 0.60], [0.60, 0.62]]),
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec('The Lantern Bearer',
            'He climbs the eastern ridge each dusk with his lamp.'),
        stars: [[0.22, 0.80], [0.32, 0.62], [0.44, 0.46], [0.52, 0.30], [0.66, 0.24], [0.80, 0.30]]),
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec('The Kettle Handle',
            'Someone always leaves it on the hob of the sky.'),
        stars: [[0.24, 0.62], [0.24, 0.40], [0.38, 0.24], [0.62, 0.24], [0.76, 0.40], [0.76, 0.62]]),
    _guidedHand(id: next(), chapter: 0,
        spec: const _Spec("The Heron's Neck",
            'It bends to drink from the river of night.'),
        stars: [[0.30, 0.82], [0.36, 0.62], [0.50, 0.50], [0.62, 0.36], [0.56, 0.18], [0.38, 0.20]]),
    _guidedHand(id: next(), chapter: 0, finale: true,
        spec: const _Spec('The First Key',
            'Every door in the Atlas opens with this one.'),
        stars: [[0.68, 0.28], [0.50, 0.12], [0.32, 0.28], [0.50, 0.42], [0.50, 0.62], [0.66, 0.72], [0.50, 0.88]]),

    // ── Chapter II · Wandering Stars — guided + decoys ──────────────────
    _guidedHand(id: next(), chapter: 1,
        spec: const _Spec('The Mourning Crown',
            'She sits on her throne upside-down, waiting for dawn.'),
        stars: [[0.14, 0.40], [0.32, 0.24], [0.50, 0.42], [0.68, 0.24], [0.86, 0.40]],
        decoys: [[0.50, 0.14], [0.50, 0.66]]),
    _guidedHand(id: next(), chapter: 1,
        spec: const _Spec("The River's First Bend",
            'Even the sky remembers where water once ran.'),
        stars: [[0.12, 0.30], [0.28, 0.40], [0.44, 0.50], [0.58, 0.56], [0.66, 0.42], [0.74, 0.28], [0.88, 0.22]],
        decoys: [[0.44, 0.28], [0.80, 0.52]]),
    _guidedHand(id: next(), chapter: 1,
        spec: const _Spec('The Twin Watchers',
            'They never blink; they only drift with the seasons.'),
        stars: [[0.30, 0.78], [0.30, 0.52], [0.30, 0.26], [0.70, 0.26], [0.70, 0.52], [0.70, 0.78]],
        decoys: [[0.50, 0.52], [0.10, 0.52], [0.90, 0.52]]),
    _guidedHand(id: next(), chapter: 1,
        spec: const _Spec('The Broken Harp',
            'One string snapped; the music became silence.'),
        stars: [[0.18, 0.70], [0.26, 0.48], [0.40, 0.30], [0.58, 0.26], [0.74, 0.36], [0.82, 0.56], [0.84, 0.78]],
        decoys: [[0.52, 0.56], [0.36, 0.78]]),
    _guidedHand(id: next(), chapter: 1,
        spec: const _Spec("The Cartographer's Signature",
            'Leave your mark so the next apprentice knows you passed.'),
        stars: [[0.16, 0.34], [0.34, 0.22], [0.50, 0.34], [0.50, 0.54], [0.64, 0.70], [0.84, 0.66]],
        decoys: [[0.30, 0.52], [0.72, 0.44], [0.40, 0.80]]),
    _pathGen(id: next(), chapter: 1, seed: 2101, stars: 7, decoys: 3,
        spec: const _Spec('The Lost Sandal',
            'A traveller crossed the sky barefoot ever after.')),
    _pathGen(id: next(), chapter: 1, seed: 2207, stars: 8, decoys: 3,
        spec: const _Spec("The Weaver's Shuttle",
            'Back and forth, she stitched the dusk to the dark.')),
    _pathGen(id: next(), chapter: 1, seed: 2311, stars: 8, decoys: 4,
        spec: const _Spec('The Sleeping Fox',
            'Its tail curls around the pole star to keep warm.')),
    _pathGen(id: next(), chapter: 1, seed: 2417, stars: 9, decoys: 4,
        spec: const _Spec("The Ferryman's Pole",
            'He pushes the night across the water, slowly.')),
    _pathGen(id: next(), chapter: 1, seed: 2503, stars: 9, decoys: 5, finale: true,
        spec: const _Spec('The Bell Tower',
            'It rings once each year, and no one hears it.')),

    // ── Chapter III · Turning Skies — chart card, rotation, hidden ──────
    _guidedHand(id: next(), chapter: 2, mode: TraceMode.chart, rotation: 40,
        extraDecoys: 2, seed: 3001,
        spec: const _Spec('The Frost Crown',
            'Ice crystals pretend to be stars until you connect them.'),
        stars: [[0.18, 0.46], [0.30, 0.24], [0.50, 0.16], [0.70, 0.24], [0.82, 0.46]],
        decoys: [[0.50, 0.40], [0.50, 0.66]]),
    _guidedHand(id: next(), chapter: 2, mode: TraceMode.chart, rotation: -35,
        extraDecoys: 4, seed: 3013,
        spec: const _Spec('The Drifting Canoe',
            'It slides across the sky without a ripple.'),
        stars: [[0.10, 0.40], [0.28, 0.56], [0.50, 0.62], [0.72, 0.56], [0.90, 0.40]]),
    _pathGen(id: next(), chapter: 2, seed: 3101, stars: 6, decoys: 5,
        mode: TraceMode.chart, rotation: 70,
        spec: const _Spec('The Salt Road',
            'Merchants followed it east when the moon was new.')),
    _guidedHand(id: next(), chapter: 2, mode: TraceMode.chart, rotation: 60,
        extraDecoys: 4, seed: 3023,
        spec: const _Spec('The Elder Compass',
            'Four points, yet only one path is correct.'),
        stars: [[0.50, 0.12], [0.76, 0.30], [0.76, 0.66], [0.50, 0.86], [0.24, 0.66], [0.24, 0.30]],
        decoys: [[0.50, 0.48]]),
    _pathGen(id: next(), chapter: 2, seed: 3203, stars: 6, decoys: 6,
        mode: TraceMode.chart, rotation: 110,
        spec: const _Spec("The Owl's Lantern",
            'It sees the things the sun forgets.')),
    _guidedHand(id: next(), chapter: 2, mode: TraceMode.chart, rotation: 75,
        extraDecoys: 4, seed: 3031,
        spec: const _Spec('The Last Ember',
            'The final spark before the sky goes dark.'),
        stars: [[0.30, 0.22], [0.52, 0.14], [0.74, 0.26], [0.80, 0.50], [0.66, 0.72], [0.42, 0.74]],
        decoys: [[0.52, 0.44]]),
    _pathGen(id: next(), chapter: 2, seed: 3307, stars: 7, decoys: 6,
        mode: TraceMode.chart, rotation: -60,
        spec: const _Spec('The Broken Wheel',
            'It turned the seasons until one spoke fell away.')),
    _pathGen(id: next(), chapter: 2, seed: 3409, stars: 7, decoys: 7,
        mode: TraceMode.chart, rotation: 150,
        spec: const _Spec('The Glass Fish',
            'Caught once, and thrown back to the deep sky.')),
    _pathGen(id: next(), chapter: 2, seed: 3511, stars: 7, decoys: 7,
        mode: TraceMode.chart, rotation: -120,
        spec: const _Spec('The Winding Stair',
            'Each step a little colder, a little nearer.')),
    _pathGen(id: next(), chapter: 2, seed: 3613, stars: 8, decoys: 7,
        mode: TraceMode.chart, rotation: 95,
        spec: const _Spec("The Fiddler's Bow",
            'It crosses no string, yet the whole sky hums.')),
    _guidedHand(id: next(), chapter: 2, mode: TraceMode.chart, rotation: 180,
        extraDecoys: 6, seed: 3041,
        spec: const _Spec("The Navigator's Oath",
            'Swear by the sky, and the sky will hold you to it.'),
        stars: [[0.20, 0.30], [0.40, 0.18], [0.62, 0.22], [0.80, 0.38], [0.76, 0.62], [0.56, 0.78], [0.34, 0.70]]),
    _pathGen(id: next(), chapter: 2, seed: 3719, stars: 8, decoys: 8, finale: true,
        mode: TraceMode.chart, rotation: -150,
        spec: const _Spec('The Northern Gate',
            'Beyond it, the charts are blank.')),

    // ── Chapter IV · The Unbroken Line — one stroke ─────────────────────
    _strokeHand(id: next(),
        spec: const _Spec("The Shepherd's Hut",
            'Draw it in one breath, as the old shepherds did.'),
        stars: [[0.26, 0.80], [0.74, 0.80], [0.74, 0.44], [0.26, 0.44], [0.50, 0.14]],
        edges: [[0, 1], [1, 2], [2, 3], [3, 0], [0, 2], [1, 3], [3, 4], [4, 2]]),
    _strokeHand(id: next(), decoys: 2, seed: 4011,
        spec: const _Spec('The Hourglass',
            'Time runs both ways when no one is watching.'),
        stars: [[0.26, 0.16], [0.74, 0.16], [0.50, 0.46], [0.26, 0.76], [0.74, 0.76], [0.90, 0.92]],
        edges: [[0, 1], [1, 2], [2, 0], [2, 3], [3, 4], [4, 2], [4, 5]]),
    _strokeGen(id: next(), seed: 4101, stars: 6, loops: 2, decoys: 2,
        spec: const _Spec("The Spider's Mending",
            'She repairs one thread each night, never the same one.')),
    _strokeHand(id: next(), decoys: 3, seed: 4021, rotation: 20,
        spec: const _Spec('The Kite and String',
            'A child let go of it, and the sky kept it.'),
        stars: [[0.50, 0.08], [0.74, 0.34], [0.50, 0.60], [0.26, 0.34], [0.36, 0.80], [0.58, 0.94]],
        edges: [[0, 1], [1, 2], [2, 3], [3, 0], [0, 2], [2, 4], [4, 5]]),
    _strokeGen(id: next(), seed: 4203, stars: 7, loops: 2, decoys: 3,
        spec: const _Spec('The Orchard Fence',
            'It keeps the falling stars from straying.')),
    _strokeGen(id: next(), seed: 4307, stars: 7, loops: 3, decoys: 3, rotation: 45,
        spec: const _Spec('The Tidewater Net',
            'Cast at dusk, hauled in full of light.')),
    _strokeHand(id: next(), decoys: 2, seed: 4031,
        spec: const _Spec('The Five-Point Seal',
            'Pressed into wax on every chart worth keeping.'),
        stars: [[0.50, 0.08], [0.90, 0.37], [0.75, 0.84], [0.25, 0.84], [0.10, 0.37]],
        edges: [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [0, 2], [2, 4], [4, 1], [1, 3], [3, 0]]),
    _strokeGen(id: next(), seed: 4409, stars: 8, loops: 3, decoys: 3, rotation: -30,
        spec: const _Spec('The Lighthouse Keeper',
            'He trims the wick and watches the dark sea of stars.')),
    _strokeGen(id: next(), seed: 4511, stars: 9, loops: 3, decoys: 4, rotation: 70,
        spec: const _Spec('The Folded Map',
            'Unfold it carefully; the creases are rivers.')),
    _strokeGen(id: next(), seed: 4613, stars: 11, loops: 4, decoys: 4, rotation: 15,
        finale: true,
        spec: const _Spec('The Master Chart',
            'When this map is complete, you are no longer an apprentice.')),
  ];
}

Night? nightById(int id) =>
    id >= 1 && id <= nights.length ? nights[id - 1] : null;

List<Night> nightsInChapter(int chapter) =>
    nights.where((n) => n.chapter == chapter).toList();
