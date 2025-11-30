# Thumbnails

Extract frames from video for thumbnails, previews, and promotional images.

## Single Frame Extraction

### At Specific Time

```bash
# Frame at 5 seconds
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 thumbnail.jpg

# At 1 minute 30 seconds
ffmpeg -i input.mp4 -ss 00:01:30 -frames:v 1 thumbnail.jpg
```

### High Quality JPEG

```bash
# -q:v ranges from 1 (best) to 31 (worst)
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 -q:v 2 thumbnail.jpg
```

### PNG (Lossless)

```bash
ffmpeg -i input.mp4 -ss 00:00:05 -frames:v 1 thumbnail.png
```

### With Scaling

```bash
# Scale to 640px width, maintain aspect ratio
ffmpeg -i input.mp4 -ss 5 -frames:v 1 -vf "scale=640:-1" thumbnail.jpg

# Fixed dimensions with letterbox
ffmpeg -i input.mp4 -ss 5 -frames:v 1 \
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:-1:-1:black" \
  thumbnail.jpg
```

## Multiple Thumbnails

### At Regular Intervals

```bash
# One frame per second
ffmpeg -i input.mp4 -vf "fps=1" thumb_%04d.jpg

# One frame every 5 seconds
ffmpeg -i input.mp4 -vf "fps=1/5" thumb_%04d.jpg

# One frame every 10 seconds with quality
ffmpeg -i input.mp4 -vf "fps=1/10" -q:v 2 thumb_%04d.jpg
```

### Specific Number of Thumbnails

```bash
# First, get duration
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4)

# Calculate interval for 10 thumbnails
interval=$(echo "$duration / 10" | bc -l)

# Extract
ffmpeg -i input.mp4 -vf "fps=1/$interval" -q:v 2 thumb_%02d.jpg
```

### At Specific Times

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split=3[a][b][c];[a]select='gte(t,5)'[t1];[b]select='gte(t,15)'[t2];[c]select='gte(t,30)'[t3]" \
  -map "[t1]" -frames:v 1 thumb_05.jpg \
  -map "[t2]" -frames:v 1 thumb_15.jpg \
  -map "[t3]" -frames:v 1 thumb_30.jpg
```

## Scene Change Detection

### Extract on Scene Changes

```bash
# Sensitivity: 0 (most sensitive) to 1 (least)
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)'" \
  -vsync vfr \
  -q:v 2 \
  scene_%04d.jpg
```

### First Frame After Scene Change

```bash
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)',thumbnail" \
  -frames:v 1 \
  best_scene.jpg
```

### Scene Changes with Limit

```bash
# Maximum 20 scene thumbnails
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)'" \
  -vsync vfr \
  -frames:v 20 \
  scene_%02d.jpg
```

## Keyframe Extraction

### Extract Only Keyframes

```bash
# I-frames only (fast, no decoding of other frames)
ffmpeg -skip_frame nokey -i input.mp4 \
  -vsync 0 \
  keyframe_%04d.jpg

# With quality
ffmpeg -skip_frame nokey -i input.mp4 \
  -vsync 0 -q:v 2 \
  keyframe_%04d.jpg
```

## Thumbnail Selection

### Automatic "Best" Frame (thumbnail filter)

```bash
# Analyzes 100 frames, picks most representative
ffmpeg -i input.mp4 -vf "thumbnail=100" -frames:v 1 best.jpg

# From middle portion
ffmpeg -ss 00:00:30 -i input.mp4 -t 60 \
  -vf "thumbnail=100" -frames:v 1 best.jpg
```

### Multiple "Best" Frames

```bash
# One "best" frame per 100 frames
ffmpeg -i input.mp4 \
  -vf "thumbnail=100" \
  -vsync 0 \
  thumb_%04d.jpg
```

## Animated Thumbnails

### GIF Preview

```bash
# 3-second animated thumbnail
ffmpeg -ss 10 -t 3 -i input.mp4 \
  -vf "fps=10,scale=320:-1:flags=lanczos" \
  preview.gif
```

### WebP Preview (Smaller)

```bash
ffmpeg -ss 10 -t 3 -i input.mp4 \
  -vf "fps=10,scale=320:-1" \
  -loop 0 \
  preview.webp
```

### Video Preview (MP4)

```bash
# 5-second silent preview
ffmpeg -ss 10 -t 5 -i input.mp4 \
  -vf "scale=320:-2" \
  -an -c:v libx264 -crf 28 \
  preview.mp4
```

## Storyboards and Contact Sheets

### Basic Tile Grid

```bash
# 4x4 grid of scenes
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.3)',scale=320:180,tile=4x4" \
  -frames:v 1 \
  storyboard.jpg
```

### Tiled Keyframes

```bash
# Grid from keyframes
ffmpeg -skip_frame nokey -i input.mp4 \
  -vf "scale=240:135,tile=5x4" \
  -frames:v 1 \
  contact_sheet.jpg
```

### Time-Based Tiles

```bash
# One frame every 10 seconds in 4x3 grid
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=320:180,tile=4x3" \
  -frames:v 1 \
  timeline.jpg
```

### Multiple Contact Sheets

```bash
# If video has more frames than fit in one sheet
ffmpeg -i input.mp4 \
  -vf "fps=1/5,scale=240:135,tile=5x4" \
  sheet_%02d.jpg
```

## Video Sprites

For web video players (hover previews):

```bash
# Horizontal sprite strip
ffmpeg -i input.mp4 \
  -vf "fps=1/5,scale=160:90,tile=20x1" \
  sprite.jpg

# Vertical sprite
ffmpeg -i input.mp4 \
  -vf "fps=1/5,scale=160:90,tile=1x20" \
  sprite_vertical.jpg
```

## Batch Thumbnails

### From Multiple Videos

```bash
for video in *.mp4; do
  ffmpeg -ss 5 -i "$video" -frames:v 1 -q:v 2 "${video%.mp4}_thumb.jpg"
done
```

### Multiple Thumbnails Per Video

```bash
for video in *.mp4; do
  base="${video%.mp4}"
  ffmpeg -i "$video" -vf "fps=1/30" -q:v 2 "${base}_thumb_%02d.jpg"
done
```

## Overlay Information

### Add Timestamp

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/10,drawtext=text='%{pts\\:hms}':x=10:y=10:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5" \
  thumb_%03d.jpg
```

### Add Filename

```bash
ffmpeg -i input.mp4 -ss 5 -frames:v 1 \
  -vf "drawtext=text='input.mp4':x=10:y=h-30:fontsize=18:fontcolor=white:box=1:boxcolor=black@0.5" \
  thumb.jpg
```

## Quality and Format

### JPEG Quality

| -q:v | Quality | File Size |
|------|---------|-----------|
| 1-2 | Excellent | Large |
| 3-5 | Very Good | Medium |
| 6-10 | Good | Small |
| 11-31 | Poor | Tiny |

### Format Comparison

| Format | Best For | Transparency |
|--------|----------|--------------|
| JPEG | Photos, complex scenes | No |
| PNG | Graphics, screenshots | Yes |
| WebP | Web delivery | Yes |

### WebP Thumbnails

```bash
ffmpeg -i input.mp4 -ss 5 -frames:v 1 \
  -c:v libwebp -quality 90 \
  thumbnail.webp
```

## Performance Tips

1. **Use input seeking** (`-ss` before `-i`) for faster extraction
2. **Use `-skip_frame nokey`** for keyframe-only extraction
3. **Lower resolution** for faster processing
4. **Limit output frames** with `-frames:v`

```bash
# Fast thumbnail extraction
ffmpeg -ss 30 -i input.mp4 -frames:v 1 -q:v 3 thumb.jpg
```

## Common Issues

### Black Frames

Video starts with fade-in:
```bash
# Skip first few seconds
ffmpeg -ss 5 -i input.mp4 -frames:v 1 thumb.jpg
```

### Wrong Aspect Ratio

Force correct SAR:
```bash
ffmpeg -i input.mp4 -ss 5 -frames:v 1 -vf "setsar=1:1" thumb.jpg
```

### Color Shift

Specify pixel format:
```bash
ffmpeg -i input.mp4 -ss 5 -frames:v 1 -pix_fmt yuvj420p thumb.jpg
```

## Next Steps

- [GIFs](gifs.md) - Animated thumbnail creation
- [Storyboards](storyboards.md) - Video previews and summaries
