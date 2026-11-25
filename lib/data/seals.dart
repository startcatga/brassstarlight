/// Local achievements ("Seals"). Earned only by playing; nothing is sold.
class SealDef {
  const SealDef(this.id, this.name, this.how);

  final String id;
  final String name;

  /// What earns it, in plain words.
  final String how;
}

const sealDefs = [
  SealDef('first', 'First Ink', 'Seal your first constellation.'),
  SealDef('ch0', 'Dawn Apprentice', 'Chart every night of First Light.'),
  SealDef('ch1', 'Steady Hand', 'Chart every night of Wandering Stars.'),
  SealDef('ch2', 'Sky Reader', 'Chart every night of Turning Skies.'),
  SealDef('ch3', 'Master Cartographer', 'Chart every night of The Unbroken Line.'),
  SealDef('flawless5', 'Clean Lines', 'Seal 5 constellations without a broken line.'),
  SealDef('flawless20', 'Unwavering', 'Seal 20 constellations without a broken line.'),
  SealDef('dark', 'By Starlight Alone', 'Chart a whole chapter without lighting a lantern.'),
  SealDef('daily1', 'Night Watch', "Chart Tonight's Sky for the first time."),
  SealDef('streak3', 'Three Clear Nights', "Chart Tonight's Sky three days in a row."),
  SealDef('streak7', 'A Week of Watching', "Chart Tonight's Sky seven days in a row."),
  SealDef('atlas', 'The Atlas Complete', 'Chart all forty nights.'),
];

SealDef? sealById(String id) {
  for (final s in sealDefs) {
    if (s.id == id) return s;
  }
  return null;
}
