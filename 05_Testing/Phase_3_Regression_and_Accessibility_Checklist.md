# Phase 3 Regression and Accessibility Checklist

**Release:** v0.3.2
**Date:** August 26, 2026
**Tester:** ____________________
**Browser and version:** ____________________
**Device:** ____________________

## Automated release gate

- [x] Icon data contains 40 unique records.
- [x] Lesson data contains four unique records.
- [x] Lesson data contains 40 valid icon references.
- [x] All 40 icon identifiers are represented by the lessons.
- [x] Phase 3A through Phase 3D builders are present.
- [x] Lesson catalog, runner, persistence, resume, completion, and reset markers are present.
- [x] Deployment update and reload markers are preserved.
- [x] Service-worker cache is v0.3.2.
- [x] Lesson data is included in offline assets.
- [x] No external progress-transmission mechanism was detected.
- [x] Phase 3E did not change runtime file hashes.

## Learn regression

- [ ] Learn opens as the default mode.
- [ ] Clearing search and selecting All categories displays 40 icons.
- [ ] Search finds icons by name, meaning, example, caution, and search terms.
- [ ] Category filtering works alone.
- [ ] Search and category filtering work together.
- [ ] Selecting an icon displays its SVG, name, meaning, example, devices, and caution.
- [ ] Read aloud works or reports that browser speech is unavailable.
- [ ] Save for Review adds and removes the selected icon.
- [ ] Practice this icon opens a one-icon practice session.

## Lessons catalog

- [ ] Lessons displays four cards in the defined order.
- [ ] Each card displays title, summary, duration, and step count.
- [ ] Selecting a card displays the correct preview.
- [ ] Start lesson opens Step 1 for a new lesson.
- [ ] Each displayed step uses the referenced icon from the 40-icon library.

## Guided progression

- [ ] The progress text and progress bar match the current step.
- [ ] Previous is disabled on Step 1.
- [ ] Next advances exactly one step.
- [ ] Previous returns exactly one step.
- [ ] Focus moves to the new step heading.
- [ ] Back to lesson choices exits without losing the current step.
- [ ] The final step displays Finish lesson.
- [ ] Finish lesson displays the defined completion message.
- [ ] Return to lesson choices works after completion.

## Persistence and reset

- [ ] Exiting an unfinished lesson displays In progress and the correct step.
- [ ] Reloading preserves the unfinished lesson step.
- [ ] Resume lesson opens the stored step.
- [ ] Completion displays a Completed indicator.
- [ ] Reloading preserves completion.
- [ ] Review lesson starts a completed lesson without clearing completion.
- [ ] Canceling Reset lesson progress preserves lesson data.
- [ ] Confirming Reset lesson progress clears all lesson indicators.
- [ ] Lesson reset does not clear explored, practiced, or saved-icon data.
- [ ] Lesson reset does not change text size or high contrast.

## Practice regression

- [ ] Practice offers 5, 10, 20, and all-icon sessions.
- [ ] Each question displays four choices.
- [ ] Questions and choices are randomized.
- [ ] Questions do not repeat within a session.
- [ ] Correct and supportive retry feedback display correctly.
- [ ] Results report completed and correct counts.
- [ ] Missed icons can be opened in review.

## Saved for Review regression

- [ ] Saved for Review displays only saved icons.
- [ ] An empty saved list explains that no icons are available.
- [ ] Search filters the saved list rather than all icons.
- [ ] Returning to Learn restores the complete library search scope.

## Accessibility

- [ ] All four modes can be completed using only a keyboard.
- [ ] Focus indicators remain visible.
- [ ] Lesson cards and icon choices have meaningful accessible names.
- [ ] Status and feedback updates are announced appropriately.
- [ ] Standard, Large, and Extra Large text remain usable.
- [ ] High contrast remains usable in every mode.
- [ ] Content remains usable at 200 percent zoom.
- [ ] Content remains usable at a 320-pixel viewport.
- [ ] Reduced-motion preference is honored.
- [ ] No activity imposes a timer.

## Offline, deployment, and browser coverage

- [ ] The online application loads the latest v0.3.2 release.
- [ ] A service-worker update may reload only once.
- [ ] The application loads offline after one successful online visit.
- [ ] Icons and lesson data remain available offline.
- [ ] Edge smoke test passes.
- [ ] Chrome smoke test passes.
- [ ] Safari or iOS smoke test passes when available.
- [ ] Android browser smoke test passes when available.
- [ ] Browser Console contains no red application errors.

## Privacy and release control

- [ ] No account or personally identifiable information is requested.
- [ ] Browser storage contains learning preferences and progress only.
- [ ] No learning or lesson progress is transmitted externally.
- [ ] Git working tree is clean before tagging.
- [ ] Local main and origin/main reference the same closeout commit.
- [ ] Live GitHub Pages smoke test passes after deployment.
- [ ] Release tag v0.3.2 is created only after all required checks pass.

## Release decision

- [ ] Approved for v0.3.2 release.

**Approver:** ____________________
**Approval date:** ____________________
**Notes:**
