# Command Anatomy

Every FFmpeg command follows a consistent structure. Understanding this structure is key to building complex commands.

## Basic Structure

```
ffmpeg [global_options] [input_options] -i input [output_options] output
```

```
ffmpeg  -y  -ss 10  -i input.mp4  -t 30 -c:v libx264  output.mp4
   │     │    │          │          │        │           │
   │     │    │          │          │        │           └── Output file
   │     │    │          │          │        └── Output option (codec)
   │     │    │          │          └── Output option (duration)
   │     │    │          └── Input file
   │     │    └── Input option (seek)
   │     └── Global option (overwrite)
   └── Command
```

## Option Placement Matters

The position of options relative to `-i` changes their meaning:

```bash
# Input option: seek in input BEFORE decoding (fast, keyframe-based)
ffmpeg -ss 10 -i input.mp4 output.mp4

# Output option: seek AFTER decoding (slow, frame-accurate)
ffmpeg -i input.mp4 -ss 10 output.mp4
```

## Global Options

Apply to the entire operation:

| Option | Description |
|--------|-------------|
| `-y` | Overwrite output files without asking |
| `-n` | Never overwrite output files |
| `-v quiet` | Suppress output (levels: quiet, panic, fatal, error, warning, info, verbose, debug) |
| `-stats` | Show encoding statistics |
| `-progress url` | Send progress info to URL |

```bash
# Typical production command with globals
ffmpeg -y -v error -stats -i input.mp4 output.mp4
```

## Input Options

Apply to the next input file:

| Option | Description |
|--------|-------------|
| `-ss time` | Start time (seek before decoding) |
| `-t duration` | Read only this duration |
| `-to time` | Read until this time |
| `-loop 1` | Loop input (for images) |
| `-r fps` | Input frame rate |
| `-f format` | Force input format |

```bash
# Read 10 seconds starting at 1 minute
ffmpeg -ss 00:01:00 -t 10 -i input.mp4 output.mp4

# Loop an image for 5 seconds
ffmpeg -loop 1 -t 5 -i image.png -pix_fmt yuv420p output.mp4
```

## Output Options

Apply to the next output file:

| Option | Description |
|--------|-------------|
| `-c:v codec` | Video codec |
| `-c:a codec` | Audio codec |
| `-b:v bitrate` | Video bitrate |
| `-b:a bitrate` | Audio bitrate |
| `-r fps` | Output frame rate |
| `-s WxH` | Output size |
| `-vf filter` | Video filter |
| `-af filter` | Audio filter |
| `-an` | No audio |
| `-vn` | No video |
| `-shortest` | End when shortest input ends |

```bash
# Full output specification
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 23 -preset medium \
  -c:a aac -b:a 128k \
  -r 30 \
  output.mp4
```

## Multiple Inputs and Outputs

FFmpeg can handle multiple inputs and outputs in a single command:

```bash
# Two inputs, one output (overlay)
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=10:10" output.mp4

# One input, two outputs
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 23 output_high.mp4 \
  -c:v libx264 -crf 28 output_low.mp4
```

## Stream Specifiers

Target specific streams with specifiers:

```
-option:stream_type:stream_index value
```

| Specifier | Meaning |
|-----------|---------|
| `:v` | All video streams |
| `:a` | All audio streams |
| `:s` | All subtitle streams |
| `:v:0` | First video stream |
| `:a:1` | Second audio stream |

```bash
# Different codecs for different streams
ffmpeg -i input.mp4 \
  -c:v libx264 \
  -c:a:0 aac \
  -c:a:1 mp3 \
  output.mkv
```

## The -map Option

Control which streams go to output:

```bash
# Default: FFmpeg picks "best" streams automatically

# Explicit mapping
ffmpeg -i video.mp4 -i audio.mp3 \
  -map 0:v \       # Video from first input
  -map 1:a \       # Audio from second input
  output.mp4

# Multiple streams
ffmpeg -i input.mkv \
  -map 0:v:0 \     # First video
  -map 0:a:0 \     # First audio
  -map 0:a:1 \     # Second audio
  -map 0:s:0 \     # First subtitle
  output.mkv
```

## Time Formats

FFmpeg accepts multiple time formats:

```bash
# Seconds
-ss 30

# HH:MM:SS
-ss 00:00:30

# HH:MM:SS.mmm
-ss 00:00:30.500

# Negative (from end, some contexts)
-sseof -30
```

## Size/Bitrate Formats

```bash
# Bitrate
-b:v 5M        # 5 megabits/sec
-b:v 5000k     # 5000 kilobits/sec
-b:v 5000000   # 5000000 bits/sec

# Size
-s 1920x1080   # Width x Height
```

## Building Complex Commands

### Step-by-step approach:

1. **Start simple**: Get basic conversion working
2. **Add options**: One option at a time
3. **Test each step**: Verify output at each stage
4. **Use line breaks**: Make commands readable

```bash
# Readable multi-line command
ffmpeg \
  -y \
  -i input.mp4 \
  -c:v libx264 \
  -crf 23 \
  -preset medium \
  -c:a aac \
  -b:a 128k \
  -movflags +faststart \
  output.mp4
```

## Common Patterns

### Copy without re-encoding
```bash
ffmpeg -i input.mp4 -c copy output.mkv
```

### Re-encode video only
```bash
ffmpeg -i input.mp4 -c:v libx264 -c:a copy output.mp4
```

### Re-encode audio only
```bash
ffmpeg -i input.mp4 -c:v copy -c:a aac output.mp4
```

### Extract stream
```bash
# Video only
ffmpeg -i input.mp4 -c:v copy -an output.mp4

# Audio only
ffmpeg -i input.mp4 -vn -c:a copy output.aac
```

## Debugging Commands

### Verbose output
```bash
ffmpeg -v verbose -i input.mp4 output.mp4
```

### Show what would happen (no output)
```bash
ffmpeg -i input.mp4 -f null -
```

### Progress to file
```bash
ffmpeg -progress progress.log -i input.mp4 output.mp4
```

## Next Steps

- [Filters](filters.md) - Understanding filter syntax
- [Format Conversion](../operations/conversion.md) - Practical conversion examples
