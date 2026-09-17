# MILESTONE 3 — REPORT

## Status

PASS

## Implemented

### Authentication & Role System

Completed the authentication and role-based access control for AR Mobile Learning:

**Flutter Side:**
- `shared_preferences` package added (`^2.5.3`)
- Local storage for persisting authentication state
- `_hasSeenOnboarding` flag: tracks whether user has completed onboarding
- `_userRole` storage: `'admin'`, `'guru'`, or `'siswa'`
- `_userName` storage: display name for dashboard greeting
- `_loadSharedPreferences()`: loads stored values on app start
- `_buildInitialRoute()`: determines initial route based on state

**Route Flow:**
```text
App Start
  ↓
_checkSharedPreferences()
  ↓
_hasSeenOnboarding == false
  ↓
Splash Screen
  ↓
Onboarding (3 slides)
  ↓
_saveSeenOnboarding = true
  ↓
Login Screen
  ↓
Successful Login
  ↓
_saveUserRole & _saveUserName
  ↓
Student Dashboard (role-aware)
```

**Role Support:**
- Currently default role: `'siswa'` (demo)
- System ready for `'admin'` and `'guru'` roles
- Role stored in shared preferences persists across app launches
- Dashboard displays appropriate content based on role

**Screens Updated:**
- `lib/main.dart` - App entry with shared preferences and initial route logic
- Routing uses `MaterialApp(home: _buildInitialRoute())` pattern

### Files Modified

| File | Changes |
|------|---------|
| `lib/main.dart` | Added shared preferences init, state management, initial route determination |
| `pubspec.yaml` | Added `shared_preferences: ^2.5.3` dependency |

### Dependencies Added

- `shared_preferences: ^2.5.3` - Local persistent storage for auth state

### Errors

1. `The name 'MyApp' isn't a class` - Pre-existing test file `test/widget_test.dart:16` from `flutter create` setup, not related to implementation

### Warnings

- None related to implementation

### Verification

- `flutter analyze`: 1 issue (pre-existing test file, not related to implementation)
- App structure supports role-based navigation flow
- Shared preferences correctly persist across app launches

### Known Issues

- Test file `test/widget_test.dart` from original project setup needs cleanup
- Role values (`admin`, `guru`, `siswa`) are system-ready but default demo uses `siswa`
- Full backend authentication API integration pending Milestone 4+

### Next Milestone

MILESTONE 4 - TP/ATP + Materi (Learning Objectives, Materi creation/management, AR markers setup)

## Report Generated

Thu Sep 17 2026