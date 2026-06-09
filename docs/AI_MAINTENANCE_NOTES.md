# RockyDex AI Maintenance Notes

This file gives future AI coding agents the project-specific context needed for
reader performance fixes and release/version updates.

## Reader horizontal mode

The horizontal reader lives in:

- `mobile/lib/features/reader/presentation/screens/reader_screen.dart`

Known performance pitfalls:

- Do not place full-screen `GestureDetector` overlays above `PhotoViewGallery`.
  They compete in Flutter's gesture arena and make horizontal drags feel late.
- Do not precache every image in a chapter while the user is reading. Large
  image decode/network work can happen during page transitions and cause jank.
  Prefer precaching only the current page, one page behind, and a small number
  of pages ahead.
- Do not save reading history on every drag/frame. Queue or debounce progress
  saves, and flush immediately only when leaving the chapter or switching
  chapters.
- `BackdropFilter` overlays are expensive over moving full-screen images. Keep
  them hidden while the user is dragging horizontally, or use simple translucent
  containers for performance-critical reader UI.
- `PhotoViewGallery.builder` should use `wantKeepAlive`, `gaplessPlayback`, and
  `allowImplicitScrolling` for smoother adjacent-page swipes.

Current behavior:

- Page taps are handled by `PhotoViewGalleryPageOptions.onTapUp`.
- Left/right edge taps still move previous/next page or chapter.
- Center taps toggle reader UI.
- Horizontal drag start hides reader UI so blur overlays do not repaint during
  the swipe.
- Progress saves are debounced and flushed on dispose/chapter navigation.

## Backend sync path for reader smoothness

The reader writes progress through:

- Mobile: `mobile/lib/features/library/data/library_repository.dart`
- Backend handler: `backend/internal/interfaces/http/library_handler.go`
- Backend service: `backend/internal/application/library_service.go`
- Backend repository: `backend/internal/infrastructure/repository/pg_history_repo.go`

Keep this path lightweight. The app may save progress while a user is actively
reading, so backend writes should avoid read-before-write patterns. The history
repository uses an update-first save so existing rows are updated in one DB
query, then inserted only when missing.

Useful DB indexes are declared on the domain models:

- `idx_histories_user_comic` for progress updates and per-comic history lookup.
- `idx_histories_user_last_read` for history list ordering.
- `idx_favorites_user_comic` for favorite checks/removes.
- `idx_favorites_user_created` for favorite list ordering.

## OTruyen chapter direction

OTruyen and MangaDex may expose chapter lists in different orders. Do not hard
code `currentIdx - 1` as next or `currentIdx + 1` as previous without checking
chapter number order.

Use the helper methods in `reader_screen.dart`:

- `_getNextChapterIndex`
- `_getPreviousChapterIndex`
- `_isChapterListAscending`

OTruyen chapter lists are normalized in:

- `mobile/lib/features/comic/data/comic_repository.dart`

## Version bump checklist

For each app release:

1. Update `mobile/pubspec.yaml`.
2. Update `AppVersionService.fallbackVersion` in
   `mobile/lib/core/services/app_version_service.dart`.
3. Splash and Profile should read display version through
   `AppVersionService.displayVersionLabel()` instead of hardcoded strings.
4. Run `dart format` on touched Dart files.
5. Run `flutter analyze`.
6. Build APK with `flutter build apk --release` before tagging/releasing.

## Release workflow

The GitHub release workflow is:

- `.github/workflows/build_apk.yml`

Creating a GitHub Release for tag `vX.Y.Z` triggers the workflow to build and
upload `rockydex-vX.Y.Z.apk`.
