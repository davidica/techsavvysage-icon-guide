# Phase 2.1 Deployment Hardening

## Purpose

This maintenance update prevents an earlier cached release from remaining visible after a new GitHub Pages deployment.

## Changes

- Uses network-first loading while the learner is online.
- Retains cached application files for offline use.
- Refreshes pre-cached files without relying on the browser HTTP cache.
- Activates a new service worker immediately.
- Checks for an updated service worker when the application starts.
- Reloads the page once when a new service worker assumes control.

## Privacy

The update introduces no analytics, accounts, cloud synchronization, or personally identifiable information collection.
