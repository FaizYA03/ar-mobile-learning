\# AR Mobile Learning - Development Rules



\## Project



This project is an AR Mobile Learning application for Informatics.



Architecture:



\- frontend = Flutter/Dart

\- backend = Laravel/PHP

\- database = MySQL

\- communication = REST API

\- authentication = token-based API authentication

\- AR = real marker detection/tracking + 3D model rendering



Project structure:



frontend/

backend/

docs/



\---



\# GENERAL RULES



Before modifying code:



1\. Inspect the relevant existing files.

2\. Understand the current architecture.

3\. Do not create duplicate services, models, providers, controllers, or utilities.

4\. Reuse existing code when appropriate.

5\. Do not perform unnecessary refactoring.

6\. Do not install dependencies unless necessary.

7\. Explain why a new dependency is required.

8\. Keep frontend and backend separated.

9\. Never hardcode secrets.

10\. Never claim a feature is complete without testing it.



\---



\# FLUTTER RULES



Use:



\- Dart

\- Flutter

\- Material 3

\- Dio for HTTP (`api_client.dart`) + `package:http` (`api_service.dart`) — saat ini masih dua HTTP client; konsolidasi tercatat di `PROJECT_STATUS_REPORT.md`

\- Flutter Secure Storage for sensitive authentication data

\- SharedPreferences for non-sensitive local preferences when needed

**ARSITEKTUR TARGET — BELUM DIIMPLEMENTASI (jangan dianggap sudah ada):**

\- **Riverpod** untuk state management. Saat ini proyek memakai `StatefulWidget` + `setState`, dan `flutter_riverpod` **tidak ada** di `pubspec.yaml`.

\- **GoRouter** untuk routing. Saat ini memakai `Navigator` + map `routes:` pada `MaterialApp`, dan `go_router` **tidak ada** di `pubspec.yaml`.

\- Struktur `app/ core/ features/ shared/`. Saat ini `screens/ services/ models/ widgets/ config/ core/debug/`.

Sebelum menulis kode baru, periksa `pubspec.yaml`. Jangan memakai API Riverpod/GoRouter
kecuali dependensi itu benar-benar ditambahkan. Jika hanya membuat perubahan kecil,
ikuti pola yang sudah dipakai file surroundings agar tidak menambah CAMPURAN gaya.



Prefer feature-based architecture.



Example:



lib/

├── app/

├── core/

├── features/

└── shared/



Do not put all application logic inside widgets.



Widgets should remain focused on UI.



Business logic belongs in appropriate controllers/notifiers/services.



API communication must be separated from UI.



\---



\# LARAVEL RULES



Backend must be a REST API.



Use:



\- Controllers

\- Models

\- Form Requests

\- API Resources when useful

\- Policies/authorization where appropriate

\- Migrations

\- Seeders

\- Feature tests



Validate incoming requests.



Never trust role information sent by the client.



Authorization must be enforced on the backend.



\---



\# AUTHENTICATION



There are three application roles:



\- admin

\- guru

\- siswa



Backend is the source of truth for:



\- authentication

\- authorization

\- validation

\- quiz scoring

\- user roles



Flutter must not be trusted to enforce permissions.



\---



\# AR RULES



The AR implementation must be real.



Do NOT implement a fake AR screen consisting only of:



\- camera preview

\- static overlay

\- manually typed marker IDs



Required pipeline:



Camera

→ marker detection/tracking

→ marker identification

→ backend/local mapping

→ associated 3D model

→ model loading

→ AR rendering



Before selecting an AR dependency:



1\. Check current Flutter compatibility.

2\. Check Android compatibility.

3\. Check package maintenance.

4\. Check whether marker/image tracking is actually supported.

5\. Prefer stable and documented solutions.



Do not blindly copy old tutorials.



\---



\# MARKER SYSTEM



The student should NOT manually enter a marker ID.



Expected flow:



1\. Open AR scanner.

2\. Camera starts.

3\. Marker is detected.

4\. Marker identity is determined.

5\. Application retrieves the associated 3D object.

6\. 3D object loads.

7\. Object appears in AR.



\---



\# API RULES



API responses should be consistent.



Success example:



{

&#x20; "success": true,

&#x20; "message": "Success",

&#x20; "data": {}

}



Error example:



{

&#x20; "success": false,

&#x20; "message": "Validation failed",

&#x20; "errors": {}

}



Do not randomly change API response structures.



\---



\# NETWORKING



Never hardcode:



127.0.0.1



as the API address inside production application code.



Use environment/configuration.



Remember:



Android emulator:

10.0.2.2



Physical Android device:

laptop LAN IP



\---



\# DATABASE



Avoid unnecessary varchar(255).



Choose effective column sizes based on actual data.



Primary and foreign keys must have explicit meaningful names.



Use migrations as the source of truth.



\---



\# TESTING



After significant changes run appropriate checks.



Flutter:



dart format .

flutter analyze

flutter test



Laravel:



php artisan test



For API:



Test using Postman/Bruno or equivalent.



For AR:



Test on a physical Android device.



\---



\# AI CODING BEHAVIOR



Do not modify many unrelated files at once.



Work milestone by milestone.



For each task:



1\. Inspect.

2\. Plan.

3\. Implement.

4\. Format.

5\. Analyze.

6\. Test.

7\. Report changed files.

8\. Report remaining problems.



If an error occurs:



Do not hide it.



Find the root cause.



Do not disable validation or remove tests merely to make the error disappear.



\---



\# PROJECT MILESTONES



Milestone 0:

Environment audit



Milestone 1:

Project foundation



Milestone 2:

Laravel database/API foundation



Milestone 3:

Flutter authentication



Milestone 4:

Materials



Milestone 5:

Quiz



Milestone 6:

3D objects



Milestone 7:

AR proof of concept



Milestone 8:

Marker management



Milestone 9:

Full integration



Milestone 10:

Testing



Milestone 11:

Performance optimization



Milestone 12:

Release



Do not jump to later milestones unless explicitly requested.



\---



\# CURRENT DEVELOPMENT PRIORITY



The current goal is to build the foundation first.



Do NOT immediately implement the entire application.



Start by auditing the environment and creating the project structure.

