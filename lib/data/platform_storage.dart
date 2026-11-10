/// The storage this device uses: a JSON file on phones, the browser's own
/// storage on the web version.
library;

export 'platform_storage_io.dart' if (dart.library.js_interop) 'platform_storage_web.dart';
