# Manual Device Testing Checklist

These checks require a physical Android device or emulator and cannot be automated.

## Installation & Launch

- [ ] Install APK from file manager ("unknown sources" enabled)
- [ ] App icon appears in launcher with correct label "RepPilot"
- [ ] App opens to home dashboard without crashes
- [ ] First launch seeds default exercises and foods

## Workout Flow (Critical Path)

- [ ] Create a new routine with 3+ exercises
- [ ] Assign routine to a day of the week
- [ ] Start a live workout session from the dashboard
- [ ] Log sets with varying reps and weights
- [ ] Rest timer starts and counts down correctly
- [ ] Complete the workout — session saved with timestamp
- [ ] Session appears in workout history

## Session Recovery

- [ ] Start a workout session
- [ ] Force-close the app (swipe from recents or `adb shell am force-stop`)
- [ ] Reopen the app — active session is detected and can be resumed
- [ ] Complete the resumed session normally

## Progressive Overload

- [ ] Complete the same routine 2-3 times with consistent performance
- [ ] Check the progress dashboard for overload suggestions
- [ ] Suggestions show clear explanations for why they recommend changes

## Body Weight

- [ ] Log a body weight entry for today
- [ ] Log entries for several days
- [ ] Weight chart displays correctly with proper date axis
- [ ] Edit an existing weight entry
- [ ] Delete a weight entry (with confirmation)

## Diet & Nutrition

- [ ] Log a meal with calories and macros
- [ ] Search for a food from the default food database
- [ ] Log water intake
- [ ] Daily totals update correctly on the diet screen
- [ ] Edit and delete food entries

## Backup & Restore

- [ ] Export a full JSON backup — file picker opens, file saves
- [ ] Export CSV for weight, food, and workout data
- [ ] Import the JSON backup on a fresh install — all data restored
- [ ] Verify record counts match after restore

## Themes & Display

- [ ] Switch between dark, light, and system themes
- [ ] Theme persists after app restart
- [ ] UI is legible in both themes (no invisible text, icons, or controls)
- [ ] Screens render correctly on small (5") and large (6.7") displays
- [ ] Landscape orientation does not crash (even if layout is portrait-optimized)

## Edge Cases

- [ ] App handles zero data gracefully (empty states for all screens)
- [ ] Very long exercise names don't overflow or crash
- [ ] Entering 0 reps or 0 weight is handled gracefully
- [ ] Date boundaries: log data near midnight, verify it appears on the correct day
- [ ] Back button navigation works correctly from all screens
- [ ] Keyboard dismiss on text fields works properly

## Performance

- [ ] App launches in under 3 seconds on mid-range device
- [ ] Scrolling through exercise library (58+ items) is smooth
- [ ] Charts render without lag
- [ ] After 100+ workout sessions, the app remains responsive

## Accessibility

- [ ] TalkBack reads screen content correctly
- [ ] Touch targets are at least 48×48 dp
- [ ] Sufficient color contrast in both themes
- [ ] Font scaling (system large text) does not break layouts
