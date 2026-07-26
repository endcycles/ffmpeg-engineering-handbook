# Contributing

The handbook accepts corrections and tested engineering guidance. New recipe
volume is secondary to keeping existing commands accurate.

## Baseline

The stable validation baseline is FFmpeg 8.1.2. Include the output of
`ffmpeg -version` and the relevant component help, such as
`ffmpeg -hide_banner -h filter=xfade`, with behavior-changing reports.
Distributor builds and optional libraries differ, so name every required
encoder, decoder, filter, muxer, protocol, library, device, or driver.

## Recipe contract

Every complete recipe must state:

1. Goal and input assumptions, including required stream types.
2. Whether video, audio, subtitles, or metadata are copied, re-encoded,
   generated, or dropped.
3. Whether timestamps, duration, color properties, sample format, or channel
   layout change.
4. Shell and platform assumptions.
5. A safe overwrite policy. Prefer `-n` in examples.
6. A validation command and the expected measurable result.

Use explicit maps for filtered outputs and multi-stream inputs. Use optional
maps only when omission is an intended result. Do not place a comment after a
line-continuation backslash.

## Claims and evidence

Do not publish universal codec savings, equivalent quality-factor tables,
hardware speed or quality penalties, compatibility claims, or delivery targets.
For measured claims, provide the fixture, exact command, FFmpeg build, hardware
and driver where relevant, metric, and output. Never invent benchmark numbers.

## Checks

Run:

```bash
scripts/validate-docs.sh
scripts/test-repaired-recipes.sh
```

Hardware-only commands must also name the tested device, driver, FFmpeg build,
required pixel formats, and a software fallback. Review in color/HDR,
multichannel audio, hardware acceleration, streaming, packaging, or security
requires a reviewer familiar with that domain.

## Pull requests

Keep one behavioral change per pull request when practical. Update the relevant
page, executable test, and `CHANGELOG.md` together. State whether the result is
local, committed, pushed, deployed, and independently verified.
