# ============================================================================
# Build-TechSavvySageIconGuidePhase3Data.ps1
# Phase 3A - Lesson Data Foundation
# ============================================================================
[CmdletBinding()]
param (
    [string]$RepositoryRoot,

    [ValidateSet('Build', 'ValidateOnly')]
    [string]$OperatingMode = 'Build',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:UtilityName = 'TechSavvySage Icon Guide Phase 3A Lesson Data Builder'
$Script:UtilityVersion = '0.3.0'
$Script:ExpectedRepositoryName = 'techsavvysage-icon-guide'
$Script:CreatedFiles = 0
$Script:ReplacedFiles = 0
$Script:ValidatedLessons = 0
$Script:ValidatedSteps = 0

function Write-Banner {
    param ([Parameter(Mandatory)][string]$Text)

    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor Cyan
}

function Write-Section {
    param ([Parameter(Mandatory)][string]$Text)

    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('-' * 76) -ForegroundColor DarkGray
}

function Write-Status {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'CREATE', 'REPLACE', 'VALIDATE', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)][string]$Message
    )

    $Color = switch ($Level) {
        'CREATE'   { 'Green' }
        'REPLACE'  { 'Yellow' }
        'VALIDATE' { 'Cyan' }
        'PASS'     { 'Green' }
        'WARN'     { 'Yellow' }
        'FAIL'     { 'Red' }
        default    { 'Gray' }
    }

    Write-Host ('[{0,-8}] {1}' -f $Level, $Message) -ForegroundColor $Color
}

function Write-Metric {
    param (
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value
    )

    Write-Host ('{0,-32}: {1}' -f $Name, $Value)
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

    if ((Split-Path -Path $NormalizedScriptRoot -Leaf) -ieq $Script:ExpectedRepositoryName) {
        return $NormalizedScriptRoot
    }

    if ((Split-Path -Path $NormalizedScriptRoot -Leaf) -ieq 'PowerShell') {
        $AutomationRoot = Split-Path -Path $NormalizedScriptRoot -Parent

        if ((Split-Path -Path $AutomationRoot -Leaf) -ieq '11_Automation') {
            return Split-Path -Path $AutomationRoot -Parent
        }
    }

    throw @'
Unable to determine the repository root automatically.

Place this builder in either the techsavvysage-icon-guide repository root or
11_Automation\PowerShell. You may also provide -RepositoryRoot explicitly.
'@
}

function Write-Utf8File {
    param (
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $NormalizedContent = $Content.TrimEnd([char[]]@("`r", "`n")) + "`n"
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf
    [System.IO.File]::WriteAllText($Path, $NormalizedContent, $Utf8NoBom)

    if ($Exists) {
        $Script:ReplacedFiles++
        Write-Status -Level 'REPLACE' -Message $Path
    }
    else {
        $Script:CreatedFiles++
        Write-Status -Level 'CREATE' -Message $Path
    }
}

function Test-RequiredProperties {
    param (
        [Parameter(Mandatory)][object]$Record,
        [Parameter(Mandatory)][string[]]$PropertyNames,
        [Parameter(Mandatory)][string]$RecordDescription
    )

    $AvailableProperties = @($Record.PSObject.Properties.Name)

    foreach ($PropertyName in $PropertyNames) {
        if ($AvailableProperties -notcontains $PropertyName) {
            throw "$RecordDescription is missing required property '$PropertyName'."
        }

        $Value = $Record.$PropertyName

        if ($null -eq $Value) {
            throw "$RecordDescription property '$PropertyName' cannot be null."
        }

        if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
            throw "$RecordDescription property '$PropertyName' cannot be empty."
        }
    }
}

function Test-SequentialOrder {
    param (
        [Parameter(Mandatory)][object[]]$Records,
        [Parameter(Mandatory)][string]$RecordDescription
    )

    $ActualOrder = @($Records | Sort-Object order | ForEach-Object { [int]$_.order })
    $ExpectedOrder = @(1..$Records.Count)

    if (($ActualOrder -join ',') -ne ($ExpectedOrder -join ',')) {
        throw "$RecordDescription order values must be unique and sequential from 1 through $($Records.Count)."
    }
}

function Test-LessonData {
    param (
        [Parameter(Mandatory)][string]$IconDataPath,
        [Parameter(Mandatory)][string]$LessonDataPath
    )

    Write-Section -Text 'Phase 3A - Lesson Reference Validation'

    if (-not (Test-Path -LiteralPath $IconDataPath -PathType Leaf)) {
        throw "The icon library was not found: $IconDataPath"
    }

    if (-not (Test-Path -LiteralPath $LessonDataPath -PathType Leaf)) {
        throw "The lesson data file was not found: $LessonDataPath"
    }

    Write-Status -Level 'VALIDATE' -Message $IconDataPath
    $IconData = Get-Content -LiteralPath $IconDataPath -Raw | ConvertFrom-Json
    $Icons = @($IconData.icons)
    $IconIds = @($Icons | ForEach-Object { [string]$_.id })
    $DuplicateIconIds = @(
        $IconIds |
        Group-Object |
        Where-Object { $_.Count -gt 1 }
    )

    if ($Icons.Count -ne 40) {
        throw "Expected the Phase 2 baseline of 40 icons; found $($Icons.Count)."
    }

    if ($DuplicateIconIds.Count -gt 0) {
        throw 'The icon library contains duplicate icon identifiers.'
    }

    Write-Status -Level 'PASS' -Message 'Icon library contains 40 unique records.'

    Write-Status -Level 'VALIDATE' -Message $LessonDataPath
    $LessonData = Get-Content -LiteralPath $LessonDataPath -Raw | ConvertFrom-Json
    Test-RequiredProperties `
        -Record $LessonData `
        -PropertyNames @('schema_version', 'utility', 'phase', 'lessons') `
        -RecordDescription 'Lesson data root'

    if ([string]$LessonData.schema_version -ne '1.0.0') {
        throw "Expected lesson schema version 1.0.0; found $($LessonData.schema_version)."
    }

    $Lessons = @($LessonData.lessons)

    if ($Lessons.Count -ne 4) {
        throw "Expected exactly four lesson records; found $($Lessons.Count)."
    }

    $DuplicateLessonIds = @(
        $Lessons |
        Group-Object id |
        Where-Object { $_.Count -gt 1 }
    )

    if ($DuplicateLessonIds.Count -gt 0) {
        throw 'Duplicate lesson identifiers were detected.'
    }

    Test-SequentialOrder -Records $Lessons -RecordDescription 'Lesson'

    $ReferencedIconIds = New-Object System.Collections.Generic.List[string]
    $AllStepIds = New-Object System.Collections.Generic.List[string]

    foreach ($Lesson in ($Lessons | Sort-Object order)) {
        Test-RequiredProperties `
            -Record $Lesson `
            -PropertyNames @(
                'id',
                'order',
                'title',
                'summary',
                'estimated_minutes',
                'completion_message',
                'steps'
            ) `
            -RecordDescription "Lesson '$($Lesson.id)'"

        if ([string]$Lesson.id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
            throw "Lesson identifier '$($Lesson.id)' must use lowercase kebab-case."
        }

        if ([int]$Lesson.estimated_minutes -lt 1) {
            throw "Lesson '$($Lesson.id)' must have an estimated time of at least one minute."
        }

        $Steps = @($Lesson.steps)

        if ($Steps.Count -lt 1) {
            throw "Lesson '$($Lesson.id)' must contain at least one step."
        }

        Test-SequentialOrder `
            -Records $Steps `
            -RecordDescription "Steps in lesson '$($Lesson.id)'"

        $DuplicateStepIds = @(
            $Steps |
            Group-Object id |
            Where-Object { $_.Count -gt 1 }
        )

        if ($DuplicateStepIds.Count -gt 0) {
            throw "Lesson '$($Lesson.id)' contains duplicate step identifiers."
        }

        foreach ($Step in ($Steps | Sort-Object order)) {
            Test-RequiredProperties `
                -Record $Step `
                -PropertyNames @(
                    'id',
                    'order',
                    'icon_id',
                    'heading',
                    'instruction',
                    'practice_prompt'
                ) `
                -RecordDescription "Step '$($Step.id)' in lesson '$($Lesson.id)'"

            if ([string]$Step.id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                throw "Step identifier '$($Step.id)' must use lowercase kebab-case."
            }

            $QualifiedStepId = '{0}/{1}' -f $Lesson.id, $Step.id

            if ($AllStepIds.Contains($QualifiedStepId)) {
                throw "Duplicate qualified step identifier detected: $QualifiedStepId"
            }

            $AllStepIds.Add($QualifiedStepId)
            $ReferencedIconIds.Add([string]$Step.icon_id)

            if ($IconIds -cnotcontains [string]$Step.icon_id) {
                throw "Lesson step '$QualifiedStepId' references unknown icon '$($Step.icon_id)'."
            }

            $Script:ValidatedSteps++
        }

        $Script:ValidatedLessons++
        Write-Status `
            -Level 'PASS' `
            -Message ("Validated lesson {0}: {1} steps." -f $Lesson.order, $Steps.Count)
    }

    $UniqueReferencedIconIds = @($ReferencedIconIds | Sort-Object -Unique)
    $UnreferencedIconIds = @($IconIds | Where-Object { $UniqueReferencedIconIds -cnotcontains $_ })

    if ($UnreferencedIconIds.Count -gt 0) {
        Write-Status `
            -Level 'WARN' `
            -Message ('Icons not yet used in a lesson: {0}' -f ($UnreferencedIconIds -join ', '))
    }
    else {
        Write-Status -Level 'PASS' -Message 'All 40 library icons are represented in the four lessons.'
    }

    Write-Status -Level 'PASS' -Message 'Every lesson step resolves to an existing icon record.'

    return [pscustomobject]@{
        IconCount = $Icons.Count
        LessonCount = $Lessons.Count
        StepCount = $Script:ValidatedSteps
        UniqueReferencedIconCount = $UniqueReferencedIconIds.Count
        UnreferencedIconCount = $UnreferencedIconIds.Count
    }
}

try {
    Write-Banner -Text ('{0} v{1}' -f $Script:UtilityName, $Script:UtilityVersion)

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw 'Windows PowerShell 5.1 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        throw 'Unable to determine the Phase 3A builder directory.'
    }

    $ResolvedRepositoryRoot = Resolve-RepositoryRoot `
        -ExplicitRepositoryRoot $RepositoryRoot `
        -ScriptRoot $PSScriptRoot

    if (-not (Test-Path -LiteralPath $ResolvedRepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $ResolvedRepositoryRoot"
    }

    $IconDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\icons.json'
    $LessonDataPath = Join-Path $ResolvedRepositoryRoot '04_Application\data\lessons.json'
    $Phase2BuilderPath = Join-Path `
        $ResolvedRepositoryRoot `
        '11_Automation\PowerShell\Build-TechSavvySageIconGuidePhase2.ps1'

    Write-Section -Text 'Phase 3A - Preflight Validation'

    foreach ($RequiredPath in @($IconDataPath, $Phase2BuilderPath)) {
        if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
            throw "The validated Phase 2 baseline is incomplete: $RequiredPath"
        }

        Write-Status -Level 'PASS' -Message $RequiredPath
    }

    if ($OperatingMode -eq 'Build') {
        if ((Test-Path -LiteralPath $LessonDataPath -PathType Leaf) -and -not $Force) {
            throw 'Lesson data already exists. Use -Force only after reviewing and committing the current lesson file.'
        }

        Write-Section -Text 'Phase 3A - Create Four Lesson Records'

        $LessonDataContent = @'
{
  "schema_version": "1.0.0",
  "utility": "TechSavvySage Icon Guide",
  "phase": "3A",
  "record_type": "guided_lessons",
  "lessons": [
    {
      "id": "find-your-way",
      "order": 1,
      "title": "Find Your Way",
      "summary": "Practice the icons that help you move through apps and websites without feeling lost.",
      "estimated_minutes": 8,
      "completion_message": "You can now recognize the common controls used to move, search, refresh, and close.",
      "steps": [
        {"id":"start-at-home","order":1,"icon_id":"home","heading":"Return to a familiar starting point","instruction":"The Home icon takes you to the main screen of an app or website.","practice_prompt":"Choose Home when you want the main screen without closing the app."},
        {"id":"go-back","order":2,"icon_id":"back","heading":"Return to the previous screen","instruction":"The Back icon returns to the screen or page you just left.","practice_prompt":"Choose Back after opening the wrong page."},
        {"id":"move-forward","order":3,"icon_id":"forward","heading":"Move to the next page again","instruction":"The Forward icon moves ahead after you have used Back.","practice_prompt":"Choose Forward to revisit the page that came after the current one."},
        {"id":"open-menu","order":4,"icon_id":"menu","heading":"Open the main choices","instruction":"The Menu icon reveals sections and actions that are not always visible.","practice_prompt":"Choose Menu to look for Profile, Help, Settings, or Sign Out."},
        {"id":"find-something","order":5,"icon_id":"search","heading":"Find information","instruction":"The Search icon helps locate people, files, settings, messages, or topics.","practice_prompt":"Choose Search when you know a word but not where the item is stored."},
        {"id":"see-more","order":6,"icon_id":"more","heading":"Reveal additional choices","instruction":"The More icon opens actions that do not fit on the current screen.","practice_prompt":"Choose More to look for actions such as Print, Share, Move, or Delete."},
        {"id":"refresh-page","order":7,"icon_id":"refresh","heading":"Load current information again","instruction":"The Refresh icon reloads a page or updates the information shown.","practice_prompt":"Choose Refresh when a page looks outdated or did not finish loading."},
        {"id":"close-item","order":8,"icon_id":"close","heading":"Dismiss a window or message","instruction":"The Close icon dismisses a screen, window, menu, or message.","practice_prompt":"Choose Close when you are finished with a pop-up."}
      ]
    },
    {
      "id": "work-with-files",
      "order": 2,
      "title": "Work With Files",
      "summary": "Follow the common actions used to create, organize, save, transfer, and remove files.",
      "estimated_minutes": 11,
      "completion_message": "You can now recognize the main icons used to create, store, transfer, share, and remove files.",
      "steps": [
        {"id":"add-item","order":1,"icon_id":"add","heading":"Create something new","instruction":"The Add icon begins a new item such as a file, contact, event, or tab.","practice_prompt":"Choose Add to begin creating a new item."},
        {"id":"edit-item","order":2,"icon_id":"edit","heading":"Change an existing item","instruction":"The Edit icon lets you revise information that already exists.","practice_prompt":"Choose Edit before changing a note, contact, photograph, or document."},
        {"id":"save-work","order":3,"icon_id":"save","heading":"Keep your changes","instruction":"The Save icon stores the current version of your work.","practice_prompt":"Choose Save after making changes you want to keep."},
        {"id":"open-folder","order":4,"icon_id":"folder","heading":"Open a container for files","instruction":"The Folder icon contains files and may also contain other folders.","practice_prompt":"Choose Folder to browse organized documents or photographs."},
        {"id":"open-document","order":5,"icon_id":"document","heading":"Recognize a document","instruction":"The Document icon represents a file containing text or other information.","practice_prompt":"Choose Document when you want to open or review a written file."},
        {"id":"download-file","order":6,"icon_id":"download","heading":"Bring a file onto your device","instruction":"The Download icon saves a file from a website or service onto your device.","practice_prompt":"Choose Download to keep a trusted file on your device."},
        {"id":"upload-file","order":7,"icon_id":"upload","heading":"Send a file from your device","instruction":"The Upload icon sends a local file into an app, website, or cloud service.","practice_prompt":"Choose Upload when a trusted website asks you to provide a file."},
        {"id":"attach-file","order":8,"icon_id":"attach","heading":"Include a file with a message","instruction":"The Attach icon adds a document or photograph to a message or form.","practice_prompt":"Choose Attach to include a file with an email."},
        {"id":"share-item","order":9,"icon_id":"share","heading":"Send a copy or link","instruction":"The Share icon sends an item or link to another person or app.","practice_prompt":"Choose Share after confirming the item and recipient."},
        {"id":"print-item","order":10,"icon_id":"print","heading":"Create a paper copy","instruction":"The Print icon sends a document or picture to a selected printer.","practice_prompt":"Choose Print after checking the printer, pages, and number of copies."},
        {"id":"delete-item","order":11,"icon_id":"delete","heading":"Remove an item","instruction":"The Delete icon removes the selected item and may be difficult to undo.","practice_prompt":"Choose Delete only after confirming that the correct item is selected."}
      ]
    },
    {
      "id": "communicate-and-use-media",
      "order": 3,
      "title": "Communicate and Use Media",
      "summary": "Recognize the controls used for calls, messages, photographs, sound, and playback.",
      "estimated_minutes": 10,
      "completion_message": "You can now identify the common icons used for communication, recording, sound, and media playback.",
      "steps": [
        {"id":"find-contact","order":1,"icon_id":"contacts","heading":"Find a saved person","instruction":"The Contacts icon opens saved names, numbers, and contact details.","practice_prompt":"Choose Contacts before calling or messaging a saved person."},
        {"id":"check-calendar","order":2,"icon_id":"calendar","heading":"Review a date or appointment","instruction":"The Calendar icon shows dates, appointments, reminders, and scheduled events.","practice_prompt":"Choose Calendar to check an appointment or create an event."},
        {"id":"make-call","order":3,"icon_id":"phone","heading":"Start a call","instruction":"The Phone icon starts or represents a telephone or internet call.","practice_prompt":"Choose Phone to call a confirmed contact."},
        {"id":"open-message","order":4,"icon_id":"message","heading":"Open a conversation","instruction":"The Message icon opens text messages, chat, or another conversation.","practice_prompt":"Choose Message to read or write a text response."},
        {"id":"send-message","order":5,"icon_id":"send","heading":"Deliver the message","instruction":"The Send icon delivers a message, email, form, or file.","practice_prompt":"Choose Send only after reviewing the recipient and attachments."},
        {"id":"use-camera","order":6,"icon_id":"camera","heading":"Take or add a picture","instruction":"The Camera icon opens the camera or adds a photograph or video.","practice_prompt":"Choose Camera for a picture, video call, or document scan."},
        {"id":"use-microphone","order":7,"icon_id":"microphone","heading":"Use your voice","instruction":"The Microphone icon begins voice input, recording, or speech-to-text.","practice_prompt":"Choose Microphone to dictate, record, or speak a search."},
        {"id":"adjust-volume","order":8,"icon_id":"volume","heading":"Control sound level","instruction":"The Volume icon makes sound louder, quieter, or muted.","practice_prompt":"Choose Volume before playing media when you need to check the sound level."},
        {"id":"play-media","order":9,"icon_id":"play","heading":"Start media","instruction":"The Play icon starts a video, recording, song, or animation.","practice_prompt":"Choose Play when you are ready to watch or listen."},
        {"id":"pause-media","order":10,"icon_id":"pause","heading":"Temporarily hold your place","instruction":"The Pause icon temporarily stops media while keeping your place.","practice_prompt":"Choose Pause when you plan to continue the same media shortly."},
        {"id":"stop-media","order":11,"icon_id":"stop","heading":"End playback or recording","instruction":"The Stop icon ends playback, recording, or another active process.","practice_prompt":"Choose Stop when you are finished with playback or recording."}
      ]
    },
    {
      "id": "stay-safe-and-connected",
      "order": 4,
      "title": "Stay Safe and Connected",
      "summary": "Learn the icons that manage device connections, permissions, notices, and safer decisions.",
      "estimated_minutes": 11,
      "completion_message": "You can now recognize common connection, permission, information, and safety icons.",
      "steps": [
        {"id":"open-settings","order":1,"icon_id":"settings","heading":"Control how the device works","instruction":"The Settings icon opens controls for privacy, sound, display, notifications, and accounts.","practice_prompt":"Choose Settings when you need to change one device or app option."},
        {"id":"review-notifications","order":2,"icon_id":"notifications","heading":"Review alerts calmly","instruction":"The Notifications icon shows alerts, reminders, and recent activity.","practice_prompt":"Choose Notifications to review an alert before deciding whether it needs action."},
        {"id":"connect-wifi","order":3,"icon_id":"wifi","heading":"Manage wireless internet","instruction":"The Wi-Fi icon shows or manages a wireless internet connection.","practice_prompt":"Choose Wi-Fi to check or change the current network connection."},
        {"id":"connect-bluetooth","order":4,"icon_id":"bluetooth","heading":"Connect a nearby device","instruction":"The Bluetooth icon pairs trusted nearby headphones, keyboards, cars, and other devices.","practice_prompt":"Choose Bluetooth after confirming the nearby device name."},
        {"id":"check-lock","order":5,"icon_id":"lock","heading":"Notice protected access","instruction":"The Lock icon indicates security, privacy, or an encrypted connection.","practice_prompt":"Choose the Lock for security information, while remembering it does not prove a website is honest."},
        {"id":"control-view","order":6,"icon_id":"view","heading":"Reveal or preview content","instruction":"The View icon shows hidden content or opens a preview.","practice_prompt":"Choose View to check hidden text, then hide sensitive information again."},
        {"id":"pause-at-warning","order":7,"icon_id":"warning","heading":"Pause before continuing","instruction":"The Warning icon signals that something needs attention before you act.","practice_prompt":"Choose Warning as your cue to stop, read, and verify."},
        {"id":"open-help","order":8,"icon_id":"help","heading":"Find trusted guidance","instruction":"The Help icon opens instructions, support information, or common answers.","practice_prompt":"Choose Help inside the official app or website when you need guidance."},
        {"id":"read-information","order":9,"icon_id":"information","heading":"Read additional details","instruction":"The Information icon explains an item, setting, or situation.","practice_prompt":"Choose Information to learn more before making a decision."},
        {"id":"review-location","order":10,"icon_id":"location","heading":"Manage location use","instruction":"The Location icon shows a place or indicates that an app may use your location.","practice_prompt":"Choose Location for maps or directions and allow access only when needed."}
      ]
    }
  ]
}
'@

        Write-Utf8File -Path $LessonDataPath -Content $LessonDataContent
    }
    else {
        Write-Status -Level 'INFO' -Message 'ValidateOnly mode selected. File generation was skipped.'
    }

    $Metrics = Test-LessonData `
        -IconDataPath $IconDataPath `
        -LessonDataPath $LessonDataPath

    Write-Section -Text 'Phase 3A Execution Metrics'
    Write-Metric -Name 'Icon library records' -Value $Metrics.IconCount
    Write-Metric -Name 'Lesson records' -Value $Metrics.LessonCount
    Write-Metric -Name 'Lesson steps' -Value $Metrics.StepCount
    Write-Metric -Name 'Unique referenced icons' -Value $Metrics.UniqueReferencedIconCount
    Write-Metric -Name 'Unreferenced icons' -Value $Metrics.UnreferencedIconCount
    Write-Metric -Name 'Created files' -Value $Script:CreatedFiles
    Write-Metric -Name 'Replaced files' -Value $Script:ReplacedFiles

    Write-Banner -Text 'TECHSAVVYSAGE ICON GUIDE PHASE 3A COMPLETE'
    Write-Status `
        -Level 'PASS' `
        -Message ('Operating mode {0} completed successfully.' -f $OperatingMode)
}
catch {
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host 'TECHSAVVYSAGE ICON GUIDE PHASE 3A ERROR' -ForegroundColor Red
    Write-Host ('=' * 76) -ForegroundColor Red
    Write-Host ('Message     : {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Line number : {0}' -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor Red
    Write-Host ''
    exit 1
}
