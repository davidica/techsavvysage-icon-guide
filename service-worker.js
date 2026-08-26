'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v0.1.1';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/icons.js',
    './04_Application/js/app.js',
    './04_Application/data/icons.json'
];

self.addEventListener('install', function (event) {
    event.waitUntil(
        caches.open(CACHE_NAME).then(function (cache) {
            return cache.addAll(CORE_ASSETS);
        })
    );
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    event.waitUntil(
        caches.keys().then(function (cacheNames) {
            return Promise.all(
                cacheNames
                    .filter(function (cacheName) {
                        return cacheName !== CACHE_NAME;
                    })
                    .map(function (cacheName) {
                        return caches.delete(cacheName);
                    })
            );
        })
    );
    self.clients.claim();
});

self.addEventListener('fetch', function (event) {
    if (event.request.method !== 'GET') {
        return;
    }

    event.respondWith(
        caches.match(event.request).then(function (cachedResponse) {
            return cachedResponse || fetch(event.request).then(function (networkResponse) {
                return networkResponse;
            });
        })
    );
});
