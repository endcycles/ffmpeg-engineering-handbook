# Speed Manipulation

Change playback speed, create slow motion, time-lapse, and reverse video.

## Speed Up Video

### Basic Speed Increase

```bash
# 2x speed (half duration)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" \
  -map "[v]" -map "[a]" output.mp4
```

| Multiplier | setpts | atempo | Duration |
|------------|--------|--------|----------|
| 2x | 0.5*PTS | 2.0 | Half |
| 3x | 0.333*PTS | 3.0 | Third |
| 4x | 0.25*PTS | 4.0 | Quarter |

### Speed Without Re-timing Audio

```bash
# Speed up video only, drop audio
ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" -an output.mp4

# Speed up video, keep audio at original speed (truncated)
ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" -c:a copy -shortest output.mp4
```

### Very Fast (>4x)

atempo max is 100, but for best quality, chain at 2.0:

```bash
# 4x speed (chain atempo)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.25*PTS[v];[0:a]atempo=2.0,atempo=2.0[a]" \
  -map "[v]" -map "[a]" output.mp4

# 8x speed
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.125*PTS[v];[0:a]atempo=2.0,atempo=2.0,atempo=2.0[a]" \
  -map "[v]" -map "[a]" output.mp4
```

## Slow Down Video

### Basic Slow Motion

```bash
# 0.5x speed (double duration)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]" \
  -map "[v]" -map "[a]" output.mp4
```

| Multiplier | setpts | atempo | Duration |
|------------|--------|--------|----------|
| 0.5x | 2.0*PTS | 0.5 | Double |
| 0.25x | 4.0*PTS | 0.5,0.5 | 4x |
| 0.1x | 10.0*PTS | 0.5,0.5,0.5,0.5 | 10x |

### Very Slow (<0.5x)

Chain atempo (min is 0.5):

```bash
# 0.25x speed
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=4.0*PTS[v];[0:a]atempo=0.5,atempo=0.5[a]" \
  -map "[v]" -map "[a]" output.mp4
```

## High Quality Slow Motion

### Frame Interpolation (minterpolate)

Create smooth slow motion by generating intermediate frames:

```bash
# 0.5x speed with frame interpolation
ffmpeg -i input.mp4 \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=60',setpts=2.0*PTS" \
  -an output.mp4
```

| Parameter | Description |
|-----------|-------------|
| `mi_mode=mci` | Motion compensated interpolation |
| `mc_mode=aobmc` | Adaptive overlapped block motion compensation |
| `vsbmc=1` | Variable-size block motion compensation |
| `fps=60` | Target frame rate before slowing |

### Simpler Interpolation

```bash
# Blend interpolation (faster, lower quality)
ffmpeg -i input.mp4 \
  -vf "minterpolate='fps=60:mi_mode=blend',setpts=2.0*PTS" \
  -an output.mp4
```

## Time-Lapse

### From Video

```bash
# 10x speed (time-lapse effect)
ffmpeg -i input.mp4 -vf "setpts=0.1*PTS" -an output.mp4

# Select every Nth frame (smoother time-lapse)
ffmpeg -i input.mp4 -vf "select='not(mod(n,30))',setpts=N/30/TB" -an output.mp4
```

### From Image Sequence

```bash
# Images to time-lapse video
ffmpeg -framerate 30 -pattern_type glob -i '*.jpg' \
  -c:v libx264 -pix_fmt yuv420p timelapse.mp4
```

### From High Frame Rate Source

```bash
# 120fps to 30fps time-lapse (4x speed)
ffmpeg -i highfps.mp4 -vf "fps=30" -an timelapse.mp4
```

## Reverse Video

### Reverse Entire Video

```bash
# Reverse video and audio
ffmpeg -i input.mp4 -vf reverse -af areverse output.mp4
```

**Warning**: This loads entire video into memory. For long videos, process in segments.

### Reverse Video Only

```bash
ffmpeg -i input.mp4 -vf reverse -an output.mp4
```

### Reverse Long Videos

Split, reverse, concatenate:

```bash
# Split into 10-second segments
ffmpeg -i long_video.mp4 -c copy -segment_time 10 -f segment segment_%03d.mp4

# Reverse each segment
for f in segment_*.mp4; do
  ffmpeg -i "$f" -vf reverse -af areverse "rev_$f"
done

# Concatenate in reverse order
ls -r rev_segment_*.mp4 | sed 's/^/file /' > list.txt
ffmpeg -f concat -safe 0 -i list.txt -c copy reversed.mp4
```

## Variable Speed (Ramp)

### Speed Ramp Up

```bash
# Start slow, speed up over time
ffmpeg -i input.mp4 \
  -vf "setpts='if(lt(T,5),2*PTS,PTS-5+5/2)'" \
  -af "atempo='if(lt(t,5),0.5,2)':eval=frame" \
  output.mp4
```

### Speed Ramp Down

```bash
# Start fast, slow down
ffmpeg -i input.mp4 \
  -vf "setpts='if(lt(T,5),0.5*PTS,PTS*2-5+5*0.5)'" \
  output.mp4
```

### Smooth Speed Change

```bash
# Gradual speed change using expression
ffmpeg -i input.mp4 \
  -vf "setpts='PTS/(1+0.5*T/10)'" \
  -an output.mp4
```

## Preserve Audio Pitch

### Speed Up Without Chipmunk Effect

```bash
# atempo preserves pitch automatically
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Using rubberband (Higher Quality)

```bash
# If rubberband filter is available
ffmpeg -i input.mp4 \
  -vf "setpts=0.5*PTS" \
  -af "rubberband=tempo=2.0" \
  output.mp4
```

## Frame Rate Changes

### Change FPS Without Speed Change

```bash
# Drop/duplicate frames to reach target fps
ffmpeg -i input.mp4 -vf "fps=60" output.mp4
```

### Smooth FPS Conversion

```bash
# Frame interpolation for smooth fps change
ffmpeg -i input_24fps.mp4 \
  -vf "minterpolate='fps=60'" \
  output_60fps.mp4
```

## Freeze Frame

### Insert Freeze Frame

```bash
# Freeze at 5 seconds for 3 seconds
ffmpeg -i input.mp4 \
  -filter_complex \
    "[0:v]trim=0:5,setpts=PTS-STARTPTS[a]; \
     [0:v]trim=5:5.04,setpts=PTS-STARTPTS,loop=75:1:0,setpts=N/FRAME_RATE/TB[freeze]; \
     [0:v]trim=5:,setpts=PTS-STARTPTS[b]; \
     [a][freeze][b]concat=n=3:v=1" \
  output.mp4
```

### Freeze Last Frame

```bash
# Extend video by freezing last frame
ffmpeg -i input.mp4 \
  -vf "tpad=stop_mode=clone:stop_duration=5" \
  output.mp4
```

## Speed Segments Differently

### Different Speeds for Different Parts

```bash
ffmpeg -i input.mp4 \
  -filter_complex \
    "[0:v]trim=0:5,setpts=PTS-STARTPTS[v1]; \
     [0:v]trim=5:10,setpts=0.5*PTS-STARTPTS[v2]; \
     [0:v]trim=10:15,setpts=2*PTS-STARTPTS[v3]; \
     [v1][v2][v3]concat=n=3:v=1[v]" \
  -map "[v]" -an output.mp4
```

## Common Calculations

| Desired Speed | setpts Multiplier | atempo Value |
|---------------|-------------------|--------------|
| 0.25x | 4.0*PTS | 0.5,0.5 |
| 0.5x | 2.0*PTS | 0.5 |
| 0.75x | 1.333*PTS | 0.75 |
| 1.25x | 0.8*PTS | 1.25 |
| 1.5x | 0.667*PTS | 1.5 |
| 2x | 0.5*PTS | 2.0 |
| 3x | 0.333*PTS | 2.0,1.5 |
| 4x | 0.25*PTS | 2.0,2.0 |

**Formula**: `setpts_multiplier = 1 / speed`

## Common Issues

### Audio/Video Desync

Reset timestamps after speed change:

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0,aresample=async=1[a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Jerky Slow Motion

Use minterpolate for smooth slow motion, or start with higher frame rate source.

### Memory Issues with Reverse

Process in smaller segments for long videos.

## Next Steps

- [Complex Filters](complex-filters.md) - Combine with other effects
- [Automation](../automation/batch.md) - Process multiple files
