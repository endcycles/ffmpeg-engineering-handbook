# GIFs

Create animated GIFs from video for social media, documentation, and web content.

## Basic GIF Creation

### Simple Conversion

```bash
ffmpeg -i input.mp4 output.gif
```

**Warning**: This creates large, low-quality GIFs. Use the techniques below for better results.

### With Size and Frame Rate

```bash
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" output.gif
```

## High Quality GIFs

### Two-Pass Palette Method

The key to good GIFs is a custom color palette:

```bash
# Pass 1: Generate palette
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1:flags=lanczos,palettegen" palette.png

# Pass 2: Use palette
ffmpeg -i input.mp4 -i palette.png \
  -filter_complex "[0:v]fps=10,scale=480:-1:flags=lanczos[v];[v][1:v]paletteuse" \
  output.gif
```

### Single Command (Simpler)

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## Palette Options

### Stats Mode

| Mode | Description |
|------|-------------|
| `full` | Global palette (default, smaller file) |
| `diff` | Per-frame palette (better quality, larger) |
| `single` | Single frame reference |

```bash
# Per-frame palette (best quality)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]fps=10,scale=480:-1,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer" \
  output.gif
```

### Dithering

| Dither | Description |
|--------|-------------|
| `bayer` | Ordered dithering (grid pattern) |
| `floyd_steinberg` | Error diffusion (smooth, default) |
| `sierra2` | Sierra-2 dithering |
| `none` | No dithering (banding) |

```bash
# Bayer dithering (good for graphics)
-filter_complex "...[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3"

# No dithering (flat colors)
-filter_complex "...[p];[s1][p]paletteuse=dither=none"
```

## Time Selection

### Specific Segment

```bash
# 3 seconds starting at 10 seconds
ffmpeg -ss 10 -t 3 -i input.mp4 \
  -filter_complex "fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Trim with Filter

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]trim=10:13,setpts=PTS-STARTPTS,fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## Size Optimization

### Reduce Frame Rate

```bash
# Fewer fps = smaller file
-vf "fps=8,scale=320:-1"   # Very small
-vf "fps=12,scale=480:-1"  # Balanced
-vf "fps=15,scale=640:-1"  # Higher quality
```

### Reduce Colors

```bash
# Limit palette (default is 256)
-vf "palettegen=max_colors=128"
-vf "palettegen=max_colors=64"   # Very small
```

### Reduce Dimensions

| Width | Use Case |
|-------|----------|
| 320 | Inline icons, thumbnails |
| 480 | Chat, social inline |
| 640 | Standard web |
| 800+ | High quality demo |

### Skip Frames

```bash
# Every other frame
ffmpeg -i input.mp4 \
  -vf "select='not(mod(n,2))',setpts=N/FRAME_RATE/TB,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## Looping

### Infinite Loop (Default)

```bash
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" -loop 0 output.gif
```

### Specific Loop Count

```bash
# Loop 3 times then stop
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" -loop 3 output.gif

# Play once (no loop)
ffmpeg -i input.mp4 -vf "fps=10,scale=480:-1" -loop -1 output.gif
```

## Effects

### Crop to Square

```bash
ffmpeg -i input.mp4 \
  -filter_complex "crop=min(iw\,ih):min(iw\,ih),fps=10,scale=480:480,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Fade In/Out

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]trim=0:3,setpts=PTS-STARTPTS,fps=10,scale=480:-1,fade=t=in:d=0.5,fade=t=out:st=2.5:d=0.5,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Speed Change

```bash
# 2x speed
ffmpeg -i input.mp4 \
  -filter_complex "setpts=0.5*PTS,fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Reverse

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]trim=0:3,setpts=PTS-STARTPTS,reverse,fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Ping-Pong (Forward + Reverse)

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]trim=0:2,setpts=PTS-STARTPTS[clip];[clip]split[a][b];[b]reverse[r];[a][r]concat,fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Add Text

```bash
ffmpeg -i input.mp4 \
  -filter_complex "fps=10,scale=480:-1,drawtext=text='Demo':x=10:y=10:fontsize=24:fontcolor=white,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## From Images

### Image Sequence to GIF

```bash
# From numbered images
ffmpeg -framerate 10 -i frame_%04d.png \
  -filter_complex "scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif

# From glob pattern
ffmpeg -framerate 10 -pattern_type glob -i '*.png' \
  -filter_complex "scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

### Custom Duration Per Image

```bash
# Each image for 1 second
ffmpeg -framerate 1 -i frame_%04d.png \
  -filter_complex "fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  slideshow.gif
```

## Alternatives to GIF

### WebP (Better Compression)

```bash
ffmpeg -i input.mp4 \
  -vf "fps=10,scale=480:-1" \
  -c:v libwebp -loop 0 -quality 75 \
  output.webp
```

### MP4 (Best Quality/Size)

```bash
# Short looping video (better than GIF in every way)
ffmpeg -i input.mp4 -t 3 \
  -vf "scale=480:-2" \
  -c:v libx264 -an -pix_fmt yuv420p \
  -movflags +faststart \
  output.mp4
```

## File Size Comparison

For a typical 5-second clip:

| Format | Estimated Size |
|--------|----------------|
| GIF (naive) | 10-50 MB |
| GIF (optimized) | 2-10 MB |
| WebP animated | 1-5 MB |
| MP4 (H.264) | 200-500 KB |

## Batch Processing

```bash
for video in *.mp4; do
  ffmpeg -ss 0 -t 3 -i "$video" \
    -filter_complex "fps=10,scale=320:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    "${video%.mp4}.gif"
done
```

## Compression Tips

1. **Shorter duration** = smaller file
2. **Lower fps** (8-12 is usually fine)
3. **Smaller dimensions** (480px or less)
4. **Fewer colors** (max_colors=128)
5. **Use diff mode** for static backgrounds
6. **Optimize with gifsicle** after creation:

```bash
gifsicle -O3 --colors 128 input.gif -o optimized.gif
```

## Platform Requirements

| Platform | Max Size | Recommended |
|----------|----------|-------------|
| Twitter | 15 MB | < 5 MB |
| Slack | 10 MB | < 3 MB |
| Discord | 8 MB | < 3 MB |
| GitHub | 10 MB | < 5 MB |
| Email | Varies | < 1 MB |

## Common Issues

### Banding

Use dithering:
```bash
paletteuse=dither=floyd_steinberg
```

### Wrong Colors

Use per-frame palette:
```bash
palettegen=stats_mode=diff
```

### Too Large

Reduce: dimensions, fps, duration, or color count.

### Not Looping

Ensure `-loop 0` (or omit for default infinite loop).

## Next Steps

- [Slideshows](slideshows.md) - Image sequences to video
- [Thumbnails](thumbnails.md) - Static frame extraction
