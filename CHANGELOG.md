# Changelog

## 1.1.0 — Real API migration, UI fix pass, release-readiness pass

### Real backend integration
- Replaced the mock/Hive-backed network layer with a real `Dio`-based client against the live `crm.trudealsrealty.com` API.
- JWT bearer auth: secure token storage, login/logout, and automatic forced logout on session expiry (401).
- Rewrote all entities and repositories to match the live API's schemas (contacts, stages, users, templates, workflows, callbacks, enrollments, notifications, vendor orders).

### Feature fixes (previously dead/stubbed UI)
- Contact create/edit/delete, with validation and diff-based edit PATCHes.
- Contact drawer: stage chooser (role-aware), transfer, tag add/remove, callback scheduling, message compose + send + log-reply, vendor order chips, security-log notes.
- Trash: real list + restore.
- Settings: stage add/rename/reorder/remove, seat create/edit.
- Automations: full workflow editor (trigger + per-step config), real create/update/delete, real active-enrollment counts with stop/run-next.
- Dashboard: accurate stats, resolved owner names, populated follow-ups and recent activity.
- Calendar: real date-range querying.
- Notifications bell: real data instead of static placeholders.
- JSON export/import (super admin only), via device share sheet / file picker.

### Architecture
- Contacts/stages/seats now live in one shared, app-lifetime `PipelineCubit` instead of each screen loading its own disconnected copy — fixes stale data across tabs after any create/edit/move/transfer.
- Reactive `StreamBuilder` wiring for screens reached via `Navigator.push`/dialogs, so in-flight data loads are reflected once they arrive.
- Consistent error+retry states across list screens instead of silently showing "no data" on a failed load.

### Release readiness
- Custom app icon and launch screen branding (previously the default Flutter template icon).
- Encrypted token storage on Android.
- Dependencies updated to latest mutually-compatible stable versions.

## 1.0.0 — Initial scaffold
- Original clean-architecture scaffold with a mock/Hive-backed network layer.
