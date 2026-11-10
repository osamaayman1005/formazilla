/// gzip for plan codes (FZ2). dart:io on phones, a pure-Dart codec on the web.
library;

export 'gzip_io.dart' if (dart.library.js_interop) 'gzip_web.dart';
