# FFmpeg Engineering Handbook

A practical cheatsheet for video automation, clipping, and media processing pipelines.

Brought to you by [YTScribe a YouTube Transcription AI Studio](https://ytscribe.ai/)

## Installation

```bash
brew install ffmpeg        # macOS
apt-get install ffmpeg     # Ubuntu/Debian
choco install ffmpeg       # Windows
```

## Table of Contents

- [Quick Reference](#quick-reference)
- [Format Conversion](#format-conversion)
- [Trimming & Clipping](#trimming--clipping)
- [Resizing & Scaling](#resizing--scaling)
- [Audio Operations](#audio-operations)
- [Overlays & Watermarks](#overlays--watermarks)
- [Text & Subtitles](#text--subtitles)
- [Speed Control](#speed-control)
- [Concatenation](#concatenation)
- [Thumbnails & Storyboards](#thumbnails--storyboards)
- [GIF Creation](#gif-creation)
- [Encoding Settings](#encoding-settings)
- [Batch Processing](#batch-processing)
- [Deep Dives](#deep-dives)

---

## Quick Reference

### Common Flags

| Flag | Description |
|------|-------------|
| `-i` | Input file |
| `-y` | Overwrite output without asking |
| `-c copy` | Copy streams without re-encoding (fast) |
| `-c:v libx264` | H.264 video encoder |
| `-c:a aac` | AAC audio encoder |
| `-vf` | Video filter |
| `-af` | Audio filter |
| `-filter_complex` | Complex multi-stream filter |
| `-ss` | Start time (seek) |
| `-t` | Duration |
| `-to` | End time |
| `-an` | Remove audio |
| `-vn` | Remove video |
| `-map` | Select specific streams |

### Filter Stream Selectors

| Selector | Meaning |
|----------|---------|
| `[0:v]` | Video from first input |
| `[0:a]` | Audio from first input |
| `[1:v]` | Video from second input |
| `[0:v:0]` | First video stream from first input |

### Time Formats

```bash
-ss 30          # 30 seconds
-ss 00:01:30    # 1 minute 30 seconds
-ss 00:01:30.500  # With milliseconds
```

---

## Format Conversion

### Remux (Fast, No Re-encoding)

```bash
# MP4 to MKV - just change container
ffmpeg -i input.mp4 -c copy output.mkv

# MP4 to MOV
ffmpeg -i input.mp4 -c copy output.mov
```

### Transcode (Re-encode)

```bash
# Any format to MP4 (H.264 + AAC)
ffmpeg -i input.avi -c:v libx264 -crf 23 -c:a aac output.mp4

# High quality H.264
ffmpeg -i input.mov -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 192k output.mp4

# To H.265 (50% smaller, slower encode)
ffmpeg -i input.mp4 -c:v libx265 -crf 28 -c:a aac output.mp4
```

> **Deep dive**: [Format Conversion](docs/operations/conversion.md) | [Codecs](docs/fundamentals/concepts.md)

---

## Trimming & Clipping

### Basic Trim

```bash
# Trim from 10s to 40s
ffmpeg -i input.mp4 -ss 00:00:10 -to 00:00:40 output.mp4

# Trim 30 seconds starting at 1 minute
ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 output.mp4
```

### Fast Trim (No Re-encoding)

```bash
# Fast but may have a few seconds of inaccuracy
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 -c copy output.mp4
```

**Note**: `-ss` before `-i` = fast input seeking (keyframe-based). After `-i` = accurate but slower.

### Frame-Accurate Trim

```bash
# Re-encode for precise cuts
ffmpeg -i input.mp4 -ss 00:00:37 -t 00:00:10 -c:v libx264 -c:a aac output.mp4
```

### Jump Cuts (Multiple Segments)

```bash
# Keep 0-5s, 10-15s, 20-25s
ffmpeg -i input.mp4 \
  -vf "select='between(t,0,5)+between(t,10,15)+between(t,20,25)',setpts=N/FRAME_RATE/TB" \
  -af "aselect='between(t,0,5)+between(t,10,15)+between(t,20,25)',asetpts=N/SR/TB" \
  output.mp4
```

> **Deep dive**: [Trimming Guide](docs/operations/trimming.md)

---

## Resizing & Scaling

### Basic Resize

```bash
# Scale to 1280x720
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4

# Scale width, auto-height (preserve aspect)
ffmpeg -i input.mp4 -vf "scale=1280:-2" output.mp4
```

### Fit with Letterbox/Pillarbox

```bash
# Fit in 1920x1080, add black bars
ffmpeg -i input.mp4 -vf \
  "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  output.mp4
```

### Social Media Formats

```bash
# YouTube 1080p (16:9)
ffmpeg -i input.mp4 -vf \
  "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:black,setsar=1" \
  output_youtube.mp4

# Instagram/TikTok (9:16 vertical)
ffmpeg -i input.mp4 -vf \
  "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1:black,setsar=1" \
  output_vertical.mp4

# Instagram Square (1:1)
ffmpeg -i input.mp4 -vf \
  "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:black,setsar=1" \
  output_square.mp4
```

### Crop

```bash
# Crop to center 1280x720
ffmpeg -i input.mp4 -vf "crop=1280:720" output.mp4

# Crop with offset (x=100, y=50)
ffmpeg -i input.mp4 -vf "crop=1280:720:100:50" output.mp4

# Crop to 16:9 from center
ffmpeg -i input.mp4 -vf "crop=ih*16/9:ih" output.mp4
```

> **Deep dive**: [Scaling Guide](docs/operations/scaling.md)

---

## Audio Operations

### Extract Audio

```bash
# Copy audio without re-encoding
ffmpeg -i input.mp4 -vn -c:a copy output.aac

# Extract as MP3
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3

# Extract as WAV
ffmpeg -i input.mp4 -vn -c:a pcm_s16le output.wav
```

### Replace Audio

```bash
ffmpeg -i video.mp4 -i audio.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -shortest \
  output.mp4
```

### Mix Audio (Background Music)

```bash
# Lower music volume, mix with video audio
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex "[1:a]volume=0.3[music];[0:a][music]amix=inputs=2:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

### Fade Audio

```bash
# 2s fade in, 3s fade out (for 30s audio)
ffmpeg -i input.mp4 -af "afade=t=in:d=2,afade=t=out:st=27:d=3" output.mp4
```

### Remove Audio

```bash
ffmpeg -i input.mp4 -an -c:v copy output.mp4
```

> **Deep dive**: [Audio Extraction](docs/audio/extraction.md) | [Audio Mixing](docs/audio/mixing.md)

---

## Overlays & Watermarks

### Image Overlay (Watermark)

```bash
# Bottom-right corner with padding
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=main_w-overlay_w-10:main_h-overlay_h-10" \
  output.mp4

# Top-left corner
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=10:10" \
  output.mp4

# Center
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" \
  output.mp4
```

### Timed Overlay

```bash
# Show logo from 5s to 15s only
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=10:10:enable='between(t,5,15)'" \
  output.mp4
```

### Semi-Transparent Overlay

```bash
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[1:v]format=argb,geq=p(X,Y):a='0.5*alpha(X,Y)'[logo];[0:v][logo]overlay=10:10" \
  output.mp4
```

### Picture-in-Picture

```bash
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "[1:v]scale=320:180[pip];[0:v][pip]overlay=main_w-overlay_w-10:10" \
  -map 0:a -c:a copy output.mp4
```

> **Deep dive**: [Overlays Guide](docs/advanced/overlays.md)

---

## Text & Subtitles

### Text Overlay

```bash
# Basic text
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Hello World':x=100:y=100:fontsize=48:fontcolor=white" \
  output.mp4

# With background box
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Hello':x=100:y=100:fontsize=48:fontcolor=white:box=1:boxcolor=black@0.6:boxborderw=10" \
  output.mp4

# Centered text
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Centered':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=48" \
  output.mp4
```

### Timed Text

```bash
# Show text from 2s to 8s
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Now Showing':x=100:y=100:fontsize=48:enable='between(t,2,8)'" \
  output.mp4
```

### Burn Subtitles (SRT)

```bash
ffmpeg -i video.mp4 -vf "subtitles=subs.srt" output.mp4

# With styling
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF'" \
  output.mp4
```

### Add Subtitle Track (Soft Subs)

```bash
ffmpeg -i video.mp4 -i subs.srt \
  -c copy -c:s srt \
  -metadata:s:s:0 language=eng \
  output.mkv
```

> **Deep dive**: [Subtitles Guide](docs/advanced/subtitles.md)

---

## Speed Control

### Speed Up

```bash
# 2x speed
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" \
  -map "[v]" -map "[a]" output.mp4

# 4x speed (chain atempo for >2x)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.25*PTS[v];[0:a]atempo=2.0,atempo=2.0[a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Slow Down

```bash
# 0.5x speed (half speed)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Speed Formula

| Speed | setpts | atempo |
|-------|--------|--------|
| 2x | 0.5*PTS | 2.0 |
| 1.5x | 0.667*PTS | 1.5 |
| 0.5x | 2.0*PTS | 0.5 |
| 0.25x | 4.0*PTS | 0.5,0.5 |

> **Deep dive**: [Speed Manipulation](docs/advanced/speed.md)

---

## Concatenation

### Same Format (Fast)

Create `files.txt`:
```
file 'video1.mp4'
file 'video2.mp4'
file 'video3.mp4'
```

```bash
ffmpeg -f concat -safe 0 -i files.txt -c copy output.mp4
```

### Different Formats (Re-encode)

```bash
ffmpeg -i video1.mp4 -i video2.avi \
  -filter_complex \
    "[0:v]scale=1920:1080,fps=30,format=yuv420p[v0]; \
     [1:v]scale=1920:1080,fps=30,format=yuv420p[v1]; \
     [v0][0:a][v1][1:a]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

### With Crossfade

```bash
ffmpeg -i video1.mp4 -i video2.mp4 \
  -filter_complex "xfade=transition=fade:duration=1:offset=4" \
  output.mp4
```

> **Deep dive**: [Concatenation Guide](docs/operations/concatenation.md)

---

## Thumbnails & Storyboards

### Single Thumbnail

```bash
# At 5 seconds
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 -q:v 2 thumbnail.jpg

# High quality PNG
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 thumbnail.png
```

### Multiple Thumbnails

```bash
# One per 10 seconds
ffmpeg -i input.mp4 -vf "fps=1/10" -q:v 2 thumb_%04d.jpg
```

### Scene Detection Thumbnail

```bash
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)',thumbnail" \
  -frames:v 1 best_scene.jpg
```

### Storyboard Grid

```bash
# 4x4 grid from scenes
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)',scale=320:180,tile=4x4" \
  -frames:v 1 storyboard.jpg

# Time-based grid (every 10 seconds)
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=240:135,tile=5x4" \
  -frames:v 1 storyboard.jpg
```

> **Deep dive**: [Thumbnails](docs/generation/thumbnails.md) | [Storyboards](docs/generation/storyboards.md)

---

## GIF Creation

### Basic (Low Quality)

```bash
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" output.gif
```

### High Quality (Palette Method)

```bash
ffmpeg -i input.mp4 \
  -filter_complex "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### From Specific Segment

```bash
ffmpeg -ss 10 -t 3 -i input.mp4 \
  -filter_complex "fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

> **Deep dive**: [GIF Creation](docs/generation/gifs.md)

---

## Encoding Settings

### Quality (CRF Scale)

Lower = better quality, larger file. Range 0-51.

```bash
# Visually lossless (~18)
ffmpeg -i input.mov -c:v libx264 -crf 18 output.mp4

# Good quality (~23, default)
ffmpeg -i input.mov -c:v libx264 -crf 23 output.mp4

# Smaller file (~28)
ffmpeg -i input.mov -c:v libx264 -crf 28 output.mp4
```

### Presets

Slower = better compression, smaller file.

```bash
# Fast encoding
ffmpeg -i input.mov -c:v libx264 -preset fast -crf 23 output.mp4

# Best compression
ffmpeg -i input.mov -c:v libx264 -preset veryslow -crf 23 output.mp4
```

### Web Optimization

```bash
# Fast start for streaming
ffmpeg -i input.mov -c:v libx264 -crf 23 -movflags +faststart output.mp4
```

### Hardware Encoding

```bash
# NVIDIA GPU
ffmpeg -i input.mp4 -c:v h264_nvenc output.mp4

# Intel QuickSync
ffmpeg -init_hw_device qsv=hw -i input.mp4 -c:v h264_qsv output.mp4
```

> **Deep dive**: [Codecs](docs/optimization/codecs.md) | [Hardware Acceleration](docs/optimization/hardware.md)

---

## Batch Processing

### All Files in Directory

```bash
# Convert all AVI to MP4
for f in *.avi; do
  ffmpeg -i "$f" -c:v libx264 -crf 23 "${f%.avi}.mp4"
done
```

### With Parallel Processing

```bash
# Using GNU Parallel
find . -name "*.avi" | parallel -j4 'ffmpeg -i {} -c:v libx264 -crf 23 {.}.mp4'
```

### Extract Thumbnails from All Videos

```bash
for f in *.mp4; do
  ffmpeg -ss 5 -i "$f" -frames:v 1 -q:v 2 "${f%.mp4}_thumb.jpg"
done
```

> **Deep dive**: [Batch Processing](docs/automation/batch.md)

---

## Probing Files

```bash
# Quick info
ffprobe input.mp4

# Detailed stream info
ffprobe -show_streams input.mp4

# JSON output
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# Get duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4
```

---

## Deep Dives

For comprehensive coverage on each topic:

### Fundamentals
- [Concepts & Terminology](docs/fundamentals/concepts.md) - Containers, codecs, streams
- [Command Anatomy](docs/fundamentals/command-anatomy.md) - How commands are structured
- [Filters & Filter Graphs](docs/fundamentals/filters.md) - Filter syntax and patterns

### Operations
- [Format Conversion](docs/operations/conversion.md)
- [Trimming & Cutting](docs/operations/trimming.md)
- [Resizing & Scaling](docs/operations/scaling.md)
- [Concatenation](docs/operations/concatenation.md)

### Audio
- [Audio Extraction](docs/audio/extraction.md)
- [Audio Mixing](docs/audio/mixing.md)
- [Audio Effects](docs/audio/effects.md)
- [Surround Sound](docs/audio/surround.md)

### Advanced
- [Overlays & Compositing](docs/advanced/overlays.md)
- [Text & Subtitles](docs/advanced/subtitles.md)
- [Speed Manipulation](docs/advanced/speed.md)

### Generation
- [Thumbnails](docs/generation/thumbnails.md)
- [GIFs](docs/generation/gifs.md)
- [Slideshows](docs/generation/slideshows.md)
- [Storyboards](docs/generation/storyboards.md)

---

## Sample Files

Test commands with these public samples:

```
https://storage.rendi.dev/sample/big_buck_bunny_720p_16sec.mp4
https://storage.rendi.dev/sample/Neon_Lights_5sec.mp3
https://storage.rendi.dev/sample/rendi_banner_white.png
```

---

## Resources

- [Official FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [FFmpeg Wiki](https://trac.ffmpeg.org/wiki)
- [FFmpeg Filters](https://ffmpeg.org/ffmpeg-filters.html)

---

## License

MIT License
