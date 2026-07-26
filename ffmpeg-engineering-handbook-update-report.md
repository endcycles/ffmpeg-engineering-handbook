# FFmpeg Engineering Handbook — Comprehensive Repository Update Report

**Repository audited:** `endcycles/ffmpeg-engineering-handbook`  
**Audit date:** July 25, 2026  
**Recommended documentation baseline:** FFmpeg 8.1.2 “Hoare”  
**Scope:** README, all 22 current topic pages, repository structure, examples, missing subject areas, validation, release process, and contributor infrastructure.

---

## 1. Executive assessment

The repository is useful as a compact collection of FFmpeg recipes, but it is not yet reliable enough to call an **engineering handbook**. Its current strengths are approachable organization, broad beginner coverage, and copyable examples. Its weaknesses are more consequential:

1. Several commands are non-executable, produce a result different from the stated result, or teach an incorrect mental model.
2. Multiple chapters still use deprecated or legacy-style options, especially `-vsync` and `-async`.
3. Compatibility, quality, file-size, and loudness guidance is often presented as universal even though it depends on the encoder, build, input, hardware generation, delivery target, or playback ecosystem.
4. Examples rarely state their required FFmpeg build features, shell, stream assumptions, color behavior, audio behavior, overwrite policy, or validation method.
5. The repository omits major production topics: `ffprobe`, stream mapping, timestamps, color/HDR, adaptive streaming, live/network inputs, quality control, safe subprocess integration, security, archival formats, and reproducible testing.
6. There is no automated mechanism to detect broken links, stale flags, shell errors, commands that fail, or commands whose output contradicts the text.

The correct next step is **not to add more recipes immediately**. First establish a tested FFmpeg baseline, repair the release-blocking defects, add a command-validation harness, and define repository-wide command conventions. Expansion should follow only after the existing material is trustworthy.

---

## 2. Severity model

| Priority | Meaning | Required action |
|---|---|---|
| **P0 — correctness blocker** | Command fails, produces materially different output, contains a broken internal dependency, or teaches a false core concept | Fix before the next content release |
| **P1 — high-risk guidance** | Deprecated syntax, fragile automation, unsafe assumptions, misleading compatibility/quality advice, or omitted behavior that can damage output | Fix in the first modernization pass |
| **P2 — coverage gap** | Important production topic is missing or too shallow for engineering use | Add after P0/P1 stabilization |
| **P3 — maintainability/editorial** | Duplication, navigation, terminology, style, contribution process, or discoverability problem | Address with the documentation-platform pass |

---

## 3. Baseline and version policy

### 3.1 Pin the handbook to a documented stable baseline

Every page should state the stable version on which its executable examples were tested. The baseline for the next release should be:

- **FFmpeg 8.1.2** for the stable documentation lane.
- An optional **current Git snapshot** CI lane to detect upcoming removals and behavior changes.
- Version-matched local documentation as the source of truth for users on older installations.

Do not silently imply that one command works on every FFmpeg binary. FFmpeg functionality depends heavily on configure flags, linked libraries, operating system, driver stack, and distributor packaging.

### 3.2 Add a standard environment preflight

The README and Getting Started section should teach users to capture:

```bash
ffmpeg -version
ffmpeg -buildconf
ffmpeg -formats
ffmpeg -codecs
ffmpeg -encoders
ffmpeg -decoders
ffmpeg -filters
ffmpeg -hwaccels
```

For a specific component, prefer targeted discovery:

```bash
ffmpeg -hide_banner -h encoder=libx264
ffmpeg -hide_banner -h encoder=h264_nvenc
ffmpeg -hide_banner -h filter=xfade
ffmpeg -hide_banner -h muxer=hls
ffmpeg -hide_banner -init_hw_device list
```

### 3.3 Add page-level compatibility metadata

Every topic page should begin with a small metadata block:

```yaml
status: tested
ffmpeg_tested: 8.1.2
last_verified: 2026-07-25
shells: [bash]
platforms: [linux, macos]
required_components: [libx264, aac]
reencodes: [video, audio]
changes_timestamps: true
color_behavior: preserves-tags-only
```

Use a visible rendered equivalent if the repository remains plain Markdown.

### 3.4 Separate four kinds of compatibility

Current tables often collapse these into one yes/no claim. Every compatibility discussion should distinguish:

1. Whether the **FFmpeg build can demux/decode/encode/mux** the format.
2. Whether the **container specification permits** the stream type.
3. Whether common **players, browsers, operating systems, and devices** support it.
4. Whether the resulting combination meets the requirements of a **specific delivery platform or standard**.

---

## 4. P0 correctness blockers

These items should be fixed before adding new chapters.

| Location | Defect | Why it matters | Required correction |
|---|---|---|---|
| Multiple pages | Internal links point to files that do not exist | Navigation is broken and readers are promised nonexistent material | Create the intended pages or remove/replace every link; add a CI link checker |
| `fundamentals/command-anatomy.md` | A line continuation is followed by an inline comment | In POSIX shells, the backslash must terminate the physical line; the example is not safely copyable | Move comments to their own lines or place them before the command |
| `advanced/speed.md` | “120 fps to 30 fps = 4× time-lapse” uses frame-rate reduction without timestamp compression | Dropping frames normally preserves duration; it does not create a 4× time-lapse | Use `setpts=(PTS-STARTPTS)/4`, then choose the desired output frame rate; address audio explicitly |
| `advanced/speed.md` | Variable audio ramp uses an `atempo` expression that is not valid as written | The example does not parse and suggests time-varying tempo can be expressed as a simple scalar expression | Replace with segmented `atrim` + `atempo` + `concat`, a command-supported approach, or a clearly marked external-filter solution |
| `generation/slideshows.md` | `xfade` uses `offset=duration-0.5` | `duration` is not a valid runtime variable for that option; the command is non-executable | Probe or calculate the duration outside the filter graph and inject a numeric offset; normalize both xfade inputs |
| `audio/effects.md` | The text says `atempo` changes speed and pitch | `atempo` changes tempo while preserving pitch | Correct the mental model and contrast `atempo` with sample-rate-based pitch shifting and `rubberband` where available |
| `audio/effects.md` | `volume=replaygain` is presented as normalization | As written, it is not a valid volume expression and replay-gain metadata handling is not the same as measuring/normalizing loudness | Teach `volume` replay-gain options only when side data exists; teach `loudnorm`, `ebur128`, or measured gain for normalization |
| `audio/extraction.md` | `volume=0dB` is labeled peak normalization | `0dB` applies no gain | Replace it with a measured peak-normalization workflow or remove the claim; keep loudness normalization separate |
| `audio/surround.md` | A 4.0-to-5.1 example assumes the wrong 4.0 layout and joins to 5.0 while claiming an LFE channel | FFmpeg’s named layouts distinguish `4.0`, `quad`, `5.0`, `5.1`, and `5.1(side)`; incorrect mapping can place content in the wrong speakers | Use semantic channel names, state the exact source layout, use `quad` for FL/FR/BL/BR where intended, and only create LFE deliberately |
| `generation/storyboards.md` | “Limit total frames” applies `-frames:v 20` after a tile filter | This limits output sheets, not necessarily source thumbnails; a 5×4 tile can represent many more than 20 source frames | Limit selected frames before tiling, or emit exactly one 20-cell sheet and explain the distinction |
| `generation/storyboards.md` | Sprite/VTT logic creates a one-row sprite but computes cue coordinates for additional rows and may truncate long inputs | Generated VTT cues can reference pixels outside the sprite, and `-frames:v 1` can discard later pages | Compute rows, page count, and cue coordinates from the actual sprite geometry; clamp final cue time and support multiple sheets |
| `advanced/subtitles.md` | A subtitle-offset recipe shifts video timestamps instead of subtitle cues | It solves a different problem and can create new A/V sync errors | Apply offset to the subtitle input/stream, such as with input timestamp offset, and show positive and negative cases |

### Broken-link inventory

The current internal references include missing destinations such as:

- `docs/advanced/complex-filters.md`
- `docs/advanced/social-crops.md`
- `docs/optimization/bitrate.md`
- `docs/optimization/web.md`
- `docs/troubleshooting/debugging.md`
- `docs/troubleshooting/compatibility.md`
- `docs/automation/scripts.md`
- `docs/automation/pipelines.md`

Treat this list as an audit starting point; CI should become authoritative.

---

## 5. Repository-wide changes required

### 5.1 Make `docs/` canonical and shorten the README

The README currently duplicates large portions of the topic pages. That creates two sources of truth and makes corrections easy to apply in one place but not the other.

The README should become a compact landing page containing:

- What the handbook is and is not.
- Supported/tested FFmpeg versions.
- A 60-second environment check.
- Navigation into the canonical docs.
- Safety and data-loss warning.
- Contribution and validation status.
- License.

Recipes should live only in `docs/`, except for one minimal verified example.

### 5.2 Establish a command style guide

Every executable command should follow these conventions unless the page explicitly explains why not:

- Use `-hide_banner` in examples where it improves readability, but do not hide errors.
- Avoid blind `-y`; use `-n`, a temporary output, or explicitly label destructive overwrite examples.
- Explicitly map streams when multiple streams or filter outputs exist.
- Use optional mapping when audio/subtitles are not guaranteed, for example `-map 0:a?`.
- State which streams are copied and which are re-encoded.
- State output codecs and key encoder settings instead of relying on container-dependent defaults.
- Name filter outputs and map them explicitly.
- Reset timestamps only where the operation requires it, usually with `(PTS-STARTPTS)` rather than unexplained `PTS` math.
- Show a validation command immediately after important transformations.
- Mark Bash-only syntax such as process substitution.
- Provide PowerShell equivalents for major automation examples or explicitly scope the chapter to Bash.
- Do not put comments after a line-continuation backslash.
- Do not use unsafe `eval` construction.
- Do not parse human-oriented stderr when `-progress` or `ffprobe -of json` is available.

### 5.3 Replace deprecated and legacy options

Perform a repository-wide search and replacement review, not a blind textual replacement:

| Existing pattern | Update direction |
|---|---|
| `-vsync ...` | Use per-stream `-fps_mode`, or use an explicit `fps` filter when actual frame-rate conversion is intended |
| `-async ...` | Diagnose the timestamp problem and use `aresample=async=...` where resampling is genuinely required |
| Generic `-r` after input/filtering | Explain whether it changes output timestamps, duplicates/drops frames, or only sets an encoder/muxer rate; prefer explicit filter and `-fps_mode` semantics |
| `FRAME_RATE` expressions | Avoid on VFR media unless the page first normalizes the time base/rate and explains the consequence |
| Hard-coded stream indices | Discover and map by type, metadata, program, or verified index; show `ffprobe` first |

### 5.4 Stop presenting heuristics as specifications

Remove or qualify claims such as:

- “H.265 is 50% smaller.”
- Fixed “equivalent CRF” tables across unrelated encoders.
- Fixed GPU file-size penalties.
- “Lanczos is best.”
- “Most codecs require even dimensions.”
- “CRF 18–23 is visually lossless.”
- One loudness target described as universal broadcast compliance.
- One container/codec table described as universal playback support.
- A scene-detection threshold described as generally correct.

Replace them with:

- A description of the variable.
- A safe starting point.
- The conditions under which it changes.
- A reproducible benchmark or validation method.
- A dated delivery-platform requirement only when sourced and maintained.

### 5.5 Treat stream presence and topology as variable

Many examples assume exactly one video stream and one audio stream. Production media may contain multiple video angles, commentary tracks, descriptive audio, subtitles, data, attachments, chapters, programs, cover art, or no audio at all.

Add a preflight pattern:

```bash
ffprobe -v error -of json \
  -show_format -show_streams -show_chapters -show_programs input.mkv
```

Teach:

- Optional maps: `-map 0:a?`
- Negative maps: `-map -0:d`
- Metadata and disposition selection.
- Program and stream-group selection where relevant.
- Attachment and chapter preservation.
- The difference between automatic stream selection and explicit mapping.

### 5.6 Add color-management and audio-format disclosures

Every video transformation can affect:

- Pixel format and bit depth.
- Chroma subsampling and chroma location.
- Full versus limited range.
- Color primaries, transfer characteristic, and matrix coefficients.
- HDR static/dynamic metadata.
- Rotation/display matrices and sample aspect ratio.
- Interlacing and field order.

Every audio transformation can affect:

- Sample rate and sample format.
- Channel count and semantic channel layout.
- Encoder delay/priming.
- Loudness, true peak, and clipping headroom.
- Timestamp continuity.

The handbook should stop using `format=yuv420p`, `setsar=1`, or a hard-coded sample rate as generic repair operations.

### 5.7 Replace remote sample dependencies

Do not rely on an unversioned third-party sample URL. Generate deterministic fixtures with FFmpeg sources such as `testsrc2`, `sine`, and `color`, plus checked-in tiny subtitle/metadata fixtures. This makes the documentation reproducible, works offline, avoids link rot, and enables CI assertions.

### 5.8 Add “what this command destroys” callouts

Examples should visibly identify when they:

- Re-encode a lossy stream.
- Drop secondary audio/subtitle/data streams.
- Remove metadata, chapters, attachments, or dispositions.
- Convert HDR to SDR or discard HDR metadata.
- Convert VFR to CFR.
- Change channel layout.
- Seek only to a packet/keyframe boundary under stream copy.
- Overwrite an existing output.

---

## 6. File-by-file update backlog

## 6.1 `README.md`

**Priority:** P1/P3 — rewrite, not incremental patching.

Required changes:

1. Reduce it to a landing page; remove duplicated long-form recipes.
2. Add the FFmpeg 8.1.2 test baseline and a warning that distro/package-manager versions and build flags differ.
3. Add `ffmpeg -version` and `ffmpeg -buildconf` to installation verification.
4. Correct the implication that the FFmpeg project itself supplies identical macOS, Linux, and Windows binaries; package sources and included libraries vary.
5. Rename `+faststart` guidance from “streaming” to progressive-download optimization. It is not an adaptive-streaming workflow.
6. Remove “any format to any format” and universal quality/size claims.
7. Explain that CRF values and preset behavior are encoder-specific.
8. Fix the crop recipe `crop=ih*16/9:ih`, which can request a width larger than a narrow input. Use a conditional crop or scale-and-crop strategy.
9. Make picture-in-picture audio mapping optional or state the audio assumption.
10. Rewrite the `-ss` explanation around accurate seek, transcoding, stream copy, keyframes, and pre-roll.
11. Remove `FRAME_RATE`-based jump-cut logic for arbitrary VFR inputs.
12. Make crossfade examples handle audio or explicitly label them video-only.
13. Link to the validation and troubleshooting model, not only external resources.
14. Add badges only for real checks: docs build, links, command smoke tests, and stable-version matrix.

## 6.2 `docs/fundamentals/command-anatomy.md`

**Priority:** P0/P1.

Required changes:

1. Repair the invalid continuation/comment example.
2. Add a clear model of **global options**, **input options**, **per-output options**, and **per-stream specifiers**. Emphasize that option position changes meaning.
3. Rewrite input-side and output-side `-ss` behavior without the obsolete “input seek is always inaccurate, output seek is accurate” simplification.
4. Explain that `-c:a copy output.aac` is valid only when the selected input audio is AAC and the target format supports the packetization.
5. Add optional maps, negative maps, metadata/disposition maps, program maps, and stream groups.
6. Explain automatic mapping versus filtered-output mapping.
7. Distinguish `-loglevel`, `-hide_banner`, `-nostats`, `-stats`, `-progress`, and report files.
8. Stop calling `-f null -` a dry run. It still decodes, filters, and possibly encodes; it simply uses a null muxer.
9. Add `-n` and atomic-output patterns alongside `-y`.
10. Add an annotated command where every option is scoped correctly across two inputs and two outputs.

## 6.3 `docs/fundamentals/concepts.md`

**Priority:** P1/P2 — substantial expansion.

Required changes:

1. Remove fixed codec rankings and size-savings percentages.
2. Use exact fractional NTSC-family rates such as `30000/1001` and `24000/1001` where applicable.
3. Qualify “visually lossless” and CRF ranges by encoder, content, generation loss, viewing conditions, and delivery target.
4. Expand pixel-format coverage to include subsampling, bit depth, range, primaries, transfer, matrix, alpha, endianness, and hardware surfaces.
5. Explain that hardware quality varies by hardware generation, encoder implementation, preset, rate-control mode, driver, and workload.
6. Add time bases, packet/frame timestamps, PTS versus DTS, decode/reorder delay, start time, duration estimation, VFR/CFR, and edit lists.
7. Add GOP concepts: IDR/keyframes, open versus closed GOP, B-frames, random access, scene cuts, segment alignment.
8. Add audio sample format, sample rate, channel layout, frame size, priming, and true peak.
9. Distinguish codec, encoder, decoder, elementary stream, container, muxer, demuxer, protocol, device, filter, and bitstream filter.
10. Add a glossary page and link terms consistently.

## 6.4 `docs/fundamentals/filters.md`

**Priority:** P0/P1/P2.

Required changes:

1. Repair the missing complex-filter link.
2. Make the crossfade example either video-only by title or add `acrossfade` and explicit maps.
3. Normalize dimensions, frame rate/time base, pixel format, and start timestamps before `xfade`.
4. Update `atempo`: current range is broader than the old 0.5–2.0 limit, while chaining remains relevant when avoiding high-factor sample skipping or when targeting older builds.
5. Stop presenting `format=yuv420p` as a universal compatibility fix; document the bit-depth, chroma, and HDR loss it may cause.
6. Add shell-escaping sections for Bash, PowerShell, and Windows `cmd`.
7. Add `-filter_complex_script`/filter-script examples for maintainable graphs.
8. Explain labels, unconnected outputs, automatic mapping, and explicit maps.
9. Add framesync behavior: `shortest`, EOF behavior, repeating last frames, and timestamp alignment.
10. Explain timeline support and why not every filter accepts `enable=`.
11. Add hardware-frame upload/download and zero-copy graph concepts.
12. Replace “put fast filters first” with semantic ordering plus benchmarking; filter order changes the image, not only performance.
13. Add graph inspection and benchmarking with `-benchmark`, `-progress`, and graph-reporting facilities available in the target build.
14. Ensure every filter fragment is embedded in an executable command or explicitly marked as a fragment.

## 6.5 `docs/operations/conversion.md`

**Priority:** P1.

Required changes:

1. Split muxer support from playback ecosystem compatibility.
2. Remove “any format to any format.”
3. Replace `-async 1` with diagnosed `aresample=async=...` examples.
4. Replace `-vsync cfr` with explicit `fps` and/or `-fps_mode cfr`, explaining duplication/drop behavior.
5. Expand Apple-oriented HEVC guidance beyond the `hvc1` sample-entry tag: profile, level, bit depth, color, audio, and target device still matter.
6. Make two-pass VP9/other examples portable: use `-f null -`, a unique `-passlogfile`, cleanup, and explicit audio behavior.
7. Make multi-output commands specify maps and codecs for every output.
8. Move GIF creation to the dedicated palette workflow rather than a low-quality one-line shortcut.
9. Teach deliberate preservation or removal of metadata, chapters, attachments, data, and dispositions.
10. Add stream-copy compatibility checks and bitstream-filter examples.
11. Add remux versus transcode decision tables based on actual stream/container compatibility.
12. Add checksum/`ffprobe` validation for remuxes.

## 6.6 `docs/operations/scaling.md`

**Priority:** P0/P1/P2.

Required changes:

1. Replace the malformed/ambiguous quoting in the conditional scale example with an unambiguous named-option expression.
2. Repair the missing social-crops link.
3. Replace crop formulas that fail on inputs narrower/taller than the target aspect ratio with conditional expressions or scale-then-crop.
4. Replace “most codecs require even dimensions” with an explanation of encoder and pixel-format divisibility constraints; demonstrate `force_divisible_by` where supported.
5. Treat social-platform dimensions as dated external delivery requirements, not timeless FFmpeg facts.
6. Make multi-output examples tolerate missing audio and specify audio behavior per output.
7. Expand hardware scaling examples to include required hardware contexts, upload/download steps, compatible filters, and fallback behavior.
8. Add color-aware scaling with `zscale` and/or `libplacebo` when available, including HDR-to-SDR tone mapping.
9. Add 10/12-bit workflows, chroma location, range, and interlace-aware scaling.
10. Remove “Lanczos is best”; explain quality, ringing, speed, and content tradeoffs.
11. Add no-upscale patterns.
12. Handle rotation/display metadata and sample/display aspect ratio explicitly.
13. Stop presenting `setsar=1` as a generic aspect-ratio repair.
14. Add output-dimension validation with `ffprobe`.

## 6.7 `docs/operations/trimming.md`

**Priority:** P1/P2.

Required changes:

1. Rewrite all seek guidance around demuxer seek, accurate seek during transcode, packet/keyframe boundaries during stream copy, pre-roll, and timestamp behavior.
2. Remove the suggestion that forcing a keyframe at time zero is a distinct general-purpose “accuracy” fix.
3. Do not use `.aac` as a stream-copy output unless the input codec is verified as AAC.
4. Replace jump-cut logic based on `select` plus `FRAME_RATE` with `trim`/`atrim`, timestamp reset, and concat; provide a VFR-safe version.
5. Remove `-async` and explain when `aresample=async` is appropriate.
6. Qualify “always reset PTS”; timestamp preservation may be intentional.
7. Add `-copyts`, `-start_at_zero`, `-avoid_negative_ts`, edit-list, open-GOP, B-frame, and audio-priming behavior.
8. Add a fast-versus-exact trimming decision matrix.
9. Correct “segment by size” if the command actually segments by duration; add true size-limited caveats if retained.
10. Warn that parallel stream-copy cuts may not begin on independently decodable frames.
11. Make every re-encode example specify codecs, rate control, pixel format/color behavior, and audio behavior.
12. Add frame-accurate validation using timestamps rather than only container duration.

## 6.8 `docs/operations/concatenation.md`

**Priority:** P1/P2.

Required changes:

1. Expand concat-demuxer compatibility requirements beyond codec and resolution: stream count/order, time bases, codec extradata, channel layout, and relevant parameters must be compatible.
2. Generate concat lists safely for quotes, apostrophes, backslashes, newlines, and arbitrary paths.
3. Explain `-safe` and why `-safe 0` weakens path restrictions; do not use it casually.
4. Add audio crossfades alongside video `xfade`, or label video-only output clearly.
5. Replace hard-coded repeated transition offsets with a generated timeline based on probed durations.
6. Normalize sample rate, sample format, channel layout, dimensions, SAR, pixel format, frame rate, time base, and start timestamps before filter concat.
7. Do not present `+genpts` as a universal timestamp repair.
8. Replace fragile/off-by-one grouping scripts with array- or Python-based logic and deterministic ordering.
9. Cover concat-demuxer `inpoint`/`outpoint`, segment metadata, and bitstream-filter requirements.
10. Handle clips with missing audio by generating intentional silence or using separate paths.
11. Add verification for monotonic timestamps and A/V duration drift.

## 6.9 `docs/optimization/codecs.md`

**Priority:** P1/P2.

Required changes:

1. Repair the missing bitrate chapter link.
2. Modernize AV1 coverage: include libaom, SVT-AV1, rav1e when built, software decoders, and current hardware paths without implying universal availability.
3. Add relevant FFmpeg 8.1-era capabilities only with build/hardware prerequisites.
4. Remove universal size savings and cross-encoder CRF-equivalence tables.
5. Correct the relationship between profile/level and quality; profiles describe tool sets and levels constrain decoder/resource requirements.
6. Explain that presets and tune names are encoder-specific.
7. Separate preservation, mezzanine, and delivery:
   - Preservation/lossless: FFV1 with lossless audio such as FLAC or PCM where appropriate.
   - Mezzanine/editing: ProRes, DNxHR, AVC-Intra or other workflow-specific formats.
   - Delivery: H.264, HEVC, AV1, VP9, etc., chosen by target support.
8. Add encoder-specific rate-control models: CRF/CQ, QP, capped quality/VBV, CBR, VBR, two-pass, lookahead, GOP, and latency.
9. Explain licensing/build implications for external encoders such as x264, x265, and libfdk_aac; do not assume they exist in every binary.
10. Replace brand/platform recommendations with dated, sourced delivery profiles or generic decision criteria.
11. Add objective and perceptual evaluation: PSNR, SSIM, VMAF when built, visual inspection, and per-title encoding.
12. Add generation-loss warnings and lossless intermediate guidance.

## 6.10 `docs/optimization/hardware.md`

**Priority:** P1/P2 — full rewrite recommended.

Required changes:

1. Repair missing links.
2. Remove fixed file-size penalties and fixed speed comparisons. Hardware generation, codec, encoder version, preset, rate control, content, resolution, and filters all change the result.
3. Begin with capability discovery: available accelerators, decoders, encoders, filters, and devices.
4. Cover current paths by platform: NVENC/NVDEC/CUDA/NPP, QSV/VPP via current oneVPL-oriented stacks, VAAPI, AMF, VideoToolbox, D3D11/D3D12, Vulkan, V4L2 M2M/Rockchip where available.
5. Add AV1 encode/decode paths and relevant FFmpeg 8.1 additions with strict prerequisites.
6. Do not call NVENC `-cq` “CRF.” Explain the selected encoder’s rate-control mode, preset, tune, VBV, lookahead, and quality controls using `-h encoder=...`.
7. Replace obsolete Intel Media SDK-only framing with current implementation discovery; retain legacy notes only in a versioned appendix.
8. Explain software decode + hardware encode, hardware decode + software filters, and fully hardware-resident pipelines separately.
9. Show the performance cost and format constraints of `hwupload`, `hwdownload`, and device transfers.
10. Add 10-bit, 4:2:2/4:4:4, HDR metadata, interlace, B-frame, and codec-profile capability checks.
11. Add device selection, multi-GPU concerns, driver/container permissions, session limits, memory limits, and graceful fallback.
12. Replace “software is always final delivery” with a measured target-specific recommendation.
13. Add a reproducible benchmark template measuring speed, wall time, utilization, output size, and quality metric.

## 6.11 `docs/advanced/speed.md`

**Priority:** P0/P1.

Required changes:

1. Correct the false 120-to-30-fps time-lapse recipe.
2. Replace the invalid variable `atempo` ramp.
3. Update the `atempo` range and explain why factor chaining may still be preferred.
4. Rename “keep audio at original speed” examples as intentionally desynchronized/truncated effects; they are not a normal synchronized speed change.
5. Prefer `(PTS-STARTPTS)/speed` in examples to make timestamp origin explicit.
6. Rework long reverse workflows. Segmenting, stream copying, reversing, and re-concatenating raises keyframe, timestamp, encoder-delay, and click/discontinuity issues.
7. Explain source capture rate versus intended playback rate for slow motion.
8. State output `fps_mode` and frame interpolation policy.
9. Implement variable speed as tested segments with corresponding audio segments, or explicitly document build-dependent external filters.
10. Add duration assertions proving that 2×, 4×, and 0.5× examples produce the claimed duration.

## 6.12 `docs/advanced/overlays.md`

**Priority:** P0/P1/P2.

Required changes:

1. Repair the missing complex-filter link.
2. Label and map filter outputs explicitly.
3. Use optional audio maps or state exactly which input supplies audio.
4. Explain overlay framesync, EOF behavior, `shortest`, repeated last frames, and timestamp reset/alignment.
5. Loop still images deliberately and define output duration.
6. Ensure picture-in-picture/chroma examples do not fail when an assumed audio stream is absent.
7. Rename the “rounded PiP” example if it is actually circular/elliptical, or implement a true rounded-rectangle alpha mask.
8. Define background duration; generated backgrounds are otherwise easy to make infinite or unexpectedly short.
9. Add alpha format, straight versus premultiplied alpha, and color-range/space behavior.
10. Use scale-reference methods or explicit dimensions to avoid mismatched geometry.
11. Add hardware overlay paths only with compatible hardware-frame examples and fallback.
12. Add validation screenshots/checksums only as generated test artifacts, not as undocumented visual assumptions.

## 6.13 `docs/advanced/subtitles.md`

**Priority:** P0/P1/P2.

Required changes:

1. Repair the missing complex-filter link.
2. Document build requirements for `subtitles`/libass, font discovery, shaping, and optional libraries.
3. Separate soft subtitle muxing by container from subtitle burning.
4. Cover text subtitles versus bitmap subtitles; do not imply image subtitles can be extracted directly to SRT without OCR/transcription.
5. Preserve/set language, title, default, forced, and hearing-impaired dispositions intentionally.
6. Add font attachments, `fontsdir`, font fallback, and cross-platform path escaping.
7. Replace the offset example that shifts video instead of subtitle cues.
8. Replace the “typing effect” if it does not actually reveal text by character; either implement a tested effect or remove it.
9. Add embedded-stream selection, `original_size`, alpha behavior, character encoding, and shaping details.
10. Add CEA-608/708, WebVTT/HLS, TTML/IMSC caveats where supported by the intended workflow, and ASS-style preservation versus lossy conversion.
11. Add a subtitle QA checklist: timing bounds, overlap, encoding, line length, safe areas, font availability, and output-player test.

## 6.14 `docs/audio/effects.md`

**Priority:** P0/P1/P2.

Required changes:

1. Correct the `atempo` pitch statement.
2. Replace invalid/mislabeled replay-gain normalization guidance.
3. Do not call `I=-16` a universal broadcast/EBU target. Loudness, range, and true-peak targets are delivery-spec specific.
4. Make two-pass `loudnorm` executable by showing how to parse the first pass and inject measured values; do not leave unexplained placeholders.
5. Distinguish sample-peak limiting from true-peak compliance.
6. Do not claim a limiter setting equals an exact delivery true-peak value without measurement.
7. Make fake-stereo examples use explicit `pan` and channel layouts; verify the output layout.
8. Avoid a hard-coded 44.1 kHz sample rate in pitch-shift examples unless it is intentional and documented.
9. Warn about clipping/headroom and additional lossy generations.
10. Add `ebur128`, `astats`, `volumedetect`, `aresample`, sample-format conversion, and true-peak verification.
11. Mark external filters such as `rubberband` as build-dependent.
12. Add before/after measurement commands for every normalization or dynamics example.

## 6.15 `docs/audio/extraction.md`

**Priority:** P0/P1.

Required changes:

1. Do not name every copied track `.aac`; derive or choose an extension/container compatible with the actual codec.
2. Explain that copying into M4A works only for compatible audio codecs and metadata/packetization.
3. Add libfdk_aac build/licensing caveats if retained.
4. Replace volatile vendor/STT product recommendations with a generic speech-recognition input specification; place provider-specific notes in dated appendices.
5. Remove the no-op `volume=0dB` normalization example.
6. Make loudness targets delivery-specific.
7. Replace the sync command that redundantly specifies audio copy and implies `avoid_negative_ts` repairs drift. Timestamp shifting is not drift correction.
8. Preserve or explicitly drop metadata, chapters, cover art, attachments, and secondary tracks.
9. Add semantic stream selection by language/title/disposition.
10. Avoid implying FFmpeg bypasses encrypted/DRM-protected DVD or Blu-ray media.
11. Qualify MP3 bitrate/quality guidance by encoder and content.
12. Add PCM extraction recipes that preserve sample rate, bit depth, and channel layout for analysis/transcription.

## 6.16 `docs/audio/mixing.md`

**Priority:** P1/P2.

Required changes:

1. Explain `amix` normalization behavior and show explicit `normalize=0/1` choices.
2. Correct sidechain-compression topology: the sidechain compressor output alone is not automatically the final voice-plus-music mix; mix the voice back deliberately.
3. Correct “video continues with silent audio” examples. `-shortest` only stops at the shortest stream; it does not pad silence. Use `apad` where continued silence is intended.
4. Add headroom, clipping, and limiter guidance with measured verification.
5. Use modern `adelay` syntax such as `all=1` where appropriate.
6. Use explicit `pan`/layout for mono-to-stereo rather than relying on implicit behavior.
7. Distinguish `5.1` and `5.1(side)`.
8. Make loudness labels target-specific.
9. Warn about encoder priming/gaps when concatenating compressed audio.
10. Normalize sample rate, sample format, and channel layout before `amix`/`concat`.
11. Explain duration and dropout-transition behavior.
12. Add a complete ducking graph with voice, music, final mix, explicit maps, and meter validation.

## 6.17 `docs/audio/surround.md`

**Priority:** P0/P1/P2 — structural rewrite.

Required changes:

1. Correct and distinguish `5.1` versus `5.1(side)`.
2. Repair the 4.0/quad/5.0/5.1 mapping error.
3. State that a simple channel duplication/upmix does not create perceptually or artistically valid surround.
4. Use semantic channel names in `pan`/`join`; do not rely on hard-coded DTS channel indices without probing the decoded layout.
5. Add headroom and documented downmix coefficients; account for metadata and target standard.
6. Qualify DTS encoding by actual encoder/build availability and legal/distribution constraints.
7. Clarify Blu-ray PCM and authoring requirements; a codec/container command is not full disc compliance.
8. Add height layouts, ambisonics, and IAMF-oriented concepts for modern immersive workflows.
9. Explain that proprietary object-audio metadata may not survive decode/re-encode or may be inaccessible.
10. Add channel-identification test tones and semantic layout validation.
11. Add true-peak/loudness measurement for multichannel output.

## 6.18 `docs/automation/batch.md`

**Priority:** P0/P1/P2 — rewrite examples around safety.

Required changes:

1. Repair missing script/pipeline links.
2. Replace loops that break on no matches, spaces, newlines, quotes, leading dashes, or output collisions.
3. Avoid `ls | ...`, unsafe `find` parsing, and fragile plain-text failed-file logs.
4. Use null-delimited input or language-native directory iteration.
5. Provide Bash arrays, PowerShell native argument arrays, and Python `subprocess.run([...])` examples; never concatenate untrusted filenames into a shell command.
6. Add bounded concurrency. Do not launch one background FFmpeg process per file without a resource limit.
7. Add strict mode where appropriate, traps, temporary directories, atomic rename, idempotency, retries, and cleanup.
8. Validate outputs with `ffprobe` before replacing source/marking success.
9. Use structured logs and `-progress`, not regex parsing of changing stderr text.
10. Account for CPU threads, storage bandwidth, RAM, GPU memory, and hardware-encoder session limits.
11. Avoid blind `-y` in pipelines.
12. Add deterministic synthetic fixtures and CI tests for examples.
13. Explain pipeline/subshell and `set -e` failure semantics.
14. Add cancellation, timeout, and signal handling.
15. Add resume/checkpoint behavior for long batches.

## 6.19 `docs/troubleshooting/errors.md`

**Priority:** P1/P2.

Required changes:

1. Repair missing debugging/compatibility links.
2. Do not recommend MPEG-4 Part 2 as a generic fallback when libx264 is absent. Teach users to inspect/install an appropriate build or choose an encoder based on the actual target.
3. Mark distro-specific package advice as distro/version-specific.
4. Do not use `-f mp4` or `+faststart` as generic file-repair operations.
5. Use optional maps for absent audio instead of treating every no-audio input as an error.
6. Remove `-async` guidance.
7. Stop presenting `+genpts` or `yuv420p` as universal timestamp/color fixes.
8. Replace “safe to ignore” warning categories with diagnosis criteria.
9. Add a systematic preflight: version/build, input probe, decoder/encoder/filter availability, timestamp inspection, packet inspection, and a minimal null-output reproduction.
10. Add sections for non-monotonic DTS, odd dimensions, color/HDR metadata, subtitle fonts, hardware device/permission failures, out-of-memory, disk exhaustion, network timeout/reconnect, and corrupt inputs.
11. Add a reproducible bug-report template with the complete uncut command, full console output, build configuration, minimal sample, expected result, and actual result.
12. Add security guidance for untrusted inputs, paths, protocols, and resource exhaustion.

## 6.20 `docs/generation/gifs.md`

**Priority:** P1/P2.

Required changes:

1. Correct the description of `palettegen=stats_mode=diff`; it emphasizes changing regions rather than creating a separate palette for every frame.
2. Correct the stated default `paletteuse` dithering mode.
3. Remove `FRAME_RATE` assumptions for arbitrary VFR input.
4. Add transparency, alpha-threshold, disposal, palette, and loop caveats.
5. Present MP4/WebM/animated WebP/APNG alternatives by capability—not as universally superior replacements. Looping, alpha, browser support, autoplay, and accessibility differ.
6. Remove fabricated file-size tables unless generated by a checked-in benchmark with exact fixtures and settings.
7. Make image-sequence ordering portable and deterministic.
8. Explain how `palettegen` statistics and `paletteuse` diffusion/rectangle options interact.
9. Move social-platform upload limits to a dated, sourced appendix or remove them.
10. Avoid duplicate end frames in ping-pong loops unless the pause is intentional.
11. Turn isolated `max_colors` fragments into complete tested commands.
12. Add dimensions/frame-count/file-size assertions.

## 6.21 `docs/generation/slideshows.md`

**Priority:** P0/P1/P2.

Required changes:

1. Fix glob ordering, cross-shell portability, and no-match behavior.
2. Prefer explicit `fps`/`-fps_mode` semantics over unexplained output `-r`.
3. Update variable-duration concat guidance for current frame-timing behavior.
4. Replace excessive `scale=8000:-1` Ken Burns preprocessing with a resolution derived from output size and maximum zoom.
5. Normalize xfade inputs: dimensions, SAR, pixel format, frame rate/time base, and start timestamps.
6. Treat the transition-name list as build/version dependent and teach component discovery.
7. Mark process substitution as Bash-only and provide a portable alternative.
8. Fix the invalid `offset=duration-0.5` loop command.
9. Correct the common-issue example using a quoted `*.jpg` literal without the required image-pattern/glob mechanism.
10. Remove unsafe `eval` command construction; use arrays or a small script that builds arguments safely.
11. Explain `stream_loop` and copy timestamp behavior rather than presenting it as universally seamless.
12. Replace “green frames = use yuv420p” with actual pixel-format/range/color diagnosis.
13. Replace destructive/collision-prone rename loops with non-destructive manifest generation.
14. Add audio-loop/crossfade handling and final-duration validation.

## 6.22 `docs/generation/storyboards.md`

**Priority:** P0/P1/P2.

Required changes:

1. Replace `-vsync`.
2. Fix the “limit total frames” semantic error.
3. Correct keyframe extraction examples that claim multiple images but use a single non-pattern output path.
4. Rewrite the sprite/VTT generator around real rows/pages, geometry, cue limits, and output patterns.
5. Clamp the final cue to actual duration and handle fractional durations.
6. Describe scene-detection thresholds as tuning parameters, not universal values.
7. Make batch processing filename-safe and concurrency-bounded.
8. Document drawtext/font build requirements and escaping.
9. Handle tile pagination and encoder/format maximum dimensions.
10. Add representative-frame selection versus regular-interval selection versus scene-change selection as distinct modes.
11. Add machine-readable manifest output containing source time, page, x/y/width/height, and file path.
12. Validate that every cue rectangle lies inside its referenced image.

## 6.23 `docs/generation/thumbnails.md`

**Priority:** P1/P2.

Required changes:

1. Replace `-vsync`.
2. Explain that deriving an interval from duration and desired count may not produce exactly that count because of endpoints, VFR, rounding, and filter behavior.
3. Describe `thumbnail` as selecting a representative frame from each batch, not a semantic “best frame” detector.
4. Qualify “keyframes without decoding”; demuxing/decoding behavior and usable image extraction still depend on the path.
5. Remove `setsar=1` as a universal aspect fix.
6. Replace `yuvj420p` as a generic color-shift fix with range/matrix-aware conversion and metadata validation.
7. Point animated-GIF thumbnails to the palette workflow.
8. Ensure tile/sprite commands either emit one sheet intentionally or use an output pattern for multiple sheets.
9. Add rotation, SAR/DAR, color/HDR tone mapping, and image-encoder quality settings.
10. Make batch examples filename-safe.
11. Add face/object/saliency selection only as an external-analysis workflow, not as an FFmpeg-native guarantee.

---

## 7. Entirely missing chapters

The current repository cannot become a production handbook only by correcting existing pages. It needs new material in the following areas.

### 7.1 Installation, builds, licensing, and reproducibility

Create pages covering:

- Official source releases versus third-party/package-manager builds.
- Build configuration inspection.
- Static versus shared builds.
- External libraries and feature gates.
- LGPL/GPL/nonfree implications and redistribution considerations.
- Version pinning in containers and CI.
- Building from source at a high level without pretending one configuration fits all users.
- Security update policy.

### 7.2 `ffprobe` and media inspection

This should be a first-class section, not scattered snippets:

- JSON output.
- Streams, packets, frames, chapters, programs, stream groups, side data, and metadata.
- Rational values and time bases.
- Interval reads and packet/frame timestamp diagnosis.
- Semantic stream-selection helpers.
- `jq` and Python parsing without brittle text scraping.
- Probe schemas for automation.

### 7.3 Stream mapping, metadata, chapters, attachments, and dispositions

Add a dedicated mapping chapter with:

- Automatic selection.
- Positive, optional, and negative maps.
- Per-stream codec options.
- Language/title/default/forced disposition.
- Chapter and global/per-stream metadata copying.
- Attachments and cover art.
- Programs and modern stream groups.

### 7.4 Timestamps, time bases, VFR/CFR, and synchronization

This should be one of the central handbook chapters:

- PTS/DTS, decode order versus presentation order.
- Demuxer time base, filter time base, encoder/muxer time base.
- Start time, negative timestamps, discontinuities, wraparound.
- Accurate seek versus stream-copy cuts.
- `copyts`, `start_at_zero`, `avoid_negative_ts`, `itsoffset`, `itsscale`.
- Frame duplication/drop policy via `fps`/`fps_mode`.
- Audio resampling for real clock drift.
- Interleaving and monotonicity.
- Practical diagnosis with `ffprobe` packet/frame output.

### 7.5 Color, HDR, interlace, and telecine

Add chapters covering:

- Pixel format, range, primaries, transfer, matrix, chroma location, mastering metadata, content-light metadata.
- SDR-to-SDR color preservation.
- HDR passthrough and metadata preservation.
- HDR-to-SDR tone mapping with build-dependent filter paths.
- 8/10/12-bit conversion risks.
- Interlace detection, field order, deinterlacing, and telecine/IVTC.
- Rotation/display matrices and SAR/DAR.
- Color validation and test patterns.

### 7.6 Streaming and packaging

Add production sections for:

- HLS, DASH, and CMAF concepts.
- Multi-rendition ladders.
- GOP/keyframe alignment and segment independence.
- Audio/subtitle groups and alternate renditions.
- fMP4 versus MPEG-TS segments.
- Encryption/key handling at a safe architectural level.
- Manifests, segment naming, live windows, VOD finalization.
- Validation with independent packager/player tools.
- Progressive MP4 versus adaptive streaming.

### 7.7 Live, network, and capture workflows

Cover:

- RTMP/RTMPS, SRT, RIST, RTP/UDP, RTSP, HTTP, Icecast, and supported device inputs as build/platform dependent.
- Reconnect, timeout, buffering, latency, packet loss, timestamp discontinuity, and wall-clock behavior.
- Screen/camera/audio capture on macOS, Linux, and Windows.
- Live pacing and real-time constraints.
- Health checks, failover, and graceful shutdown.
- Security implications of exposed listeners and remote URLs.

### 7.8 Quality control and objective measurement

Add:

- Decode-error validation.
- PSNR, SSIM, VMAF when available.
- Frame/hash comparison.
- Black/freeze/silence detection.
- Loudness and true peak.
- A/V sync checks.
- Duration, frame count, stream topology, color tags, and channel layout assertions.
- Why metrics do not replace visual/listening review.
- Reproducible benchmark fixtures.

### 7.9 Safe automation and application integration

Add language-specific patterns for:

- Argument arrays rather than shell strings.
- Progress parsing.
- Cancellation/signals/timeouts.
- Temporary and atomic files.
- Resource limits and sandboxing.
- Idempotency, retries, checkpointing, and resumability.
- Structured errors and logs.
- Worker queues and bounded concurrency.
- Content-addressed/cacheable outputs.
- Probe-before-plan architecture.
- Never trusting filenames, metadata, or remote media.

### 7.10 Security and untrusted media

Create `SECURITY.md` and a handbook chapter covering:

- Keeping FFmpeg patched.
- Treating parsers/decoders as an attack surface.
- Protocol allowlists and avoiding unintended local/network access.
- Concat/path traversal concerns.
- CPU, memory, disk, duration, resolution, stream-count, and decompression-bomb limits.
- Running workers with least privilege and isolation.
- Secrets in URLs/logs.
- Responsible vulnerability reporting.

### 7.11 Archival, preservation, and mezzanine workflows

Cover:

- Lossless video/audio choices.
- FFV1/Matroska-oriented preservation concepts.
- Checksums and fixity.
- ProRes/DNxHR and other mezzanine use cases.
- Metadata and attachment preservation.
- Why “high quality lossy” is not archival preservation.
- Long-term verification and migration.

### 7.12 Image sequences and raw media

Add:

- Image-sequence demuxer patterns, ordering, start numbers, frame rates, gaps.
- Rawvideo/rawaudio geometry and format requirements.
- Alpha workflows.
- High-bit-depth still formats.
- Very large dimensions and memory estimation.
- Sequence-to-video and video-to-sequence round trips.

---

## 8. Recommended target information architecture

A clearer engineering-oriented structure would be:

```text
README.md
CONTRIBUTING.md
SECURITY.md
CHANGELOG.md
CODE_OF_CONDUCT.md
mkdocs.yml                         # or equivalent docs configuration

docs/
  index.md
  getting-started/
    installation-and-builds.md
    verify-your-build.md
    command-safety.md
    generated-test-media.md

  fundamentals/
    media-model.md
    command-anatomy.md
    stream-selection-and-mapping.md
    timestamps-and-time-bases.md
    filters-and-filtergraphs.md
    color-and-pixel-formats.md
    audio-formats-and-layouts.md
    metadata-chapters-attachments.md
    ffprobe.md

  operations/
    remux-and-convert.md
    trim-and-seek.md
    concatenate.md
    scale-crop-pad-rotate.md
    speed-and-retiming.md
    overlays-and-compositing.md
    subtitles-and-captions.md
    audio-extract-mix-process.md
    image-sequences.md

  encoding/
    codec-selection.md
    rate-control.md
    gop-and-random-access.md
    hardware-acceleration.md
    color-hdr-and-tone-mapping.md
    archival-and-mezzanine.md
    quality-metrics.md

  delivery/
    web-playback-profiles.md
    hls.md
    dash-and-cmaf.md
    live-and-network-inputs.md
    captions-and-alternate-renditions.md

  generation/
    thumbnails.md
    storyboards-and-sprites.md
    gifs-and-animated-images.md
    slideshows.md

  automation/
    shell.md
    powershell.md
    python.md
    progress-cancellation-timeouts.md
    queues-concurrency-and-resume.md
    validation-and-observability.md

  troubleshooting/
    diagnostic-playbook.md
    timestamps-and-sync.md
    color-and-hdr.md
    hardware.md
    corrupt-and-hostile-inputs.md
    reproducible-bug-reports.md

  reference/
    command-conventions.md
    glossary.md
    version-compatibility.md
    tested-platforms.md
```

Do not create empty placeholder pages merely to satisfy links. Either publish complete minimum-viable chapters or point to a tracked roadmap.

---

## 9. Automated validation and CI

A command-heavy handbook needs executable documentation.

### 9.1 Static checks

Add CI for:

- Markdown linting.
- Internal and external link checking.
- Spelling and terminology consistency.
- ShellCheck for Bash scripts.
- A custom rule forbidding comments after continuation backslashes.
- A custom stale-option scan for `-vsync`, `-async`, and other intentionally banned patterns.
- Docs-site build and navigation validation.
- Duplicate heading/anchor detection.

### 9.2 Code-block metadata

Annotate executable blocks so CI knows how to handle them:

````markdown
```bash test=smoke fixture=av-basic platform=linux timeout=30
ffmpeg ...
```
````

Suggested states:

- `test=smoke`: must execute in CI.
- `test=assert`: execute and validate output properties.
- `test=syntax`: parse/lint only.
- `test=manual`: hardware, live, licensed, or environment-specific; must state why.
- `fragment=true`: not a complete command.

### 9.3 Deterministic fixtures

Generate tiny local fixtures in CI, for example:

- CFR video plus sine audio.
- VFR video.
- Video without audio.
- Multi-audio/multi-subtitle Matroska file.
- Rotated/SAR-tagged video.
- 10-bit/HDR-tagged synthetic sample where feasible.
- Mono, stereo, quad, 5.1, and 5.1(side) test tones.
- SRT and ASS subtitle files.
- Image sequence with spaces and unusual characters in paths.

Fixtures should be generated from FFmpeg lavfi sources or checked-in tiny assets with checksums.

### 9.4 Output assertions

Do not treat exit code zero as sufficient. Use `ffprobe -of json` and small assertion scripts to verify:

- Expected stream count and stream types.
- Codec and container.
- Width, height, SAR/DAR, pixel format, bit depth, color tags.
- Frame rate/mode and duration tolerance.
- Audio sample rate, channel count/layout, and duration.
- Metadata, chapters, dispositions, and subtitle presence.
- Claimed speed transformation.
- Sprite cue rectangles inside image bounds.
- Monotonic timestamps where required.
- Loudness/peak target tolerance where the recipe claims compliance.

### 9.5 Version matrix

Run at least:

1. The pinned stable baseline, FFmpeg 8.1.2.
2. A current snapshot or regularly refreshed development build.

Optionally retain one older supported version only if the project explicitly promises backward compatibility. Avoid turning every page into a compatibility maze; use versioned docs or callouts.

### 9.6 Hardware examples

Hardware examples are difficult to execute on generic CI. Require each manual hardware recipe to include:

- Capability-discovery command.
- Tested GPU/SoC, OS, driver, FFmpeg version, and build flags.
- A software fallback.
- A probe/validation step.
- No unqualified quality or speed claims.

---

## 10. Documentation template for every recipe

Each recipe should use a consistent structure:

1. **Goal** — exact expected result.
2. **Assumptions** — input streams, codecs, duration, frame-rate mode, layout, color, and shell.
3. **Preflight** — `ffprobe`/component availability.
4. **Command** — complete, copyable, safely quoted.
5. **What is re-encoded/copied/dropped**.
6. **Timestamp behavior**.
7. **Color/audio behavior**.
8. **Validation** — executable check.
9. **Failure modes** — common mismatches.
10. **Variants** — only when meaningfully different.

Example skeleton:

````markdown
### Create a 4× synchronized time-lapse

**Assumptions:** one video stream, optional audio, CFR output at 30 fps, Bash.

**Inspect:**
```bash
ffprobe ...
```

**Transform:**
```bash
ffmpeg ...
```

**Behavior:** video and audio are re-encoded; duration should be approximately one quarter of the input; secondary streams are not preserved unless mapped.

**Verify:**
```bash
ffprobe ...
```
````

---

## 11. Implementation order

### Phase 0 — freeze and inventory

- Stop accepting new recipe expansion temporarily.
- Record every Markdown page and every fenced code block.
- Pin the stable baseline.
- Add link checking and stale-option scanning.
- Create deterministic fixtures.

### Phase 1 — repair correctness blockers

- Fix every P0 item in Section 4.
- Remove or create all missing linked pages.
- Replace invalid/no-op commands.
- Correct channel-layout and tempo concepts.
- Add assertions for each repaired recipe.

### Phase 2 — modernize existing pages

- Replace `-vsync` and `-async` intentionally.
- Rewrite seek/timestamp material.
- Add optional maps and explicit codecs.
- Remove universal claims.
- Add color/audio/build disclosures.
- Make scripts filename-safe and concurrency-bounded.

### Phase 3 — add the missing engineering core

Prioritize new chapters in this order:

1. `ffprobe` and stream mapping.
2. Timestamps/time bases/VFR/CFR/sync.
3. Color/HDR/interlace.
4. Safe automation/progress/cancellation.
5. Quality control and validation.
6. Hardware acceleration architecture.
7. HLS/DASH/CMAF and live/network workflows.
8. Security and untrusted media.
9. Archival/mezzanine.

### Phase 4 — documentation platform and governance

- Build a searchable docs site.
- Add page metadata and version banners.
- Add CONTRIBUTING, SECURITY, CHANGELOG, and templates.
- Establish release notes and a review cadence after each FFmpeg stable release.
- Publish an explicit supported-version policy.

---

## 12. Repository governance additions

Add at minimum:

### `CONTRIBUTING.md`

Define:

- FFmpeg baseline and supported versions.
- Required recipe structure.
- Command style guide.
- How to add fixtures/tests.
- Evidence required for performance/quality/compatibility claims.
- Platform-specific review requirements.
- No fabricated benchmark numbers.

### `SECURITY.md`

Define:

- How to report vulnerabilities in handbook scripts/examples.
- Supported handbook releases.
- Policy for known-vulnerable FFmpeg versions.
- Untrusted-input stance.

### `CHANGELOG.md`

Track:

- Command behavior changes.
- Deprecated-option removals.
- Baseline-version changes.
- Corrected dangerous or misleading recipes.

### Issue and pull-request templates

Require:

- FFmpeg version and build configuration.
- Full command and uncut output.
- Input probe.
- Expected versus actual behavior.
- Platform/shell.
- Reproduction fixture or minimal sample.
- Documentation and test updates for command changes.

### Ownership/review model

Require specialist review for:

- Color/HDR.
- Multichannel audio/loudness.
- Hardware acceleration.
- Live/network streaming.
- Packaging standards.
- Security-sensitive automation.

---

## 13. Definition of done for the next major handbook release

The repository should not call the modernization complete until all of the following are true:

1. Zero broken internal links.
2. Every complete shell block is tagged as tested, syntax-only, or manual with a reason.
3. All smoke-testable commands execute on FFmpeg 8.1.2.
4. Commands that make measurable claims have output assertions.
5. No active example uses `-vsync` or `-async` without a historical/version-specific explanation.
6. No command relies on an unverified remote sample URL.
7. No file claims universal codec size savings, CRF equivalence, hardware quality penalty, loudness target, or playback compatibility without a defined test/target.
8. Every multi-stream/filter example maps outputs explicitly.
9. Optional input streams are handled intentionally.
10. Every page identifies re-encoding, stream loss, timestamp changes, and destructive overwrite behavior.
11. Color/HDR and audio-layout risks are disclosed where relevant.
12. All batch examples safely handle spaces and unusual filenames and use bounded concurrency.
13. README no longer duplicates the handbook.
14. `ffprobe`, stream mapping, timestamps, color/HDR, validation, automation safety, and security are first-class chapters.
15. Stable and development-version CI lanes pass.
16. CONTRIBUTING, SECURITY, CHANGELOG, and release policy exist.

---

## Appendix A — evidence basis

This audit was based on:

- The repository's `main` branch, including the README and all 22 topic pages available on July 25, 2026.
- The official FFmpeg stable-release information for FFmpeg 8.1.2 and the FFmpeg 8.1 release highlights.
- The official `ffmpeg`, `ffprobe`, filter, format, utility, device, and hardware-acceleration documentation.
- Official FFmpeg project history documenting the transition from global `-vsync` behavior to per-stream `-fps_mode`, and the long-standing replacement of legacy `-async` guidance with the `aresample` filter.
- Direct command-level review of the repository examples, including targeted execution checks for the most consequential parsing and semantic defects.

Because FFmpeg documentation on the project website tracks current development, maintainers should also compare each page against the documentation shipped with the exact stable binary used in CI.

---

## 14. Final recommendation

Treat the next release as a **correctness and engineering-foundation release**, not a content-volume release.

The highest-leverage sequence is:

1. Fix P0 examples and links.
2. Add executable-documentation CI.
3. Pin FFmpeg 8.1.2 and remove deprecated patterns.
4. Rewrite command conventions, timestamps, mapping, color, and audio assumptions across every existing page.
5. Add the missing production chapters.
6. Only then expand the recipe catalog.

That sequence changes the repository from a broad but fragile cheat sheet into a handbook that an engineer can safely use as the basis of repeatable media pipelines.
