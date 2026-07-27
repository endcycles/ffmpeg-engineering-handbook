# Storyboards

Create visual summaries of video content using tiled frames.

## Basic Storyboard

### Scene-Based Grid

```bash
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)',scale=320:180,tile=4x4" \
  -frames:v 1 \
  storyboard.jpg
```

| Option | Meaning |
|--------|---------|
| `select='gt(scene,0.4)'` | Pick frames on scene changes |
| `scale=320:180` | Thumbnail size |
| `tile=4x4` | 4 columns × 4 rows |
| `-frames:v 1` | Output single image |

## Time-Based Storyboards

### Fixed Interval

```bash
# One frame every 10 seconds
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=240:135,tile=5x4" \
  -frames:v 1 \
  storyboard.jpg
```

### Specific Number of Frames

```bash
# Get duration and calculate interval for 20 frames
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4)
fps=$(echo "20 / $duration" | bc -l)

ffmpeg -i input.mp4 \
  -vf "fps=$fps,scale=240:135,tile=5x4" \
  -frames:v 1 \
  storyboard.jpg
```

## Keyframe Storyboards

### From I-Frames Only

```bash
ffmpeg -skip_frame nokey -i input.mp4 \
  -vf "scale=240:135,tile=5x4" \
  -fps_mode vfr \
  storyboard_%02d.jpg
```

**Note**: Creates multiple images if more frames than tile size.

### Single Sheet from Keyframes

```bash
ffmpeg -skip_frame nokey -i input.mp4 \
  -vf "select='isnan(prev_selected_t)+gte(t-prev_selected_t,5)',scale=240:135,tile=5x4" \
  -fps_mode vfr \
  -frames:v 1 \
  storyboard.jpg
```

## Scene Detection Storyboards

### Standard Scene Detection

```bash
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.3)',scale=320:180,tile=4x3" \
  -fps_mode vfr \
  -frames:v 1 \
  scenes.jpg
```

### With Minimum Gap

```bash
# At least 5 seconds between scenes
ffmpeg -i input.mp4 \
  -vf "select='gt(scene,0.4)*isnan(prev_selected_t)+gte(t-prev_selected_t,5)*gt(scene,0.4)',scale=320:180,tile=4x3" \
  -fps_mode vfr \
  -frames:v 1 \
  scenes.jpg
```

## Tile Layouts

### Common Sizes

| Tile | Frames | Use Case |
|------|--------|----------|
| 3x2 | 6 | Quick preview |
| 4x3 | 12 | Standard |
| 5x4 | 20 | Detailed |
| 6x5 | 30 | Long videos |
| 10x1 | 10 | Timeline strip |
| 1x10 | 10 | Vertical strip |

### With Padding

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=240:135,tile=5x4:padding=4:margin=4:color=gray" \
  -frames:v 1 \
  storyboard.jpg
```

| Option | Description |
|--------|-------------|
| `padding=4` | Space between tiles |
| `margin=4` | Border around grid |
| `color=gray` | Background color |

## With Timestamps

### Timecode Overlay

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/10,drawtext=text='%{pts\\:hms}':x=5:y=h-20:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.7,scale=240:135,tile=5x4" \
  -frames:v 1 \
  storyboard_timed.jpg
```

### Frame Number Overlay

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/10,drawtext=text='%{frame_num}':x=5:y=5:fontsize=14:fontcolor=white:box=1:boxcolor=black@0.5,scale=240:135,tile=5x4" \
  -frames:v 1 \
  storyboard.jpg
```

## Multiple Pages

### Auto-Generate Multiple Sheets

```bash
# Creates multiple files if needed
ffmpeg -i input.mp4 \
  -vf "fps=1/5,scale=240:135,tile=5x4" \
  storyboard_%02d.jpg
```

### Limit Total Frames

```bash
# Select at most 20 source thumbnails, then emit one 5x4 sheet
ffmpeg -i input.mp4 \
  -vf "fps=1/10,select='lt(n,20)',scale=240:135,tile=5x4" \
  -frames:v 1 \
  storyboard.jpg
```

## Video Sprites

For web video players (hover preview):

### Horizontal Sprite

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/2,scale=160:90,tile=30x1" \
  -frames:v 1 \
  sprite.jpg
```

### Vertical Sprite

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/2,scale=160:90,tile=1x30" \
  -frames:v 1 \
  sprite.jpg
```

### With Metadata (VTT)

This Bash script generates fixed 10x10 sprite pages and a WebVTT manifest:

```bash
#!/usr/bin/env bash

set -euo pipefail

video=${1:?"usage: sprite-vtt.sh VIDEO [OUTPUT_DIRECTORY]"}
output_dir=${2:-sprite-output}
interval=2
width=160
height=90
cols=10
rows=10

video_dir=$(cd -- "$(dirname -- "$video")" && pwd -P)
video_path="$video_dir/$(basename -- "$video")"
mkdir -p -- "$output_dir"
output_dir=$(cd -- "$output_dir" && pwd -P)

duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$video_path")

if ! awk -v value="$duration" 'BEGIN { exit !(value > 0) }'; then
  printf 'Could not determine a positive duration for %s\n' "$video" >&2
  exit 1
fi

(
  cd -- "$output_dir"
  ffmpeg -hide_banner -n -i "$video_path" \
    -vf "fps=1/$interval,scale=$width:$height,tile=${cols}x${rows}" \
    -fps_mode vfr sprite_%03d.jpg

  awk -v duration="$duration" -v interval="$interval" \
      -v width="$width" -v height="$height" -v cols="$cols" -v rows="$rows" '
    function stamp(t, h, m, s) {
      h = int(t / 3600)
      m = int((t - h * 3600) / 60)
      s = t - h * 3600 - m * 60
      return sprintf("%02d:%02d:%06.3f", h, m, s)
    }
    BEGIN {
      print "WEBVTT\n"
      frames = int((duration + interval - 0.000001) / interval)
      cells = cols * rows
      for (i = 0; i < frames; i++) {
        start = i * interval
        end = (i + 1) * interval
        if (end > duration) end = duration
        page = int(i / cells) + 1
        cell = i % cells
        x = (cell % cols) * width
        y = int(cell / cols) * height
        printf "%s --> %s\n", stamp(start), stamp(end)
        printf "sprite_%03d.jpg#xywh=%d,%d,%d,%d\n\n", page, x, y, width, height
      }
    }
  ' > thumbnails.vtt
)
```

The script probes duration, clamps the final cue, writes additional sprite
pages after 100 thumbnails, and keeps every `xywh` rectangle within its
referenced 1600x900 page.

## Chapter-Based Storyboards

If video has chapters:

```bash
# Extract chapter times
ffprobe -v error -show_chapters -of json input.mp4 > chapters.json

# Extract frame at each chapter start
# (requires parsing chapters.json)
```

## Quality Options

### JPEG Quality

```bash
# Higher quality (1-31, lower is better)
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=320:180,tile=4x3" \
  -q:v 2 \
  -frames:v 1 \
  storyboard.jpg
```

### PNG (Lossless)

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=320:180,tile=4x3" \
  -frames:v 1 \
  storyboard.png
```

### WebP

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/10,scale=320:180,tile=4x3" \
  -c:v libwebp -quality 85 \
  -frames:v 1 \
  storyboard.webp
```

## Batch Processing

### All Videos in Directory

```bash
for video in *.mp4; do
  ffmpeg -i "$video" \
    -vf "fps=1/10,scale=240:135,tile=5x4" \
    -frames:v 1 \
    "${video%.mp4}_storyboard.jpg"
done
```

### With Parallel Processing

```bash
find . -name "*.mp4" | parallel -j4 \
  'ffmpeg -i {} -vf "fps=1/10,scale=240:135,tile=5x4" -frames:v 1 {.}_storyboard.jpg'
```

## Custom Layouts

### Title Card + Storyboard

```bash
ffmpeg -i input.mp4 \
  -filter_complex \
    "[0:v]fps=1/10,scale=200:112,tile=5x3[grid]; \
     color=black:1200x800:d=1[bg]; \
     [bg]drawtext=text='Video Title':x=(w-text_w)/2:y=30:fontsize=36:fontcolor=white[title]; \
     [title][grid]overlay=(W-w)/2:80" \
  -frames:v 1 \
  storyboard_titled.jpg
```

### Vertical Timeline

```bash
ffmpeg -i input.mp4 \
  -vf "fps=1/30,scale=400:225,tile=1x10" \
  -frames:v 1 \
  timeline.jpg
```

## Scene Detection Sensitivity

| Threshold | Sensitivity | Result |
|-----------|-------------|--------|
| 0.1 | Very High | Many scenes |
| 0.3 | High | More scenes |
| 0.4 | Medium | Balanced |
| 0.5 | Low | Fewer scenes |
| 0.7 | Very Low | Major changes only |

```bash
# Very sensitive (many scenes)
-vf "select='gt(scene,0.2)'"

# Less sensitive (major scenes only)
-vf "select='gt(scene,0.6)'"
```

## Common Issues

### Too Many/Few Frames

Adjust scene threshold or fps:
```bash
# More frames
-vf "fps=1/5,..."  # Every 5 seconds

# Fewer frames
-vf "fps=1/30,..." # Every 30 seconds
```

### Black Frames

Skip dark frames:
```bash
-vf "blackframe=amount=98,metadata=select:key=lavfi.blackframe.pblack:value=0:function=less,..."
```

### Wrong Aspect Ratio

Force correct ratio:
```bash
-vf "scale=320:180:force_original_aspect_ratio=decrease,pad=320:180:(ow-iw)/2:(oh-ih)/2:black,..."
```

## Next Steps

- [Thumbnails](thumbnails.md) - Single frame extraction
- [GIFs](gifs.md) - Animated previews
