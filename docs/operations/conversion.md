# Format Conversion

Converting between formats is one of the most common FFmpeg operations. Understanding the difference between remuxing and transcoding is essential.

## Remuxing vs Transcoding

### Remuxing (Container Change Only)
- **Fast** - no re-encoding
- **No quality loss** - streams are copied
- **Limited** - only works with compatible containers

```bash
# MP4 to MKV (both support H.264 + AAC)
ffmpeg -i input.mp4 -c copy output.mkv

# MP4 to MOV
ffmpeg -i input.mp4 -c copy output.mov
```

### Transcoding (Codec Change)
- **Slow** - requires encoding
- **Quality decision** - you control the output quality
- **Flexible** - any format to any format

```bash
# AVI to MP4 with H.264
ffmpeg -i input.avi -c:v libx264 -c:a aac output.mp4
```

## Container Compatibility Matrix

| From/To | MP4 | MKV | MOV | WebM | AVI |
|---------|-----|-----|-----|------|-----|
| H.264 | ✓ | ✓ | ✓ | ✗ | ✓ |
| H.265 | ✓ | ✓ | ✓ | ✗ | ✗ |
| VP9 | ✗ | ✓ | ✗ | ✓ | ✗ |
| AAC | ✓ | ✓ | ✓ | ✗ | ✓ |
| MP3 | ✓ | ✓ | ✗ | ✗ | ✓ |
| Opus | ✗ | ✓ | ✗ | ✓ | ✗ |

## Common Conversions

### Video File Conversions

**Any format to MP4 (H.264 + AAC):**
```bash
ffmpeg -i input.avi -c:v libx264 -crf 23 -c:a aac -b:a 128k output.mp4
```

**MP4 to WebM (VP9 + Opus):**
```bash
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm
```

**Any format to MKV (preserving streams):**
```bash
ffmpeg -i input.mp4 -c copy output.mkv
```

**MP4 to GIF:**
```bash
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" output.gif
```

### Audio Conversions

**Any audio to MP3:**
```bash
ffmpeg -i input.wav -c:a libmp3lame -q:a 2 output.mp3
```

**Any audio to AAC:**
```bash
ffmpeg -i input.mp3 -c:a aac -b:a 192k output.m4a
```

**Any audio to WAV (PCM):**
```bash
ffmpeg -i input.mp3 -c:a pcm_s16le output.wav
```

**Any audio to FLAC (lossless):**
```bash
ffmpeg -i input.wav -c:a flac output.flac
```

### Image Sequence Conversions

**Video to images:**
```bash
# All frames as PNG
ffmpeg -i input.mp4 frame_%04d.png

# All frames as high-quality JPEG
ffmpeg -i input.mp4 -q:v 2 frame_%04d.jpg
```

**Images to video:**
```bash
# Numbered images to MP4
ffmpeg -framerate 30 -i frame_%04d.png -c:v libx264 -pix_fmt yuv420p output.mp4

# Glob pattern (requires -pattern_type glob)
ffmpeg -framerate 30 -pattern_type glob -i '*.png' -c:v libx264 -pix_fmt yuv420p output.mp4
```

## Quality Settings by Format

### H.264 (libx264)

```bash
# High quality (larger file)
ffmpeg -i input.avi -c:v libx264 -crf 18 -preset slow output.mp4

# Balanced quality/size
ffmpeg -i input.avi -c:v libx264 -crf 23 -preset medium output.mp4

# Smaller file (lower quality)
ffmpeg -i input.avi -c:v libx264 -crf 28 -preset fast output.mp4
```

### H.265 (libx265)

```bash
# 50% smaller than H.264 at same quality
ffmpeg -i input.avi -c:v libx265 -crf 28 -preset medium output.mp4

# For Apple device compatibility
ffmpeg -i input.avi -c:v libx265 -crf 28 -tag:v hvc1 output.mp4
```

### VP9 (libvpx-vp9)

```bash
# Constant quality mode
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 output.webm

# Two-pass for better compression
ffmpeg -i input.mp4 -c:v libvpx-vp9 -b:v 2M -pass 1 -an -f null /dev/null
ffmpeg -i input.mp4 -c:v libvpx-vp9 -b:v 2M -pass 2 -c:a libopus output.webm
```

### Audio Quality

```bash
# MP3 quality scale (0-9, lower is better)
ffmpeg -i input.wav -c:a libmp3lame -q:a 0 output.mp3   # ~245 kbps
ffmpeg -i input.wav -c:a libmp3lame -q:a 2 output.mp3   # ~190 kbps
ffmpeg -i input.wav -c:a libmp3lame -q:a 4 output.mp3   # ~165 kbps

# AAC bitrates
ffmpeg -i input.wav -c:a aac -b:a 256k output.m4a  # High quality
ffmpeg -i input.wav -c:a aac -b:a 192k output.m4a  # Good quality
ffmpeg -i input.wav -c:a aac -b:a 128k output.m4a  # Acceptable
```

## Handling Incompatibilities

### Pixel Format Issues

Some players can't handle certain pixel formats:

```bash
# Force compatible pixel format
ffmpeg -i input.mov -c:v libx264 -pix_fmt yuv420p output.mp4
```

### Frame Rate Issues

```bash
# Force specific frame rate
ffmpeg -i input.avi -c:v libx264 -r 30 output.mp4
```

### Aspect Ratio Issues

```bash
# Force square pixels
ffmpeg -i input.avi -c:v libx264 -vf "setsar=1:1" output.mp4
```

## Multi-Format Output

Generate multiple formats in one command:

```bash
ffmpeg -i input.mov \
  -c:v libx264 -crf 23 -c:a aac output.mp4 \
  -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm
```

## Probing Before Converting

Always check the input first:

```bash
# Quick format info
ffprobe -v error -show_format input.mp4

# Detailed stream info
ffprobe -v error -show_streams input.mp4

# JSON output for parsing
ffprobe -v error -print_format json -show_format -show_streams input.mp4
```

## Common Gotchas

### 1. Missing Codec

```
Unknown encoder 'libx264'
```
**Solution**: Install FFmpeg with proper codecs or use available encoder.

### 2. Container Doesn't Support Codec

```
Could not find tag for codec h264 in stream #0
```
**Solution**: Use compatible container or transcode to compatible codec.

### 3. Audio/Video Sync Issues

```bash
# Re-encode with timestamp correction
ffmpeg -i input.avi -c:v libx264 -c:a aac -async 1 output.mp4
```

### 4. Variable Frame Rate to Constant

```bash
# Convert VFR to CFR
ffmpeg -i input.mp4 -c:v libx264 -vsync cfr -r 30 output.mp4
```

## Next Steps

- [Trimming & Cutting](trimming.md) - Extract portions of media
- [Codec Selection](../optimization/codecs.md) - Deep dive into codec choices
