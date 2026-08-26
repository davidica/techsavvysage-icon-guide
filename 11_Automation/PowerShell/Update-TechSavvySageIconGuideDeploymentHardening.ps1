# ============================================================================
# Update-TechSavvySageIconGuideDeploymentHardening.ps1
# ============================================================================

[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [ValidateSet('Update', 'ValidateOnly')]
    [string]$OperatingMode = 'Update',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:UpdatedFiles = 0
$Script:CreatedFiles = 0
$Script:ValidatedFiles = 0
$Script:MissingFiles = 0

function Write-Banner {
    param ([Parameter(Mandatory)][string]$Text)

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
}

function Write-Status {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'CREATE', 'UPDATE', 'VALIDATE', 'PASS', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'CREATE'   { 'Green' }
        'UPDATE'   { 'Yellow' }
        'VALIDATE' { 'Cyan' }
        'PASS'     { 'Green' }
        'FAIL'     { 'Red' }
        default    { 'Gray' }
    }

    Write-Host ('[{0,-8}] {1}' -f $Level, $Message) -ForegroundColor $Color
}

function Get-NormalizedPath {
    param ([Parameter(Mandatory)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
}

function Resolve-RepositoryRoot {
    param (
        [string]$ExplicitRepositoryRoot,
        [Parameter(Mandatory)][string]$ScriptRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRepositoryRoot)) {
        return Get-NormalizedPath -Path $ExplicitRepositoryRoot
    }

    $NormalizedScriptRoot = Get-NormalizedPath -Path $ScriptRoot

    if ((Split-Path $NormalizedScriptRoot -Leaf) -ieq $Script:ExpectedRepositoryName) {
        return $NormalizedScriptRoot
    }

    if ((Split-Path $NormalizedScriptRoot -Leaf) -ieq 'PowerShell') {
        $AutomationRoot = Split-Path $NormalizedScriptRoot -Parent

        if ((Split-Path $AutomationRoot -Leaf) -ieq '11_Automation') {
            return Split-Path $AutomationRoot -Parent
        }
    }

    throw 'Place this update in the repository root or 11_Automation\PowerShell, or provide -RepositoryRoot.'
}

function Write-Utf8File {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $NormalizedContent = $Content.TrimEnd([char[]]@("`r", "`n")) + "`n"
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf
    [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)

    if ($Exists) {
        $Script:UpdatedFiles++
        Write-Status -Level 'UPDATE' -Message $Path
    }
    else {
        $Script:CreatedFiles++
        Write-Status -Level 'CREATE' -Message $Path
    }
}

function Update-RequiredText {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText
    )

    $Content = Get-Content -LiteralPath $Path -Raw

    if ($Content.Contains($NewText)) {
        Write-Status -Level 'INFO' -Message "Update already present: $Path"
        return
    }

    if (-not $Content.Contains($OldText)) {
        throw "The expected deployment marker was not found in: $Path"
    }

    Write-Utf8File -Path $Path -Content $Content.Replace($OldText, $NewText)
}

try {
    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE DEPLOYMENT HARDENING v0.2.1'

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the deployment-hardening script directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    $AppPath = Join-Path $ResolvedRepositoryRoot '04_Application\js\app.js'
    $ServiceWorkerPath = Join-Path $ResolvedRepositoryRoot 'service-worker.js'
    $Phase2BuilderPath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase2.ps1'
    $HardeningNotesPath = Join-Path $ResolvedRepositoryRoot '01_Documentation\Phase_2_1_Deployment_Hardening.md'

    foreach ($RequiredPath in @($AppPath, $ServiceWorkerPath, $Phase2BuilderPath)) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            $Script:MissingFiles++
            throw "Required Phase 2 file is missing: $RequiredPath"
        }
    }

    $OldRegistration = @'
            if ('serviceWorker' in navigator) {
                navigator.serviceWorker.register('service-worker.js').catch(function () {
                    // The utility remains functional if offline support is unavailable.
                });
            }
'@

    $NewRegistration = @'
            if ('serviceWorker' in navigator) {
                let refreshingForUpdate = false;

                navigator.serviceWorker.addEventListener('controllerchange', function () {
                    if (refreshingForUpdate) {
                        return;
                    }

                    refreshingForUpdate = true;
                    window.location.reload();
                });

                navigator.serviceWorker.register('service-worker.js').then(function (registration) {
                    registration.update();
                }).catch(function () {
                    // The utility remains functional if offline support is unavailable.
                });
            }
'@

    $OldServiceWorker = @'
'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v0.2.0';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/icons.js',
    './04_Application/js/app.js',
    './04_Application/data/icons.json',
    './04_Application/assets/app-icons/icon-guide-192.png',
    './04_Application/assets/app-icons/icon-guide-512.png'
];

self.addEventListener('install', function (event) {
    event.waitUntil(caches.open(CACHE_NAME).then(function (cache) {
        return cache.addAll(CORE_ASSETS);
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

self.addEventListener('fetch', function (event) {
    if (event.request.method !== 'GET') {
        return;
    }

    event.respondWith(caches.match(event.request).then(function (cachedResponse) {
        return cachedResponse || fetch(event.request);
    }));
});
'@

    $NewServiceWorker = @'
'use strict';

const CACHE_NAME = 'techsavvysage-icon-guide-v0.2.1';
const CORE_ASSETS = [
    './',
    './index.html',
    './manifest.webmanifest',
    './04_Application/css/styles.css',
    './04_Application/js/icons.js',
    './04_Application/js/app.js',
    './04_Application/data/icons.json',
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
'@

    $HardeningNotes = @'
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
'@

    if ($OperatingMode -eq 'Update') {
        if (-not $Force) {
            throw 'Run Update mode with -Force after confirming Phase 2 is committed.'
        }

        Update-RequiredText -Path $AppPath -OldText $OldRegistration -NewText $NewRegistration
        Write-Utf8File -Path $ServiceWorkerPath -Content $NewServiceWorker
        Update-RequiredText -Path $Phase2BuilderPath -OldText $OldRegistration -NewText $NewRegistration
        Update-RequiredText -Path $Phase2BuilderPath -OldText $OldServiceWorker -NewText $NewServiceWorker
        Update-RequiredText `
            -Path $Phase2BuilderPath `
            -OldText "`$Script:UtilityVersion = '0.2.0'" `
            -NewText "`$Script:UtilityVersion = '0.2.1'"
        Write-Utf8File -Path $HardeningNotesPath -Content $HardeningNotes

        $CanonicalUpdatePath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Update-TechSavvySageIconGuideDeploymentHardening.ps1'
        $CurrentScriptPath = Get-NormalizedPath -Path $MyInvocation.MyCommand.Path

        if ($CurrentScriptPath -ne (Get-NormalizedPath -Path $CanonicalUpdatePath)) {
            Copy-Item -LiteralPath $CurrentScriptPath -Destination $CanonicalUpdatePath -Force
            Write-Status -Level 'UPDATE' -Message $CanonicalUpdatePath
        }
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. No files were changed.'
    }

    $CanonicalUpdatePath = Join-Path $ResolvedRepositoryRoot '11_Automation\PowerShell\Update-TechSavvySageIconGuideDeploymentHardening.ps1'
    $ValidationRules = @(
        @{ Path = $AppPath; Marker = 'registration.update()' },
        @{ Path = $AppPath; Marker = "addEventListener('controllerchange'" },
        @{ Path = $ServiceWorkerPath; Marker = "techsavvysage-icon-guide-v0.2.1" },
        @{ Path = $ServiceWorkerPath; Marker = "fetch(event.request)" },
        @{ Path = $ServiceWorkerPath; Marker = "cache: 'reload'" },
        @{ Path = $Phase2BuilderPath; Marker = "`$Script:UtilityVersion = '0.2.1'" },
        @{ Path = $Phase2BuilderPath; Marker = "techsavvysage-icon-guide-v0.2.1" },
        @{ Path = $HardeningNotesPath; Marker = '# Phase 2.1 Deployment Hardening' },
        @{ Path = $CanonicalUpdatePath; Marker = '[CmdletBinding()]' }
    )

    foreach ($Rule in $ValidationRules) {
        Write-Status -Level 'VALIDATE' -Message ("{0} :: {1}" -f $Rule.Path, $Rule.Marker)

        if (-not (Test-Path -LiteralPath $Rule.Path -PathType Leaf)) {
            $Script:MissingFiles++
            throw "Required deployment-hardening file is missing: $($Rule.Path)"
        }

        $Content = Get-Content -LiteralPath $Rule.Path -Raw

        if (-not $Content.Contains($Rule.Marker)) {
            throw "Required deployment-hardening marker is missing: $($Rule.Marker)"
        }

        $Script:ValidatedFiles++
        Write-Status -Level 'PASS' -Message 'Required deployment-hardening marker detected.'
    }

    Write-Host ''
    Write-Host 'Execution Metrics' -ForegroundColor Cyan
    Write-Host ('-' * 76) -ForegroundColor DarkGray
    Write-Host ('{0,-28}: {1}' -f 'Updated file operations', $Script:UpdatedFiles)
    Write-Host ('{0,-28}: {1}' -f 'Created files', $Script:CreatedFiles)
    Write-Host ('{0,-28}: {1}' -f 'Validated markers', $Script:ValidatedFiles)
    Write-Host ('{0,-28}: {1}' -f 'Missing files', $Script:MissingFiles)

    Write-Banner -Text 'DEPLOYMENT HARDENING UPDATE COMPLETE'
    Write-Status -Level 'PASS' -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE DEPLOYMENT HARDENING ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
