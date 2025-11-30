# Trimming & Cutting

Extracting portions of video/audio is one of the most common operations. Understanding the tradeoffs between speed and accuracy is crucial.

## Quick Reference

| Method | Speed | Accuracy | Re-encodes |
|--------|-------|----------|------------|
| Input seeking + copy | Fast | Keyframe | No |
| Output seeking + copy | Slow | Keyframe | No |
| Output seeking + encode | Slow | Frame-exact | Yes |

## Basic Trimming

### By Duration

```bash
# Start at 10 seconds, extract 30 seconds
ffmpeg -i input.mp4 -ss 00:00:10 -t 00:00:30 output.mp4

# Short form for seconds
ffmpeg -i input.mp4 -ss 10 -t 30 output.mp4
```

### By End Time

```bash
# Start at 10 seconds, end at 40 seconds
ffmpeg -i input.mp4 -ss 00:00:10 -to 00:00:40 output.mp4
```

### From End of File

```bash
# Last 30 seconds
ffmpeg -sseof -30 -i input.mp4 -c copy output.mp4
```

## Input vs Output Seeking

### Input Seeking (Fast, Less Accurate)

Place `-ss` **before** `-i`:

```bash
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 -c copy output.mp4
```

- **Pros**: Very fast (seeks by keyframe)
- **Cons**: May start a few seconds before requested time
- **Best for**: Large files, rough cuts, `-c copy`

### Output Seeking (Slow, Accurate)

Place `-ss` **after** `-i`:

```bash
ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 output.mp4
```

- **Pros**: Frame-accurate
- **Cons**: Decodes from start (slow for late timestamps)
- **Best for**: Precise cuts, when re-encoding anyway

### Combined (Fast + Accurate)

Seek near the target, then fine-tune:

```bash
# Seek to 55 seconds (rough), then 5 more (precise)
ffmpeg -ss 00:00:55 -i input.mp4 -ss 00:00:05 -t 00:00:30 output.mp4
```

## The `-c copy` Problem

Using `-c copy` with non-keyframe timestamps causes issues:

```bash
# May produce black frames at start
ffmpeg -i input.mp4 -ss 00:00:37 -t 00:00:10 -c copy output.mp4
```

**Why?** Video streams have keyframes (I-frames) every few seconds. Copying from a non-keyframe point loses reference data.

### Solutions

**Option 1: Re-encode (recommended for accuracy)**
```bash
ffmpeg -i input.mp4 -ss 00:00:37 -t 00:00:10 -c:v libx264 -c:a aac output.mp4
```

**Option 2: Use input seeking (start at previous keyframe)**
```bash
ffmpeg -ss 00:00:37 -i input.mp4 -t 00:00:10 -c copy output.mp4
```

**Option 3: Force keyframe at start**
```bash
ffmpeg -i input.mp4 -ss 00:00:37 -t 00:00:10 \
  -c:v libx264 -force_key_frames "expr:eq(t,0)" \
  -c:a aac output.mp4
```

## Trimming Audio Only

```bash
# Extract 30 seconds of audio starting at 1 minute
ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 -vn -c:a copy output.aac

# Same with re-encoding
ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 -vn -c:a aac output.m4a
```

## Trimming Video Only

```bash
# Extract video without audio
ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 -an -c:v copy output.mp4
```

## Multiple Clips (Jump Cuts)

Extract multiple segments and concatenate:

```bash
# Using select filter
ffmpeg -i input.mp4 \
  -vf "select='between(t,0,5)+between(t,10,15)+between(t,20,25)',setpts=N/FRAME_RATE/TB" \
  -af "aselect='between(t,0,5)+between(t,10,15)+between(t,20,25)',asetpts=N/SR/TB" \
  output.mp4
```

| Expression | Meaning |
|------------|---------|
| `between(t,0,5)` | Include 0-5 seconds |
| `+` | OR operator |
| `setpts=N/FRAME_RATE/TB` | Reset video timestamps |
| `asetpts=N/SR/TB` | Reset audio timestamps |

## Removing Sections (Inverse Trim)

Remove a section from the middle:

```bash
# Remove 10-20 second section from a 60 second video
ffmpeg -i input.mp4 \
  -filter_complex \
    "[0:v]trim=0:10,setpts=PTS-STARTPTS[v1]; \
     [0:v]trim=20:60,setpts=PTS-STARTPTS[v2]; \
     [0:a]atrim=0:10,asetpts=PTS-STARTPTS[a1]; \
     [0:a]atrim=20:60,asetpts=PTS-STARTPTS[a2]; \
     [v1][a1][v2][a2]concat=n=2:v=1:a=1" \
  output.mp4
```

## Time Formats

FFmpeg accepts various time formats:

```bash
# Seconds (integer or decimal)
-ss 30
-ss 30.5

# HH:MM:SS
-ss 00:00:30

# HH:MM:SS.mmm (millisecond precision)
-ss 00:00:30.500

# With frames (at 30fps, frame 15 = 0.5 sec)
-ss 00:00:30.5
```

## Precise Frame Extraction

For frame-perfect extraction:

```bash
# Extract exactly 100 frames starting at frame 500
ffmpeg -i input.mp4 \
  -vf "select='gte(n,500)*lte(n,599)',setpts=PTS-STARTPTS" \
  -frames:v 100 \
  output.mp4
```

## Trimming with Filter Complex

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]trim=start=10:end=40,setpts=PTS-STARTPTS[v]; \
                   [0:a]atrim=start=10:end=40,asetpts=PTS-STARTPTS[a]" \
  -map "[v]" -map "[a]" \
  output.mp4
```

**Note**: Always use `setpts=PTS-STARTPTS` after `trim` to reset timestamps.

## Split into Equal Parts

```bash
# Get duration first
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4)

# Split into 4 parts (bash example)
part_length=$(echo "$duration / 4" | bc -l)
for i in 0 1 2 3; do
  start=$(echo "$i * $part_length" | bc -l)
  ffmpeg -i input.mp4 -ss $start -t $part_length -c copy part_$i.mp4
done
```

## Segment by Size

```bash
# Split into ~50MB segments
ffmpeg -i input.mp4 -c copy -f segment -segment_time 60 -reset_timestamps 1 segment_%03d.mp4
```

## Common Gotchas

### 1. Duration mismatch with `-c copy`

The output may be slightly longer/shorter than requested when copying.

**Solution**: Re-encode for exact duration.

### 2. Audio/video sync after trim

```bash
# Force sync reset
ffmpeg -i input.mp4 -ss 10 -t 30 -async 1 output.mp4
```

### 3. Timestamp gaps

After trimming, timestamps may not start at 0.

**Solution**: Always reset with `setpts=PTS-STARTPTS`.

### 4. Concat after trim fails

Trimmed segments need matching properties.

**Solution**: Normalize segments before concat:

```bash
ffmpeg -i segment.mp4 -c:v libx264 -c:a aac -r 30 -ar 44100 normalized.mp4
```

## Performance Tips

1. **Use input seeking** for rough cuts on large files
2. **Avoid decoding** when possible (`-c copy`)
3. **Combine with format conversion** if re-encoding anyway
4. **Process in parallel** for multiple segments

```bash
# Parallel processing (bash)
ffmpeg -ss 0 -t 30 -i input.mp4 -c copy part1.mp4 &
ffmpeg -ss 30 -t 30 -i input.mp4 -c copy part2.mp4 &
wait
```

## Next Steps

- [Scaling](scaling.md) - Resize and crop videos
- [Concatenation](concatenation.md) - Join segments back together
