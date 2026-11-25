import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/progress_store.dart';
import 'services/feedback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicences();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await ProgressStore.open();
  runApp(BrassAndStarlightApp(progress: progress, feedback: SkyFeedback(progress)));
}

/// The bundled fonts are OFL; their licences ship with the app.
void _registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (pkg, file) in [
      ('Cinzel', 'assets/fonts/OFL-Cinzel.txt'),
      ('Crimson Pro', 'assets/fonts/OFL-CrimsonPro.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([pkg], await rootBundle.loadString(file));
    }
  });
}
