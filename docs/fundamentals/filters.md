# Filters & Filter Graphs

Filters are FFmpeg's most powerful feature—they transform audio and video streams in countless ways.

## Filter Types

### Simple Filters

Use `-vf` for video and `-af` for audio when you have a single input, single output:

```bash
# Video filter: scale
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4

# Audio filter: volume
ffmpeg -i input.mp4 -af "volume=2.0" output.mp4
```

### Complex Filters

Use `-filter_complex` when you need:
- Multiple inputs
- Multiple outputs
- Filters that combine streams

```bash
# Overlay logo on video (2 inputs → 1 output)
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[0:v][1:v]overlay=10:10" \
  output.mp4
```

## Filter Syntax

### Basic Filter

```
filter_name=param1=value1:param2=value2
```

```bash
# Scale with parameters
-vf "scale=w=1280:h=720"

# Or positional (order matters)
-vf "scale=1280:720"
```

### Chaining Filters

Connect filters with commas:

```bash
# Scale, then add fade
-vf "scale=1280:720,fade=t=in:d=1"
```

### Named Streams

Use square brackets to name streams:

```bash
[input]filter[output]
```

```bash
-filter_complex "[0:v]scale=1280:720[scaled];[scaled]fade=t=in:d=1[final]"
```

### Multiple Inputs

```bash
# Two inputs to overlay
-filter_complex "[0:v][1:v]overlay=10:10"
```

### Multiple Outputs

```bash
# Split into two streams
-filter_complex "[0:v]split=2[out1][out2]"
```

## Stream Selection in Filters

| Selector | Meaning |
|----------|---------|
| `[0]` | All streams from first input |
| `[0:v]` | Video stream from first input |
| `[0:a]` | Audio stream from first input |
| `[0:v:0]` | First video stream from first input |
| `[1:a:1]` | Second audio stream from second input |

## Essential Video Filters

### scale - Resize Video

```bash
# Specific dimensions
-vf "scale=1920:1080"

# Preserve aspect ratio (-1 auto-calculates)
-vf "scale=1280:-1"

# Force even dimensions (-2 rounds to even)
-vf "scale=1280:-2"

# Fit within bounds, preserve aspect ratio
-vf "scale=1920:1080:force_original_aspect_ratio=decrease"

# Fill bounds, crop excess
-vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080"
```

### pad - Add Borders

```bash
# Add black bars to reach target size
-vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black"

# pad=width:height:x:y:color
# ow/oh = output width/height
# iw/ih = input width/height
```

### crop - Remove Edges

```bash
# crop=width:height:x:y
-vf "crop=1280:720:100:50"

# Crop to center
-vf "crop=1280:720:(in_w-1280)/2:(in_h-720)/2"

# Crop 10% from each side
-vf "crop=in_w*0.8:in_h*0.8:in_w*0.1:in_h*0.1"
```

### overlay - Composite Videos/Images

```bash
# Position at x=10, y=10
-filter_complex "[0:v][1:v]overlay=10:10"

# Center
-filter_complex "[0:v][1:v]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2"

# Bottom right with padding
-filter_complex "[0:v][1:v]overlay=main_w-overlay_w-10:main_h-overlay_h-10"

# Enable/disable by time
-filter_complex "[0:v][1:v]overlay=10:10:enable='between(t,5,10)'"
```

### fade - Fade In/Out

```bash
# Fade in first 2 seconds
-vf "fade=t=in:st=0:d=2"

# Fade out last 2 seconds (video is 30 seconds)
-vf "fade=t=out:st=28:d=2"

# Both
-vf "fade=t=in:d=1,fade=t=out:st=29:d=1"
```

### drawtext - Text Overlay

```bash
# Basic text
-vf "drawtext=text='Hello World':x=100:y=100:fontsize=48:fontcolor=white"

# With background box
-vf "drawtext=text='Hello':x=100:y=100:fontsize=48:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=10"

# Timed text
-vf "drawtext=text='Hello':enable='between(t,2,5)':x=100:y=100:fontsize=48"

# Timecode
-vf "drawtext=text='%{pts\:hms}':x=10:y=10:fontsize=24:fontcolor=white"

# Custom font
-vf "drawtext=text='Hello':fontfile=/path/to/font.ttf:fontsize=48"
```

### setpts - Change Timestamps (Speed)

```bash
# 2x speed (half duration)
-vf "setpts=0.5*PTS"

# 0.5x speed (double duration)
-vf "setpts=2*PTS"

# Reset timestamps (important after trim)
-vf "setpts=PTS-STARTPTS"
```

### select - Choose Frames

```bash
# Every 10th frame
-vf "select='not(mod(n,10))'"

# Frames between times
-vf "select='between(t,5,10)'"

# Scene changes
-vf "select='gt(scene,0.4)'"
```

### fps - Change Frame Rate

```bash
-vf "fps=30"

# Drop to lower fps
-vf "fps=24"
```

### format - Pixel Format

```bash
# Ensure compatibility
-vf "format=yuv420p"

# Add alpha channel
-vf "format=rgba"
```

## Essential Audio Filters

### volume - Adjust Volume

```bash
# Double volume
-af "volume=2.0"

# Half volume
-af "volume=0.5"

# In decibels
-af "volume=3dB"
```

### afade - Audio Fade

```bash
# Fade in 2 seconds
-af "afade=t=in:st=0:d=2"

# Fade out last 3 seconds
-af "afade=t=out:st=27:d=3"
```

### atempo - Change Audio Speed

```bash
# 1.5x speed (maintains pitch)
-af "atempo=1.5"

# 2x speed (chain for >2x)
-af "atempo=2.0,atempo=2.0"
```

### amix - Mix Audio Streams

```bash
# Mix two audio inputs
-filter_complex "[0:a][1:a]amix=inputs=2:duration=longest"

# With volume adjustment
-filter_complex "[0:a]volume=1.0[a0];[1:a]volume=0.3[a1];[a0][a1]amix=inputs=2"
```

### aformat - Audio Format

```bash
# Specific sample format and rate
-af "aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo"
```

### dynaudnorm - Dynamic Normalization

```bash
# Normalize audio levels
-af "dynaudnorm"
```

## Complex Filter Examples

### Picture-in-Picture

```bash
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "[1:v]scale=320:180[pip];[0:v][pip]overlay=main_w-overlay_w-10:main_h-overlay_h-10" \
  output.mp4
```

### Side-by-Side Videos

```bash
ffmpeg -i left.mp4 -i right.mp4 \
  -filter_complex "[0:v]scale=640:360[l];[1:v]scale=640:360[r];[l][r]hstack" \
  output.mp4
```

### Vertical Stack

```bash
ffmpeg -i top.mp4 -i bottom.mp4 \
  -filter_complex "[0:v]scale=640:360[t];[1:v]scale=640:360[b];[t][b]vstack" \
  output.mp4
```

### Split and Process Differently

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split=2[a][b];[a]scale=1920:1080[hd];[b]scale=640:360[sd]" \
  -map "[hd]" output_hd.mp4 \
  -map "[sd]" output_sd.mp4
```

### Trim and Concatenate

```bash
ffmpeg -i input.mp4 \
  -filter_complex \
    "[0:v]trim=0:5,setpts=PTS-STARTPTS[v1]; \
     [0:v]trim=10:15,setpts=PTS-STARTPTS[v2]; \
     [0:a]atrim=0:5,asetpts=PTS-STARTPTS[a1]; \
     [0:a]atrim=10:15,asetpts=PTS-STARTPTS[a2]; \
     [v1][a1][v2][a2]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Crossfade Between Videos

```bash
ffmpeg -i first.mp4 -i second.mp4 \
  -filter_complex "xfade=transition=fade:duration=1:offset=4" \
  output.mp4
```

## Expression Syntax

Filters support expressions for dynamic values:

| Expression | Meaning |
|------------|---------|
| `t` | Time in seconds |
| `n` | Frame number |
| `w`, `h` | Input width/height |
| `iw`, `ih` | Input width/height |
| `ow`, `oh` | Output width/height |
| `main_w`, `main_h` | Main input dimensions |
| `overlay_w`, `overlay_h` | Overlay dimensions |
| `PTS` | Presentation timestamp |

### Expression Functions

| Function | Meaning |
|----------|---------|
| `between(x,min,max)` | 1 if min ≤ x ≤ max |
| `gte(x,y)` | 1 if x ≥ y |
| `lte(x,y)` | 1 if x ≤ y |
| `if(cond,then,else)` | Conditional |
| `mod(x,y)` | x modulo y |
| `random(x)` | Random 0-1 |

```bash
# Fade in alpha from t=1 to t=3
-vf "drawtext=text='Hi':alpha='if(between(t,1,3),(t-1)/2,1)'"
```

## Timeline Editing

Enable/disable filters based on time:

```bash
# Overlay only between 5-10 seconds
-filter_complex "[0:v][1:v]overlay=10:10:enable='between(t,5,10)'"

# Text that fades in
-vf "drawtext=text='Hi':enable='gte(t,2)':alpha='min(1,(t-2)/1)'"
```

## Filter Graph Visualization

For complex filters, visualize the graph:

```bash
ffmpeg -i input.mp4 -filter_complex "..." -f null - 2>&1 | grep "filtergraph"
```

## Performance Tips

1. **Order matters**: Put fast filters first
2. **Avoid redundant operations**: Don't scale then scale again
3. **Use hardware filters** when available (e.g., `scale_npp` for NVIDIA)
4. **Minimize format conversions**: Stay in the same pixel format

## Next Steps

- [Overlays & Compositing](../advanced/overlays.md) - Deep dive into overlay techniques
- [Complex Filters](../advanced/complex-filters.md) - Advanced filter graph patterns
