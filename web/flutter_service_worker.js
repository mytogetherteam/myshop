'use strict';

// The name of the cache. Update this version number to clear the cache.
const CACHE_NAME = 'myshop-pwa-v1';

// Resources to cache immediately on install.
const CORE_RESOURCES = [
  './',
  'index.html',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'flutter.js',
  'flutter_bootstrap.js',
  'icons/Icon-192.png',
  'icons/Icon-512.png'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CORE_RESOURCES);
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

self.addEventListener('fetch', (event) => {
  // Only handle GET requests
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((response) => {
      // Return cached response if found, else fetch from network
      return response || fetch(event.request).then((networkResponse) => {
        // Optionally cache new resources here
        return networkResponse;
      });
    }).catch(() => {
      // Fallback logic could go here
    })
  );
});
