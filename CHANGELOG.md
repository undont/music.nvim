# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Spotify AppleScript backend (`spotify_local`) for macOS — no API key or Spotify Premium required
- Automatic platform detection: Spotify uses AppleScript on macOS, Web API elsewhere
- `active_backend()` function on the backend module

### Changed
- Default `poll_interval` reduced from 2000ms to 1000ms for snappier track updates
- Artwork extraction now uses the active backend instead of hardcoding Apple Music

### Fixed
- Floating window crash on Neovim 0.12.0 (`Invalid buffer id` in `nvim_open_win`) caused by wiped scratch buffer not being recreated
- README `highlights.background` default was documented as `'NormalFloat'` but actual default is `'Normal'`
- README highlight example was misleading (suggested switching to the already-default value)
