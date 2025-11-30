# Concatenation

Joining multiple video or audio files is straightforward when the sources match, but requires care when they differ.

## Methods Overview

| Method | Speed | Flexibility | Requirements |
|--------|-------|-------------|--------------|
| Concat demuxer | Fast | Low | Same codecs, resolution |
| Concat protocol | Fast | Low | Same format |
| Concat filter | Slow | High | Any input |

## Concat Demuxer (Fastest)

Best for files with identical properties (codec, resolution, frame rate).

### Step 1: Create File List

```bash
# files.txt
file 'video1.mp4'
file 'video2.mp4'
file 'video3.mp4'
```

**Important**: Use single quotes around filenames and relative or absolute paths.

### Step 2: Concatenate

```bash
ffmpeg -f concat -safe 0 -i files.txt -c copy output.mp4
```

| Option | Purpose |
|--------|---------|
| `-f concat` | Use concat demuxer |
| `-safe 0` | Allow absolute paths |
| `-c copy` | Copy streams (no re-encode) |

### Generate File List Dynamically

```bash
# Bash: list all mp4 files
for f in *.mp4; do echo "file '$f'"; done > files.txt
ffmpeg -f concat -safe 0 -i files.txt -c copy output.mp4

# One-liner with process substitution
ffmpeg -f concat -safe 0 -i <(for f in *.mp4; do echo "file '$f'"; done) -c copy output.mp4
```

## Concat Protocol

For formats that support direct concatenation (MPEG-TS, MPEG-PS):

```bash
# Concatenate MPEG-TS files
ffmpeg -i "concat:part1.ts|part2.ts|part3.ts" -c copy output.ts
```

## Concat Filter (Most Flexible)

When sources differ in codec, resolution, or frame rate:

```bash
ffmpeg -i video1.mp4 -i video2.mp4 -i video3.mp4 \
  -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

| Parameter | Meaning |
|-----------|---------|
| `n=3` | Number of segments |
| `v=1` | Output 1 video stream |
| `a=1` | Output 1 audio stream |

### Normalizing Inputs

For reliable concatenation, normalize all inputs first:

```bash
ffmpeg -i video1.mov -i video2.avi -i video3.mkv \
  -filter_complex \
    "[0:v]scale=1920:1080,fps=30,format=yuv420p,setsar=1[v0]; \
     [0:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a0]; \
     [1:v]scale=1920:1080,fps=30,format=yuv420p,setsar=1[v1]; \
     [1:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a1]; \
     [2:v]scale=1920:1080,fps=30,format=yuv420p,setsar=1[v2]; \
     [2:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a2]; \
     [v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" \
  -c:v libx264 -c:a aac output.mp4
```

## With Transitions

### Crossfade Between Videos

```bash
ffmpeg -i video1.mp4 -i video2.mp4 \
  -filter_complex "xfade=transition=fade:duration=1:offset=4" \
  output.mp4
```

| Parameter | Meaning |
|-----------|---------|
| `transition=fade` | Transition type |
| `duration=1` | Fade duration in seconds |
| `offset=4` | Start transition at 4 seconds |

### Available Transitions

```
fade, fadeblack, fadewhite, distance, wipeleft, wiperight,
wipeup, wipedown, slideleft, slideright, slideup, slidedown,
smoothleft, smoothright, smoothup, smoothdown, circlecrop,
rectcrop, circleclose, circleopen, horzclose, horzopen,
vertclose, vertopen, diagbl, diagbr, diagtl, diagtr, hlslice,
hrslice, vuslice, vdslice, dissolve, pixelize, radial,
hblur, wipetl, wipetr, wipebl, wipebr, squeezeh, squeezev,
zoomin
```

### Multiple Crossfades

```bash
ffmpeg -i v1.mp4 -i v2.mp4 -i v3.mp4 \
  -filter_complex \
    "[0:v][1:v]xfade=transition=fade:duration=0.5:offset=4[v01]; \
     [v01][2:v]xfade=transition=fade:duration=0.5:offset=8[v]" \
  -map "[v]" output.mp4
```

### With Audio Crossfade

```bash
ffmpeg -i video1.mp4 -i video2.mp4 \
  -filter_complex \
    "[0:v][1:v]xfade=transition=fade:duration=1:offset=4[v]; \
     [0:a][1:a]acrossfade=d=1:c1=tri:c2=tri[a]" \
  -map "[v]" -map "[a]" output.mp4
```

## Video-Only Concatenation

When inputs have no audio or you want to add audio separately:

```bash
ffmpeg -i video1.mp4 -i video2.mp4 \
  -filter_complex "[0:v][1:v]concat=n=2:v=1:a=0[v]" \
  -map "[v]" output.mp4
```

## Audio-Only Concatenation

```bash
# Using concat demuxer (fastest)
ffmpeg -f concat -safe 0 -i audio_files.txt -c copy output.mp3

# Using concat filter
ffmpeg -i audio1.mp3 -i audio2.mp3 \
  -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1[a]" \
  -map "[a]" output.mp3
```

## Handling Mismatched Properties

### Different Resolutions

```bash
ffmpeg -i small.mp4 -i large.mp4 \
  -filter_complex \
    "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2[v0]; \
     [1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2[v1]; \
     [v0][0:a][v1][1:a]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Different Frame Rates

```bash
ffmpeg -i video_24fps.mp4 -i video_30fps.mp4 \
  -filter_complex \
    "[0:v]fps=30[v0]; \
     [1:v]fps=30[v1]; \
     [v0][0:a][v1][1:a]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Different Pixel Formats

```bash
ffmpeg -i input1.mp4 -i input2.mp4 \
  -filter_complex \
    "[0:v]format=yuv420p[v0]; \
     [1:v]format=yuv420p[v1]; \
     [v0][0:a][v1][1:a]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

### Different Audio Properties

```bash
ffmpeg -i input1.mp4 -i input2.mp4 \
  -filter_complex \
    "[0:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a0]; \
     [1:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[a1]; \
     [0:v][a0][1:v][a1]concat=n=2:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" output.mp4
```

## Intro + Main + Outro Pattern

Common pattern for branded content:

```bash
ffmpeg -i intro.mp4 -i main.mp4 -i outro.mp4 \
  -filter_complex \
    "[0:v]fps=30,format=yuv420p[v0]; \
     [1:v]fps=30,format=yuv420p[v1]; \
     [2:v]fps=30,format=yuv420p[v2]; \
     [0:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a0]; \
     [1:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a1]; \
     [2:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a2]; \
     [v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" -c:v libx264 -c:a aac final.mp4
```

## Loop and Extend

### Loop Video to Match Audio Length

```bash
ffmpeg -stream_loop -1 -i short_video.mp4 -i long_audio.mp3 \
  -map 0:v -map 1:a -shortest output.mp4
```

### Extend Video with Last Frame

```bash
ffmpeg -i video.mp4 -vf "tpad=stop_mode=clone:stop_duration=5" output.mp4
```

## Performance Tips

1. **Use concat demuxer** when possible (same codecs)
2. **Pre-normalize** files before concatenating many
3. **Avoid concat filter** for large numbers of files
4. **Process in batches** for very long concatenations

```bash
# Batch concatenation for many files
# First, concat in groups of 10
for i in $(seq 0 10 100); do
  ls video_*.mp4 | sed -n "$((i+1)),$((i+10))p" | \
    sed "s/^/file '/" | sed "s/$/'/" > batch_$i.txt
  ffmpeg -f concat -safe 0 -i batch_$i.txt -c copy batch_$i.mp4
done

# Then concat the batches
ls batch_*.mp4 | sed "s/^/file '/" | sed "s/$/'/" > final.txt
ffmpeg -f concat -safe 0 -i final.txt -c copy output.mp4
```

## Common Issues

### "Discarding packet" Warning

Streams have different start times. Use `-fflags +genpts`:

```bash
ffmpeg -fflags +genpts -f concat -safe 0 -i files.txt -c copy output.mp4
```

### Duration Mismatch

Audio/video durations differ. Normalize before concat or use `-shortest`.

### Timestamp Errors

Reset timestamps after trimming:

```bash
-filter_complex "[0:v]trim=...,setpts=PTS-STARTPTS[v]"
```

## Next Steps

- [Overlays](../advanced/overlays.md) - Combining videos visually
- [Audio Mixing](../audio/mixing.md) - Combining audio tracks
