# Resizing & Scaling

Changing video resolution while maintaining quality and aspect ratio is a common requirement for multi-platform delivery.

## Basic Scaling

### Fixed Dimensions

```bash
# Scale to exact size (may distort)
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4
```

### Preserve Aspect Ratio

```bash
# Auto-calculate height to preserve ratio
ffmpeg -i input.mp4 -vf "scale=1280:-1" output.mp4

# Auto-calculate width
ffmpeg -i input.mp4 -vf "scale=-1:720" output.mp4

# Force even dimensions (required for most codecs)
ffmpeg -i input.mp4 -vf "scale=1280:-2" output.mp4
ffmpeg -i input.mp4 -vf "scale=-2:720" output.mp4
```

**Important**: Most codecs require even dimensions. Use `-2` instead of `-1`.

## Fit vs Fill

### Fit (Letterbox/Pillarbox)

Scale to fit within bounds, add padding:

```bash
# Fit in 1920x1080, add black bars
ffmpeg -i input.mp4 -vf \
  "scale=1920:1080:force_original_aspect_ratio=decrease,\
   pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black" \
  output.mp4
```

| Parameter | Meaning |
|-----------|---------|
| `force_original_aspect_ratio=decrease` | Scale down to fit |
| `pad=width:height:x:y:color` | Add padding |
| `(ow-iw)/2` | Center horizontally |
| `(oh-ih)/2` | Center vertically |

### Fill (Crop to Fit)

Scale to fill, crop excess:

```bash
# Fill 1920x1080, crop overflow
ffmpeg -i input.mp4 -vf \
  "scale=1920:1080:force_original_aspect_ratio=increase,\
   crop=1920:1080" \
  output.mp4
```

## Social Media Formats

### YouTube (16:9)

```bash
# 1080p
ffmpeg -i input.mp4 -vf \
  "scale=1920:1080:force_original_aspect_ratio=decrease,\
   pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,\
   setsar=1:1" \
  -c:v libx264 -crf 18 -c:a aac output_youtube.mp4

# 720p
ffmpeg -i input.mp4 -vf \
  "scale=1280:720:force_original_aspect_ratio=decrease,\
   pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,\
   setsar=1:1" \
  output_youtube_720.mp4
```

### Instagram/TikTok (9:16)

```bash
# 1080x1920 vertical
ffmpeg -i input.mp4 -vf \
  "scale=1080:1920:force_original_aspect_ratio=decrease,\
   pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,\
   setsar=1:1" \
  output_vertical.mp4
```

### Instagram Square (1:1)

```bash
# 1080x1080
ffmpeg -i input.mp4 -vf \
  "scale=1080:1080:force_original_aspect_ratio=decrease,\
   pad=1080:1080:(ow-iw)/2:(oh-ih)/2:black,\
   setsar=1:1" \
  output_square.mp4
```

### Twitter/X

```bash
# 1280x720 or 720x1280 (landscape or portrait)
ffmpeg -i input.mp4 -vf \
  "scale=1280:720:force_original_aspect_ratio=decrease,\
   pad=1280:720:(ow-iw)/2:(oh-ih)/2:black" \
  output_twitter.mp4
```

## Multiple Outputs

Generate multiple sizes in one command:

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 output_1080p.mp4 \
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 output_720p.mp4 \
  -vf "scale=854:480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 output_480p.mp4
```

Using split for efficiency:

```bash
ffmpeg -i input.mp4 -filter_complex \
  "[0:v]split=3[v1][v2][v3]; \
   [v1]scale=1920:-2[out1]; \
   [v2]scale=1280:-2[out2]; \
   [v3]scale=854:-2[out3]" \
  -map "[out1]" -map 0:a output_1080p.mp4 \
  -map "[out2]" -map 0:a output_720p.mp4 \
  -map "[out3]" -map 0:a output_480p.mp4
```

## Cropping

### Fixed Crop

```bash
# crop=width:height:x:y
ffmpeg -i input.mp4 -vf "crop=640:480:100:50" output.mp4
```

### Center Crop

```bash
# Crop to center 1280x720
ffmpeg -i input.mp4 -vf "crop=1280:720" output.mp4

# Explicit center
ffmpeg -i input.mp4 -vf "crop=1280:720:(in_w-1280)/2:(in_h-720)/2" output.mp4
```

### Crop to Aspect Ratio

```bash
# Crop to 16:9
ffmpeg -i input.mp4 -vf "crop=ih*16/9:ih" output.mp4

# Crop to 9:16 (vertical)
ffmpeg -i input.mp4 -vf "crop=ih*9/16:ih" output.mp4

# Crop to 1:1 (square)
ffmpeg -i input.mp4 -vf "crop=min(iw\,ih):min(iw\,ih)" output.mp4
```

### Dynamic Crop (Ken Burns)

```bash
# Animated crop position over time
ffmpeg -i input.mp4 -vf \
  "crop=640:480:t*10:(in_h-480)/2" \
  output.mp4
```

## Upscaling

### Basic Upscale

```bash
ffmpeg -i input_480p.mp4 -vf "scale=1920:1080" output_1080p.mp4
```

### With Lanczos (Higher Quality)

```bash
ffmpeg -i input.mp4 -vf "scale=1920:1080:flags=lanczos" output.mp4
```

### Scaling Algorithms

| Flag | Quality | Speed | Best For |
|------|---------|-------|----------|
| `fast_bilinear` | Low | Fastest | Preview |
| `bilinear` | Low | Fast | Real-time |
| `bicubic` | Good | Medium | General |
| `lanczos` | Best | Slow | Final output |
| `spline` | Best | Slow | Animation |

```bash
# High quality upscale
ffmpeg -i input.mp4 -vf "scale=1920:1080:flags=lanczos+accurate_rnd" output.mp4
```

## Aspect Ratio Handling

### SAR vs DAR

- **SAR** (Sample Aspect Ratio): Pixel shape
- **DAR** (Display Aspect Ratio): Final display ratio

```bash
# Force square pixels (SAR 1:1)
ffmpeg -i input.mp4 -vf "setsar=1:1" output.mp4

# Set display aspect ratio
ffmpeg -i input.mp4 -vf "setdar=16/9" output.mp4
```

### Anamorphic Content

```bash
# Squeeze anamorphic to proper ratio
ffmpeg -i anamorphic.mp4 -vf "scale=iw*sar:ih,setsar=1:1" output.mp4
```

## Conditional Scaling

### Scale Only If Larger

```bash
# Scale to 1080p only if input is larger
ffmpeg -i input.mp4 -vf \
  "scale='min(1920,iw)':min'(1080,ih)':force_original_aspect_ratio=decrease" \
  output.mp4
```

### Scale with Minimum Size

```bash
# Ensure at least 720p
ffmpeg -i input.mp4 -vf \
  "scale='max(1280,iw)':'max(720,ih)':force_original_aspect_ratio=decrease" \
  output.mp4
```

## Combining Operations

### Scale, Crop, Pad

```bash
# Crop 16:9 from center, then scale and pad to 1080p
ffmpeg -i input.mp4 -vf \
  "crop=ih*16/9:ih,\
   scale=1920:1080:force_original_aspect_ratio=decrease,\
   pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,\
   setsar=1:1" \
  output.mp4
```

### Different Crops for Different Segments

```bash
ffmpeg -i input.mp4 -filter_complex \
  "[0:v]split=3[s0][s1][s2]; \
   [s0]trim=0:10,setpts=PTS-STARTPTS,crop=480:720:0:0,scale=720:1080[v0]; \
   [s1]trim=10:20,setpts=PTS-STARTPTS,crop=480:720:300:0,scale=720:1080[v1]; \
   [s2]trim=20:30,setpts=PTS-STARTPTS,crop=480:720:600:0,scale=720:1080[v2]; \
   [v0][v1][v2]concat=n=3:v=1[v]" \
  -map "[v]" output.mp4
```

## Hardware Accelerated Scaling

### NVIDIA

```bash
ffmpeg -hwaccel cuda -i input.mp4 -vf "scale_npp=1920:1080" -c:v h264_nvenc output.mp4
```

### Intel QSV

```bash
ffmpeg -hwaccel qsv -i input.mp4 -vf "scale_qsv=1920:1080" -c:v h264_qsv output.mp4
```

## Common Issues

### Black Bars on Sides (Pillarbox)

Use crop instead of pad, or fill mode.

### Blurry Output

Use better scaling algorithm: `-vf "scale=1920:1080:flags=lanczos"`

### Stretched/Squished Video

Add `setsar=1:1` after scaling.

### Odd Dimensions Error

Use `-2` for auto-dimension: `scale=1920:-2`

## Next Steps

- [Concatenation](concatenation.md) - Join scaled videos
- [Social Media Crops](../advanced/social-crops.md) - Platform-specific formatting
