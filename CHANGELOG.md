# Changelog


## [0.2.6] - 2026-10-26

### Added

- **TX protocol version and sequence number:** every UDP packet carries a sequence number.
- **Selectable rate for fast groups:** `input`, `gps`, `tires_dyn`, `gforce` and `susp`.
- **Crash safety:** stint log data is written to disk every second. If the game crashes, the stint CSV is kept so its data can be recovered.
- **Settings locked while logging:** channel groups and sampling rates settings are now locked while logging.

### Changed

- **One CSV per stint:** each stint is recorded to a single `log_<...>.csv` file instead of one CSV per lap.
- **TX packet format:** new format `APEX|<protocol>|<seq>|<group>|<rate>|<clock>|<sessionTimeLeft>|<values>` (with protocol number).
- **Stint logged files:** log values are written with 9 significant digits. This keeps every float32 value from CSP exact and makes log files about 27% smaller.
- **File names:** stint log CSV and log JSON names include the track id and car id, and use a full date-time tag.

### Fixed

- **Pause and replay:** channels are no longer sampled while the game is paused or a replay is active.


## [0.2] - 2026-08-13

### Added

- Lap logging to CSV files (per lap), with a JSON log per stint.
- Live telemetry streaming over UDP.
- 180+ channels in 12 groups, with group selection shared by LOG and TX.
- Apex HUD window with LOG and TX status, and blink states.
- Extended Controls buttons to toggle LOG and TX.
- Python buffer app for damper data.
- Car data and aeromap detection.
- Persistent settings.

[0.2.6]: https://github.com/fabetabilo/apex-logger/releases/tag/v0.2.6
[0.2]: https://github.com/fabetabilo/apex-logger/releases/tag/v0.2
