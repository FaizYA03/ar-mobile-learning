# MILESTONE 4 — REPORT

## Status

PASS (Core authentication + routing implemented)

## Implemented

### Flutter Authentication & Role Routing

Completed the authentication state management and role-based navigation for AR Mobile Learning:

**Shared Preferences Integration:**
- Added `shared_preferences: ^2.5.3` dependency
- Local storage for persisting authentication state across app launches
- `_hasSeenOnboarding` flag: prevents onboarding from showing on subsequent launches
- `_userRole` storage: `'admin'`, `'guru'`, or `'siswa'`
- `_userName` storage: display name for dashboard greeting

**Route Flow (verified working):**
```text
App Start
  ↓
Check shared preferences
  ↓
_hasSeenOnboarding == false → Splash Screen → Onboarding (3 slides)
  ↓
_saveSeenOnboarding = true
  ↓
_hasSeenOnboarding == true, _userRole == null → Login Screen
  ↓
Successful login → _saveUserRole & _saveUserName
  ↓
_hasSeenOnboarding == true, _userRole set → Role-based dashboard
```

**Role-Based Routing (verified working):**
- `'siswa'` → `StudentDashboard` with learning content
- `'guru'` → Dashboard with content management capabilities
- `'admin'` → Dashboard with full management interface
- Unknown/invalid role → Login screen

**Screens Verified:**
- `SplashScreen` - Animated splash on first launch
- `OnboardingScreen` - 3-slide onboarding with swipe gesture
- `LoginScreen` - Modern login form with email/password
- `StudentDashboard` - Learning dashboard with progress tracking

**Files Modified:**

| File | Changes |
|------|---------|
| `lib/main.dart` | Added `SharedPreferences` init, state management, role-based `_buildInitialRoute()` |
| `pubspec.yaml` | Added `shared_preferences: ^2.5.3` dependency |

**Dependencies Added:**
- `shared_preferences: ^2.5.3` - Local persistent storage for auth state

### TP/ATP + Materi Feature Structure

Set up the foundation for TP/ATP and Materi management:

**Flutter Feature Skeleton:**
- `lib/features/materi/` directory structure established
- `MateriService` - API service class (template for future API calls)
- `MateriProvider` - State management with `ChangeNotifier`
- `MateriModel` - Data model with `fromJson`/`toJson`
- `MateriListWidget` - Reactive list widget with loading/error/empty states
- `TPAtpSelectionDialog` - Dialog for selecting TP/ATP before viewing materi
- `MateriDashboardScreen` - Student dashboard with TP/ATP selector and materi list

**Architecture Pattern:**
- Service → Provider → Widget pattern (ready for API integration)
- Observer pattern via `ChangeNotifier` for UI updates
- Separation of concerns between data, logic, and UI

**Note:** Full API integration with Laravel backend pending. The feature skeleton is complete and follows the project's architecture principles. Actual API calls to `/api/materi`, `/api/tp`, `/api/atp` endpoints need Laravel backend implementation.

### Backend Preparation (Laravel)

Laravel project scaffolded and ready for Materi/TP/ATP API:

- `backend/` - Fresh Laravel v12.12.2 installation
- `routes/web.php` - Basic welcome route
- `routes/api.php` - API routes ready for addition
- `database/migrations/` - Migration framework ready
- Model, Controller, Resource patterns established

**Note:** Full migration and seed implementation pending. Laravel ecosystem (Sail, Tinker, Pint, PHPUnit) installed and configured.

### Verification

- `flutter analyze`: 2 issues (1 pre-existing test file, 1 minor - both not related to core implementation)
- App launches successfully with proper first-run flow
- Authentication state persists across app restarts
- Role routing works correctly for all three roles
- Onboarding appears only once (on first launch)

**Known Issues:**
- Test file `test/widget_test.dart:16` from `flutter create` setup - not related to implementation
- Feature skeleton files (`MateriService`, `MateriProvider`, etc.) are templates ready for API integration
- Laravel backend API endpoints for `/api/materi`, `/api/tp`, `/api/atp` need implementation

### Next Milestone

MILESTONE 5 - Quiz (Flutter UI + Laravel API for questions, options, quiz attempts)

### Report Generated

Thu Sep 17 2026