# TechSavvySage Icon Guide Phase 4 User Guide

**Release:** v0.4.2

**Status:** Stable Release Candidate

**Release date:** August 26, 2026

## Purpose

The TechSavvySage Icon Guide is an accessible, untimed learning utility for 40 common computer and mobile icons. Phase 4 adds lesson knowledge checks, supportive missed-icon explanations, and targeted reinforcement while preserving Learn, Lessons, Practice, Saved for Review, display personalization, read-aloud support, offline use, and browser-only privacy.

## Lesson knowledge checks

Complete a guided lesson and select **Start knowledge check**. Each attempt presents five questions selected from that lesson's ten-question bank. Choose the meaning that matches the displayed icon. Each question provides immediate, supportive feedback and identifies the correct meaning when another answer is selected.

Knowledge checks are untimed. There is no penalty for retrying, and scores are not stored after the current page session.

## Review missed icons

After the fifth question, the results screen shows the number answered correctly. When one or more icons were missed, **Review missed icons** displays only those icons with their names, meanings, and plain-language examples. A perfect attempt does not display an unnecessary review list.

## Practice missed icons

Select **Practice missed icons** to move directly into the existing Practice mode using only the icons missed during the completed knowledge check as question targets. The missed targets are randomized. Existing Practice-mode answer choices, supportive feedback, and results remain in effect.

The targeted list exists only for the current session. Select **Lessons** at any time to return to the lesson choices.

## Other learning modes

- **Learn:** Search or filter all 40 icons and open detailed explanations.
- **Lessons:** Work through four guided lessons with browser-only resume and completion status.
- **Practice:** Choose 5, 10, 20, or all 40 questions for general practice.
- **Saved for Review:** Maintain a browser-local list of icons selected for later study.

## Accessibility

- No lesson, knowledge check, or practice activity is timed.
- Primary actions support keyboard operation.
- Question and completion headings receive focus as content changes.
- Feedback is announced through status and polite live regions.
- Controls use plain language and touch-friendly sizing.
- Standard, Large, and Extra Large text remain supported.
- High contrast and reduced-motion preferences remain supported.

## Offline use and updates

After one successful online visit, the application retains its core files, lesson data, and assessment data for offline use. Network-first loading and the `v0.4.2` service-worker cache allow a newly deployed version to replace older cached content.

## Privacy

The application requires no account and sends no learning, lesson, assessment, or practice result to an external service. Knowledge-check scores and missed-icon lists remain in memory for the current session only. Existing browser-local lesson progress and display preferences remain under the learner's control.

## Troubleshooting

- If **Start knowledge check** is not visible, finish or review the last step of a lesson.
- If **Practice missed icons** is not visible, the knowledge check contained no missed icons.
- If updated controls do not appear after deployment, reload once and allow the service worker to refresh.
- If icon or lesson content does not load, reconnect once so the offline cache can be established.
