# Concepts & Terminology

Understanding FFmpeg starts with grasping the fundamental concepts of digital media.

## The Media Stack

```
┌─────────────────────────────────────┐
│           Container (MP4)           │  ← Wrapper format
├─────────────────────────────────────┤
│  Video Stream    │   Audio Stream   │  ← Multiplexed streams
│  (H.264 codec)   │   (AAC codec)    │  ← Encoded data
├──────────────────┴──────────────────┤
│            Metadata                 │  ← Title, duration, etc.
└─────────────────────────────────────┘
```

## Containers vs Codecs

### Containers (Formats)
The **container** is the wrapper that holds everything together. Think of it as a box that contains video, audio, subtitles, and metadata.

| Container | Extension | Common Use |
|-----------|-----------|------------|
| MP4 | `.mp4` | Web, mobile, universal playback |
| MKV | `.mkv` | High quality archival, multiple tracks |
| MOV | `.mov` | Apple ecosystem, professional editing |
| WebM | `.webm` | Web-optimized, open format |
| AVI | `.avi` | Legacy Windows format |

**Key insight**: You can often change containers without re-encoding (remuxing):

```bash
# Remux MP4 to MKV - no quality loss, very fast
ffmpeg -i input.mp4 -c copy output.mkv
```

### Codecs (Compression)
The **codec** determines how video/audio data is compressed and decompressed.

| Codec | Type | Quality/Size | Use Case |
|-------|------|--------------|----------|
| H.264 (AVC) | Video | Good | Universal compatibility |
| H.265 (HEVC) | Video | Better (50% smaller) | 4K, storage efficiency |
| VP9 | Video | Better | YouTube, web streaming |
| AV1 | Video | Best | Future-proof, slow encode |
| AAC | Audio | Good | Universal, efficient |
| MP3 | Audio | Good | Legacy compatibility |
| Opus | Audio | Best | VoIP, streaming |
| FLAC | Audio | Lossless | Archival |

**Key insight**: Changing codecs requires re-encoding (transcoding):

```bash
# Transcode H.264 to H.265 - slow, changes quality characteristics
ffmpeg -i input.mp4 -c:v libx265 -c:a copy output.mp4
```

## Streams

A media file contains one or more **streams**. Each stream is an independent track of content.

```bash
# Inspect streams with ffprobe
ffprobe -show_streams input.mp4
```

Common stream types:
- `v` - Video stream
- `a` - Audio stream
- `s` - Subtitle stream
- `d` - Data stream

### Stream Selection

FFmpeg uses stream specifiers to target specific streams:

```
0:v      → First input, all video streams
0:a      → First input, all audio streams
0:v:0    → First input, first video stream
1:a:1    → Second input, second audio stream
```

## Encoding Concepts

### Bitrate
**Bitrate** is the amount of data used per second of media.

- **Higher bitrate** = Better quality, larger file
- **Lower bitrate** = Worse quality, smaller file

```bash
# Set video bitrate to 5 Mbps
ffmpeg -i input.mp4 -b:v 5M output.mp4
```

### Frame Rate (FPS)
**Frames per second** determines smoothness of motion.

| FPS | Use Case |
|-----|----------|
| 24 | Cinema |
| 25 | PAL TV |
| 30 | NTSC TV, web |
| 60 | Sports, gaming |

```bash
# Change frame rate
ffmpeg -i input.mp4 -r 30 output.mp4
```

### Resolution
**Resolution** is the dimensions of the video in pixels.

| Name | Resolution | Aspect |
|------|------------|--------|
| SD | 640×480 | 4:3 |
| HD | 1280×720 | 16:9 |
| Full HD | 1920×1080 | 16:9 |
| 4K UHD | 3840×2160 | 16:9 |

### Keyframes (I-frames)
**Keyframes** are complete frames that don't depend on other frames. Other frames (P-frames, B-frames) reference keyframes for efficiency.

**Why this matters**:
- Seeking to non-keyframe positions requires decoding from the previous keyframe
- Cutting at keyframes is instant with `-c copy`
- Cutting between keyframes requires re-encoding

### Pixel Format
**Pixel format** defines how color information is stored.

```bash
# Check pixel format
ffprobe -show_streams input.mp4 | grep pix_fmt

# Common format for compatibility
ffmpeg -i input.mp4 -pix_fmt yuv420p output.mp4
```

`yuv420p` is the most compatible format for playback on devices.

## Timestamp Concepts

### PTS (Presentation Timestamp)
When each frame should be displayed.

### DTS (Decoding Timestamp)
When each frame should be decoded (may differ from PTS with B-frames).

### Timebase
The unit of time measurement, expressed as a fraction (e.g., 1/1000 for milliseconds).

## Quality Metrics

### CRF (Constant Rate Factor)
A quality-based encoding mode where you specify quality, and bitrate varies.

```bash
# CRF scale: 0 (lossless) to 51 (worst)
# 18-23 is typically "visually lossless"
ffmpeg -i input.mp4 -crf 23 output.mp4
```

### VMAF (Video Multimethod Assessment Fusion)
A perceptual quality metric developed by Netflix. Scores from 0-100, where 100 is perfect quality.

## Lossless vs Lossy

### Lossless
- No quality degradation
- Larger file sizes
- Examples: FLAC, PNG, FFV1

### Lossy
- Some quality loss (often imperceptible)
- Much smaller file sizes
- Examples: H.264, AAC, JPEG

## Hardware vs Software Encoding

### Software Encoding
- Uses CPU
- Higher quality at same bitrate
- Slower
- Examples: `libx264`, `libx265`, `libvpx-vp9`

### Hardware Encoding
- Uses GPU/dedicated silicon
- Faster encoding
- Slightly lower quality at same bitrate
- Examples: `h264_nvenc` (NVIDIA), `h264_qsv` (Intel), `h264_videotoolbox` (Apple)

## Common Abbreviations

| Abbr | Meaning |
|------|---------|
| AVC | Advanced Video Coding (H.264) |
| HEVC | High Efficiency Video Coding (H.265) |
| CBR | Constant Bitrate |
| VBR | Variable Bitrate |
| GOP | Group of Pictures |
| NAL | Network Abstraction Layer |
| HLS | HTTP Live Streaming |
| DASH | Dynamic Adaptive Streaming over HTTP |

## Next Steps

- [Command Anatomy](command-anatomy.md) - How FFmpeg commands are structured
- [Filters](filters.md) - Understanding FFmpeg's filter system
