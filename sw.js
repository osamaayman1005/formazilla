// Formazilla offline service worker. CI fills in VERSION and ASSETS after
// `flutter build web` (see .github/workflows/web.yml).
const VERSION = '8ffd54d82bbc';
const ASSETS = [
 "./",
 "favicon.png",
 "flutter.js",
 "flutter_bootstrap.js",
 "index.html",
 "main.dart.js",
 "manifest.json",
 "version.json",
 "canvaskit/canvaskit.js",
 "canvaskit/canvaskit.wasm",
 "canvaskit/chromium/canvaskit.js",
 "canvaskit/chromium/canvaskit.wasm",
 "assets/AssetManifest.bin",
 "assets/AssetManifest.bin.json",
 "assets/FontManifest.json",
 "assets/NOTICES",
 "assets/shaders/ink_sparkle.frag",
 "assets/shaders/stretch_effect.frag",
 "assets/fonts/MaterialIcons-Regular.otf",
 "assets/fonts/fallback/Roboto-Regular.ttf",
 "assets/assets/logo.png",
 "assets/assets/mascot.png",
 "assets/assets/fonts/Archivo-Bold.ttf",
 "assets/assets/fonts/Archivo-ExtraBold.ttf",
 "assets/assets/fonts/Archivo-Medium.ttf",
 "assets/assets/fonts/Archivo-Regular.ttf",
 "assets/assets/fonts/Archivo-SemiBold.ttf",
 "assets/assets/fonts/ArchivoCondensed-Bold.ttf",
 "assets/assets/fonts/ArchivoCondensed-ExtraBold.ttf",
 "icons/Icon-192.png",
 "icons/Icon-512.png",
 "icons/Icon-maskable-192.png",
 "icons/Icon-maskable-512.png",
 "icons/apple-touch-icon.png"
];
const CACHE = 'formazilla-' + VERSION;

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('formazilla-') && k !== CACHE && k !== 'formazilla-fonts').map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

// Fallback fonts for symbols (✓, →) come from Google Fonts the first time
// they're needed; keep them so they also show offline.
const FONTS = 'https://fonts.gstatic.com';

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const origin = new URL(req.url).origin;
  if (origin === FONTS) {
    event.respondWith(caches.open('formazilla-fonts').then((c) => c.match(req).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok || res.type === 'opaque') c.put(req, res.clone());
      return res;
    }))));
    return;
  }
  if (origin !== self.location.origin) return;

  // The page itself: fresh when online (gets updates), cached when offline.
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put('./', copy));
          return res;
        })
        .catch(() => caches.match('./')),
    );
    return;
  }

  // Everything else: cache first (the app's files are versioned per build).
  event.respondWith(
    caches.match(req, { ignoreSearch: true }).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy));
      }
      return res;
    })),
  );
});
