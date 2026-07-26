# Changelog

All notable handbook behavior changes are recorded here.

## Unreleased

### Corrected

- Made FFmpeg 8.1.2 the executable-example baseline.
- Corrected 120 fps to 30 fps time-lapse guidance to compress timestamps before
  frame-rate conversion.
- Replaced an invalid time-varying `atempo` expression with synchronized,
  segmented video and audio retiming.
- Replaced no-op and invalid normalization recipes with measured workflows.
- Corrected `quad`, `4.0`, `5.0`, and `5.1` channel-layout guidance.
- Replaced the slideshow `xfade` runtime variable with probed numeric offsets.
- Limited storyboard source thumbnails before tiling and made sprite/VTT page
  geometry consistent.
- Corrected subtitle offset guidance so subtitle cues, not video frames, move.
- Repaired all known broken internal links.

### Changed

- Replaced active `-vsync` examples with per-output `-fps_mode` behavior.
- Replaced active `-async` recommendations with diagnosed timestamp handling
  and `aresample=async=...` only where resampling is intended.
- Reduced the README to a versioned landing page; `docs/` is canonical.
- Added repository checks, deterministic smoke tests, contribution rules,
  security policy, and GitHub templates.
