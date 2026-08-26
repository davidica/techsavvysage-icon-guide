'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v0.4.2';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/icons.js',
    './04_Application/js/app.js',
    './04_Application/data/icons.json',
    './04_Application/data/lessons.json',
    './04_Application/data/assessments.json',
    './04_Application/assets/app-icons/icon-guide-192.png',
    './04_Application/assets/app-icons/icon-guide-512.png'
];

self.addEventListener('install', function (event) {
    event.waitUntil(caches.open(CACHE_NAME).then(function (cache) {
        return Promise.all(CORE_ASSETS.map(function (asset) {
            return fetch(asset, { cache: 'reload' }).then(function (response) {
                if (!response.ok) {
                    throw new Error('Unable to cache ' + asset);
                }

                return cache.put(asset, response);
            });
        }));
    }));
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    event.waitUntil(caches.keys().then(function (cacheNames) {
        return Promise.all(cacheNames.filter(function (cacheName) {
            return cacheName !== CACHE_NAME;
        }).map(function (cacheName) {
            return caches.delete(cacheName);
        }));
    }));
    self.clients.claim();
});

self.addEventListener('message', function (event) {
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});

self.addEventListener('fetch', function (event) {
    if (event.request.method !== 'GET') {
        return;
    }

    const requestUrl = new URL(event.request.url);

    if (requestUrl.origin !== self.location.origin) {
        return;
    }

    event.respondWith(fetch(event.request).then(function (networkResponse) {
        if (networkResponse.ok) {
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then(function (cache) {
                cache.put(event.request, responseToCache);
            });
        }

        return networkResponse;
    }).catch(function () {
        return caches.match(event.request).then(function (cachedResponse) {
            if (cachedResponse) {
                return cachedResponse;
            }

            if (event.request.mode === 'navigate') {
                return caches.match('./index.html');
            }

            return Response.error();
        });
    }));
});
