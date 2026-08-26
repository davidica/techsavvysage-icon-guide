# TechSavvySage Icon Guide Phase 3 User Guide

**Release:** v0.3.2
**Status:** Stable Release Candidate
**Release date:** August 26, 2026

## Purpose

The TechSavvySage Icon Guide is an accessible, untimed learning utility for 40 common computer and mobile icons. Phase 3 adds four guided lessons while preserving Learn, Practice, Saved for Review, display personalization, read-aloud support, offline use, and browser-only privacy.

## Learning modes

### Learn

Search all 40 icons or filter by category. Select an icon to review its meaning, example, device context, and safety note. Search and category filters work together. For example, Bluetooth appears under Device rather than Communication.

### Lessons

Choose one of four guided lessons:

1. Find Your Way
2. Work With Files
3. Communicate and Use Media
4. Stay Safe and Connected

Preview the lesson, select **Start lesson**, and move through one icon step at a time. Use **Previous step**, **Next step**, **Finish lesson**, or **Back to lesson choices**. The progress bar shows the current step.

### Practice

Choose 5, 10, 20, or all 40 questions. Questions and four answer choices are randomized without repetition inside the session. Results identify missed icons for optional review.

### Saved for Review

Save an icon from Learn mode, then open Saved for Review to study that personal list. If the screen says `0 saved`, return to Learn and save at least one icon. Search in Saved for Review searches only the saved list, not all 40 icons.

## Lesson progress and resume

The application stores the last displayed step for an unfinished lesson in the current browser. An unfinished card shows **In progress** and its resume step. A completed card shows **Completed**. Select **Resume lesson** to continue or **Review lesson** to revisit a completed lesson without erasing completion.

Select **Reset lesson progress** to clear only guided-lesson status. Confirmation is required. This reset does not clear explored icons, practiced icons, the Saved for Review list, or display settings.

## Other controls

- **Clear learning data** clears explored, practiced, and saved-icon data after confirmation. It does not reset lesson progress or display settings.
- **Reset display settings** restores standard text and normal contrast.
- **Read explanation aloud** uses browser speech support when available.

## Accessibility

- No activity is timed.
- All primary controls support keyboard operation.
- Focus moves to each lesson-step heading as the step changes.
- Standard, Large, and Extra Large text are supported.
- High contrast and reduced-motion preferences are supported.
- Status changes are communicated through the page status region.

## Offline and updates

After one successful online visit, the application retains its core files for offline use. When online, it uses network-first loading so a newly deployed version replaces older cached content. A page may reload once when an updated service worker takes control.

## Privacy

The utility requires no account and sends no learning or lesson progress to an external service. Explored icons, practice status, saved icons, lesson progress, and display preferences stay in the current browser. Clearing browser site data removes this information.

## Troubleshooting

- If zero icons appear, confirm the active mode. Learn searches all icons; Saved for Review searches only saved icons.
- Clear the search field and select **All categories** to display all 40 icons.
- If a search and category conflict, zero matches is expected.
- If an update appears delayed, reload once and allow the service worker to refresh.
