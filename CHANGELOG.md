# Changelog
All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - 2026-05-10
### Fixed
- Originals no longer moved — only exact SHA256 duplicates are moved.
- Original file path now shown in log and CSV report.
- Checksum cache now loads correctly as hashtable (was breaking re-scans).
- Path joining on Windows no longer produces double drive-letter paths.
- GUI timer and status bar now update correctly during scan (scope fix).

### Changed
- Removed SelectionMode parameter — tool always keeps the first file found.
- GUI selection mode dropdown replaced with Dry Run checkbox.

### Added
- Splash screen with branding on GUI startup.
- Context-sensitive help in GUI status bar.
- Live MM:SS timer in GUI next to Run Scan button.
- Scan duration logged at end of each run with duplicate summary.
- Custom ICO icon generator (no ImageMagick required).
- Uninstall script (Uninstall-DPT.ps1).

## [1.0.0] - 2026-05-08
### Added
- Initial release of Duplicate Photo Tool.
- Multi-threaded hashing engine.
- SHA256 checksum caching system.
- Duplicate selection modes (First, Newest, Largest).
- CSV reporting.
- Logging levels (INFO, WARN, ERROR).
- WPF GUI launcher.
- Scheduled Task wrapper.
- Full documentation and tests.
