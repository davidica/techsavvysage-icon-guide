'use strict';

document.addEventListener('DOMContentLoaded', function () {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('service-worker.js').catch(function () {
            // The utility remains functional if offline support is unavailable.
        });
    }
});
