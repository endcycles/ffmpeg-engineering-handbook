# Overlays & Compositing

Layer videos, images, and graphics to create complex compositions.

## Basic Overlay

### Image on Video

```bash
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=10:10" \
  output.mp4
```

### Video on Video (Picture-in-Picture)

```bash
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "[1:v]scale=320:180[pip];[0:v][pip]overlay=main_w-overlay_w-10:10" \
  output.mp4
```

## Positioning

### Coordinates

```
overlay=x:y
```

| Position | X | Y |
|----------|---|---|
| Top-left | 0 | 0 |
| Top-right | `main_w-overlay_w` | 0 |
| Bottom-left | 0 | `main_h-overlay_h` |
| Bottom-right | `main_w-overlay_w` | `main_h-overlay_h` |
| Center | `(main_w-overlay_w)/2` | `(main_h-overlay_h)/2` |

### Common Positions

```bash
# Top-left corner
overlay=0:0

# Top-right with padding
overlay=main_w-overlay_w-10:10

# Bottom-left with padding
overlay=10:main_h-overlay_h-10

# Bottom-right with padding
overlay=main_w-overlay_w-10:main_h-overlay_h-10

# Centered
overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2
```

### Dynamic Position (Moving Overlay)

```bash
# Scroll from left to right
ffmpeg -i video.mp4 -i overlay.png \
  -filter_complex "overlay=x='t*50':y=10" \
  output.mp4

# Bounce effect
ffmpeg -i video.mp4 -i overlay.png \
  -filter_complex "overlay=x='(main_w-overlay_w)/2+sin(t*2)*100':y='(main_h-overlay_h)/2'" \
  output.mp4
```

## Transparency

### Image with Alpha Channel

```bash
# PNG with transparency
ffmpeg -i video.mp4 -i logo_transparent.png \
  -filter_complex "overlay=10:10" \
  output.mp4
```

### Adjust Overlay Transparency

```bash
# Make overlay 50% transparent
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[1:v]format=argb,geq=p(X,Y):a='0.5*alpha(X,Y)'[logo];[0:v][logo]overlay=10:10" \
  output.mp4
```

### Fade Overlay In/Out

```bash
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[1:v]fade=t=in:d=1:alpha=1,fade=t=out:st=4:d=1:alpha=1[logo];[0:v][logo]overlay=10:10:enable='between(t,0,5)'" \
  output.mp4
```

## Timed Overlays

### Show at Specific Times

```bash
# Show from 2s to 8s
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=10:10:enable='between(t,2,8)'" \
  output.mp4

# Multiple time windows
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "overlay=10:10:enable='between(t,2,5)+between(t,10,15)'" \
  output.mp4
```

### Multiple Overlays at Different Times

```bash
ffmpeg -i video.mp4 -i logo1.png -i logo2.png \
  -filter_complex \
    "[0:v][1:v]overlay=10:10:enable='between(t,0,5)'[v1]; \
     [v1][2:v]overlay=10:10:enable='between(t,5,10)'" \
  output.mp4
```

## Multiple Overlays

### Chain Overlays

```bash
ffmpeg -i video.mp4 -i logo.png -i watermark.png \
  -filter_complex \
    "[0:v][1:v]overlay=10:10[v1]; \
     [v1][2:v]overlay=main_w-overlay_w-10:main_h-overlay_h-10" \
  output.mp4
```

### Grid of Overlays

```bash
ffmpeg -i video.mp4 -i img.png \
  -filter_complex \
    "[0:v][1:v]overlay=0:0[v1]; \
     [v1][1:v]overlay=100:0[v2]; \
     [v2][1:v]overlay=200:0[v3]; \
     [v3][1:v]overlay=0:100" \
  output.mp4
```

## Picture-in-Picture

### Basic PiP

```bash
ffmpeg -i main.mp4 -i small.mp4 \
  -filter_complex "[1:v]scale=320:180[pip];[0:v][pip]overlay=main_w-overlay_w-10:10[v]" \
  -map "[v]" -map 0:a output.mp4
```

### PiP with Border

```bash
ffmpeg -i main.mp4 -i small.mp4 \
  -filter_complex \
    "[1:v]scale=320:180,pad=324:184:2:2:white[pip]; \
     [0:v][pip]overlay=main_w-overlay_w-10:10" \
  output.mp4
```

### Rounded PiP

```bash
ffmpeg -i main.mp4 -i small.mp4 \
  -filter_complex \
    "[1:v]scale=320:180,format=rgba,geq=a='if(gt(hypot(X-W/2,Y-H/2),min(W/2,H/2)),0,255)':r='r(X,Y)':g='g(X,Y)':b='b(X,Y)'[pip]; \
     [0:v][pip]overlay=main_w-overlay_w-10:10" \
  output.mp4
```

### Moving PiP

```bash
# PiP moves across screen
ffmpeg -i main.mp4 -i small.mp4 \
  -filter_complex \
    "[1:v]scale=320:180[pip]; \
     [0:v][pip]overlay=x='10+t*20':y=10" \
  output.mp4
```

## Side by Side

### Horizontal

```bash
ffmpeg -i left.mp4 -i right.mp4 \
  -filter_complex "[0:v]scale=640:480[l];[1:v]scale=640:480[r];[l][r]hstack" \
  output.mp4
```

### Vertical

```bash
ffmpeg -i top.mp4 -i bottom.mp4 \
  -filter_complex "[0:v]scale=640:360[t];[1:v]scale=640:360[b];[t][b]vstack" \
  output.mp4
```

### Grid (2x2)

```bash
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 \
  -filter_complex \
    "[0:v]scale=640:360[v0];[1:v]scale=640:360[v1];[2:v]scale=640:360[v2];[3:v]scale=640:360[v3]; \
     [v0][v1]hstack[top];[v2][v3]hstack[bottom];[top][bottom]vstack" \
  output.mp4
```

## Background Replacement

### Video on Image Background

```bash
ffmpeg -i video.mp4 -i background.png \
  -filter_complex \
    "[0:v]scale=960:540[vid]; \
     [1:v][vid]overlay=(W-w)/2:(H-h)/2" \
  output.mp4
```

### Video on Video Background

```bash
ffmpeg -i foreground.mp4 -i background.mp4 \
  -filter_complex \
    "[0:v]scale=640:360[fg]; \
     [1:v][fg]overlay=(W-w)/2:(H-h)/2:shortest=1" \
  output.mp4
```

## Green Screen (Chroma Key)

```bash
# Remove green background
ffmpeg -i greenscreen.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x00FF00:0.1:0.2[fg];[1:v][fg]overlay[out]" \
  -map "[out]" -map 1:a output.mp4
```

| Parameter | Meaning |
|-----------|---------|
| `0x00FF00` | Color to key out (green) |
| `0.1` | Similarity threshold |
| `0.2` | Blend amount |

### Blue Screen

```bash
ffmpeg -i bluescreen.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x0000FF:0.1:0.2[fg];[1:v][fg]overlay" \
  output.mp4
```

## Mask/Matte

### Apply Alpha Mask

```bash
ffmpeg -i video.mp4 -i mask.png \
  -filter_complex "[0:v][1:v]alphamerge" \
  output.mov
```

### Combine with Background

```bash
ffmpeg -i video.mp4 -i mask.png -i background.mp4 \
  -filter_complex "[0:v][1:v]alphamerge[masked];[2:v][masked]overlay" \
  output.mp4
```

## Blend Modes

```bash
# Multiply blend
ffmpeg -i bottom.mp4 -i top.mp4 \
  -filter_complex "blend=all_mode=multiply" \
  output.mp4

# Available modes: addition, and, average, burn, darken, difference,
# divide, dodge, exclusion, glow, hardlight, hardmix, lighten,
# multiply, negation, normal, overlay, phoenix, pinlight, reflect,
# screen, softlight, subtract, vividlight, xor
```

## Lower Thirds

```bash
ffmpeg -i video.mp4 -i lower_third.png \
  -filter_complex \
    "[1:v]fade=t=in:d=0.5:alpha=1,fade=t=out:st=4.5:d=0.5:alpha=1[lt]; \
     [0:v][lt]overlay=0:main_h-overlay_h:enable='between(t,2,7)'" \
  output.mp4
```

## Performance Tips

1. **Pre-scale inputs** to target size before overlaying
2. **Use format=yuv420p** for output compatibility
3. **Minimize alpha operations** when possible
4. **Process overlays in order** of size (largest first)

```bash
# Optimized multi-overlay
ffmpeg -i video.mp4 -i large.png -i small.png \
  -filter_complex \
    "[1:v]scale=300:200[l]; \
     [2:v]scale=100:100[s]; \
     [0:v][l]overlay=10:10[v1]; \
     [v1][s]overlay=main_w-overlay_w-10:10,format=yuv420p" \
  -c:v libx264 output.mp4
```

## Next Steps

- [Text & Subtitles](subtitles.md) - Text overlays and captions
- [Complex Filters](complex-filters.md) - Advanced compositions
