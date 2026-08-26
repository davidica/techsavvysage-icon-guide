# TechSavvySage Icon Guide v0.3.2 Release Notes

**Release date:** August 26, 2026
**Release status:** Stable Release Candidate

## Summary

Phase 3 introduces structured, accessible guided lessons across the existing 40-icon library. The release was built incrementally and validated after each checkpoint.

## Phase 3 checkpoints

- `8d8ff83` — Added four lesson data records and validated 40 unique icon references.
- `648094d` — Added the read-only four-lesson catalog and previews.
- `55b8203` — Added one-step-at-a-time guided progression and session completion.
- `57c44fa` — Added browser-only completion, last-step resume, completed indicators, and protected reset.

## Added

- Four guided lessons containing 40 total icon steps.
- Lesson previews with duration and step counts.
- Start, Previous, Next, Finish, and return-to-catalog controls.
- Step progress text and progress bar.
- Session completion messages.
- Browser-only last-step resume.
- Persistent Completed and In progress indicators.
- Review mode for completed lessons without clearing completion.
- Confirmation-protected lesson-progress reset.

## Preserved

- Learn, Practice, and Saved for Review modes.
- All 40 icon definitions and SVG renderings.
- Untimed randomized practice.
- Read-aloud support.
- Standard, Large, and Extra Large text.
- High contrast and reduced-motion behavior.
- Installable and offline-capable delivery.
- Network-first deployment hardening.

## Data and privacy

Phase 3 adds no account, analytics, cloud synchronization, or personally identifiable information collection. Lesson progress is added to the existing browser storage record. Resetting lesson progress does not clear other learning data or display preferences.

## Release boundaries

- Progress is specific to the current browser and device.
- Clearing browser site data removes local progress.
- Cross-device synchronization is not included.
- Phase 3 does not add scored lesson assessments; Practice remains the assessment mode.

## Release control

Complete the Phase 3 regression and accessibility checklist, verify the live GitHub Pages deployment, commit and push the closeout artifacts, then create tag `v0.3.2`.
