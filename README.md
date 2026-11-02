# Planner

A personal study planner for iPhone. SwiftUI, iOS 17+, no account, no server, no dependencies.
Data lives in `planners.json` in the app's Documents folder.

## Run it on your iPhone (free Apple ID)

1. Open `Planner.xcodeproj` in Xcode 15 or newer.
2. Click the **Planner** project → target **Planner** → **Signing & Capabilities**.
   - Team: your Personal Team (add your Apple ID in Xcode → Settings → Accounts if needed).
   - Bundle Identifier: change `com.example.planner` to something unique, e.g. `com.yourname.planner`.
   - Do the same for the **PlannerTests** target (`com.yourname.planner.tests`).
3. Plug in the iPhone, pick it as the run destination, press **⌘R**.
4. First time only, on the phone: Settings → General → VPN & Device Management → trust your developer certificate.
   Settings → Privacy & Security → Developer Mode → On (the phone restarts).
5. Free signing expires after 7 days: just press ⌘R again to reinstall. Your data is kept.

Unit tests: **⌘U** (rollover, repeat expansion, segments, red-bar logic, reminders, seed, persistence).

## Files

| File | What it does |
|---|---|
| `Models.swift` | `Subject`, `Item`, `Planner` |
| `Logic.swift` | Pure helpers: `Day` date maths, `occurrences`, `rollover`, `tally`, `dueSoon`, `segments`, day grouping |
| `Format.swift` | English date/time strings |
| `Reminders.swift` | `planReminders` (pure) and `Notifier` (UserNotifications) |
| `Store.swift` | All state, saving, rollover, notification rebuilds, every mutation |
| `Seed.swift` | The bundled "Midterm Sprint" plan (55 tasks) as a JSON string |
| `Theme.swift` | Colour tokens, palette, scaled fonts, theme switching |
| `Views/…` | One file per screen, plus small shared pieces in `Components.swift` |

## What to check on the phone

**1. Data and storage**
- Tests pass with ⌘U.
- Add something, swipe the app away, reopen it: everything is still there.

**2. Planner list**
- A fresh install shows "No planners yet" and an outlined "Import Midterm Sprint (55 tasks)" button.
- The only other control is the black "＋ New planner" at the bottom. Nothing in the top-right, no footnote.
- Import: the "Midterm Sprint" row shows Nov 1 – Nov 10 and "0 of 55 done".
- New planner: Blank, Midterm plan (hidden once imported) and "Subjects from …" all work. Create closes the sheet.

**3. Planner screen and Day**
- The tab row reads Day · Week · Month · Progress, with a bold underline on the active tab. The black "Today" pill appears once you pick another day.
- Ribbon: one segment per task, done ones solid. Tap a day to select it. Swipe left or right to change week.
- Quick-add: type a title and press return. It appears under the chosen subject on the selected day, and the keyboard stays up.
- Tap a row to edit it. Long-press for Delete. The checkbox gives a light tap of haptic feedback.

**4. Week / Month / Progress**
- Counts match the Day tab. Tapping a week row or a month cell opens that day.

**5. Settings (sliders icon)**
- Renaming updates the title and the list right away. Auto / Light / Dark switches instantly, sheets included.
- Deleting a subject keeps its tasks under "No subject". Delete planner asks first, then returns to the list.

**6. Red bar and notifications**
- Add a Due date for tomorrow: the red bar shows and tapping it does nothing. Mark it done and the bar disappears.
- To test rollover: leave a task undone, set the phone's date to tomorrow, and reopen the app. The task is now on today with "↩ from …".
- Add a due item for tomorrow, set the clock to just before 8:00 AM and wait for "… is due tomorrow".

**7. Polish**
- Settings → Accessibility → Larger Text at max: rows grow and nothing overlaps.
- VoiceOver reads each row as "title, subject, due time, done / not done".
- Check both themes on every screen.

## Later (step 8)
Widgets (App Group), iCloud backup, export/import of `planners.json`, Korean localisation, App Store
(icon, screenshots, privacy: "Data Not Collected"; `PrivacyInfo.xcprivacy` is already included).
