# Codec Selection

Choosing the right codec determines quality, file size, compatibility, and encoding speed.

## Video Codecs Overview

| Codec | Encoder | Quality/Size | Speed | Compatibility |
|-------|---------|--------------|-------|---------------|
| H.264 | libx264 | Good | Fast | Universal |
| H.265 | libx265 | Better | Slow | Good |
| VP9 | libvpx-vp9 | Better | Slow | Web (Chrome, Firefox) |
| AV1 | libaom-av1 | Best | Very Slow | Limited |

## H.264 (libx264)

The universal choice for maximum compatibility.

### Basic Usage

```bash
ffmpeg -i input.mov -c:v libx264 -c:a aac output.mp4
```

### Quality Control (CRF)

```bash
# Range: 0 (lossless) to 51 (worst)
# Recommended: 18-28

ffmpeg -i input.mov -c:v libx264 -crf 18 output.mp4  # High quality
ffmpeg -i input.mov -c:v libx264 -crf 23 output.mp4  # Default
ffmpeg -i input.mov -c:v libx264 -crf 28 output.mp4  # Smaller file
```

### Presets

Trade encoding speed for compression efficiency:

| Preset | Speed | File Size |
|--------|-------|-----------|
| ultrafast | Fastest | Largest |
| superfast | | |
| veryfast | | |
| faster | | |
| fast | | |
| medium | Default | |
| slow | | |
| slower | | |
| veryslow | Slowest | Smallest |

```bash
ffmpeg -i input.mov -c:v libx264 -crf 23 -preset slow output.mp4
```

### Profile and Level

For specific device compatibility:

```bash
# Baseline - Maximum compatibility (old devices)
ffmpeg -i input.mov -c:v libx264 -profile:v baseline -level 3.0 output.mp4

# Main - Good compatibility
ffmpeg -i input.mov -c:v libx264 -profile:v main -level 4.0 output.mp4

# High - Best quality (modern devices)
ffmpeg -i input.mov -c:v libx264 -profile:v high -level 4.1 output.mp4
```

### Tune Options

Optimize for content type:

| Tune | Best For |
|------|----------|
| film | High-quality movie content |
| animation | Cartoons, anime |
| grain | Preserve film grain |
| stillimage | Slideshows |
| psnr | PSNR optimization |
| ssim | SSIM optimization |
| fastdecode | Easier playback |
| zerolatency | Streaming/real-time |

```bash
ffmpeg -i input.mov -c:v libx264 -tune film -crf 20 output.mp4
ffmpeg -i cartoon.mov -c:v libx264 -tune animation -crf 20 output.mp4
```

### Web-Optimized H.264

```bash
ffmpeg -i input.mov \
  -c:v libx264 -crf 23 -preset medium \
  -profile:v main -level 4.0 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -c:a aac -b:a 128k \
  output.mp4
```

## H.265/HEVC (libx265)

~50% smaller files at same quality. Slower to encode.

### Basic Usage

```bash
ffmpeg -i input.mov -c:v libx265 -crf 28 -c:a aac output.mp4
```

**Note**: CRF scale is different from H.264. H.265 CRF 28 ≈ H.264 CRF 23.

### Presets

Same as H.264:

```bash
ffmpeg -i input.mov -c:v libx265 -crf 28 -preset slow output.mp4
```

### Apple Device Compatibility

```bash
# Required tag for Apple devices
ffmpeg -i input.mov -c:v libx265 -crf 28 -tag:v hvc1 output.mp4
```

### 10-bit Encoding

```bash
ffmpeg -i input.mov -c:v libx265 -crf 20 -pix_fmt yuv420p10le output.mp4
```

## VP9 (libvpx-vp9)

Royalty-free, optimized for web streaming. Used by YouTube.

### Constant Quality

```bash
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm
```

**Note**: `-b:v 0` is required for CRF mode.

### Two-Pass (Better Compression)

```bash
# Pass 1
ffmpeg -i input.mp4 -c:v libvpx-vp9 -b:v 2M -pass 1 -an -f null /dev/null

# Pass 2
ffmpeg -i input.mp4 -c:v libvpx-vp9 -b:v 2M -pass 2 -c:a libopus output.webm
```

### Speed/Quality Trade-off

```bash
# cpu-used: 0 (best quality, slow) to 8 (fastest, lower quality)
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -cpu-used 2 output.webm
```

## AV1 (libaom-av1)

Best compression, but very slow. Future standard.

```bash
ffmpeg -i input.mp4 -c:v libaom-av1 -crf 30 -cpu-used 6 output.mp4
```

## Audio Codecs

| Codec | Encoder | Quality | Compatibility |
|-------|---------|---------|---------------|
| AAC | aac | Good | Universal |
| AAC | libfdk_aac | Better | Universal |
| MP3 | libmp3lame | Good | Universal |
| Opus | libopus | Best | WebM, modern |
| FLAC | flac | Lossless | Good |

### AAC

```bash
# Default encoder
ffmpeg -i input.wav -c:a aac -b:a 192k output.m4a

# Quality-based (libfdk_aac if available)
ffmpeg -i input.wav -c:a libfdk_aac -vbr 4 output.m4a
```

### MP3

```bash
# Quality scale: 0 (best) to 9 (worst)
ffmpeg -i input.wav -c:a libmp3lame -q:a 2 output.mp3

# Fixed bitrate
ffmpeg -i input.wav -c:a libmp3lame -b:a 320k output.mp3
```

### Opus

```bash
# Best for voice and music
ffmpeg -i input.wav -c:a libopus -b:a 128k output.opus
```

## Codec Comparison by Use Case

### Web Streaming

```bash
# Best compatibility
ffmpeg -i input.mov -c:v libx264 -crf 23 -movflags +faststart -c:a aac output.mp4

# Smaller files (if target supports)
ffmpeg -i input.mov -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm
```

### Archival

```bash
# High quality H.265
ffmpeg -i input.mov -c:v libx265 -crf 18 -preset slow -c:a flac output.mkv
```

### Mobile/Low Bandwidth

```bash
ffmpeg -i input.mov -c:v libx264 -crf 28 -preset fast \
  -vf "scale=854:480" -c:a aac -b:a 96k output.mp4
```

### Social Media

```bash
# Instagram/TikTok friendly
ffmpeg -i input.mov -c:v libx264 -crf 20 -preset slow \
  -profile:v high -level 4.2 \
  -pix_fmt yuv420p \
  -c:a aac -b:a 192k \
  output.mp4
```

## Platform Recommendations

| Platform | Video | Audio | Container |
|----------|-------|-------|-----------|
| YouTube | H.264 / VP9 | AAC | MP4 / WebM |
| Instagram | H.264 | AAC | MP4 |
| Twitter | H.264 | AAC | MP4 |
| Web (general) | H.264 | AAC | MP4 |
| Netflix | H.265 / AV1 | AAC / E-AC3 | Various |

## Check Available Encoders

```bash
# List all encoders
ffmpeg -encoders

# Check if specific encoder is available
ffmpeg -encoders | grep libx264
ffmpeg -encoders | grep nvenc
```

## Next Steps

- [Bitrate Control](bitrate.md) - CRF vs CBR vs VBR
- [Hardware Acceleration](hardware.md) - GPU encoding
