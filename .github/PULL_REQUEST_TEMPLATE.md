## Change

Describe the incorrect behavior or missing engineering guidance and the narrow
change made.

## Evidence

- FFmpeg version and build:
- Platform and shell:
- Fixture or sanitized input probe:
- Expected result:
- Actual validated result:

## Checklist

- [ ] Commands use explicit stream and filter-output mapping where needed.
- [ ] Re-encoding, stream loss, timestamp, color, audio, and overwrite behavior are stated.
- [ ] Performance, quality, hardware, and compatibility claims include reproducible evidence.
- [ ] Documentation, executable checks, and `CHANGELOG.md` were updated together.
- [ ] `scripts/validate-docs.sh` passes.
- [ ] `scripts/test-repaired-recipes.sh` passes on FFmpeg 8.1.2, or the manual/hardware-only reason is documented.
