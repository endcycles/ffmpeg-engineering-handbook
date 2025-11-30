# Common Errors

Solutions to frequently encountered FFmpeg errors.

## Codec Errors

### "Unknown encoder 'libx264'"

**Cause**: FFmpeg not compiled with libx264 support.

**Solution**:
```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg libavcodec-extra

# Check available encoders
ffmpeg -encoders | grep 264
```

### "Encoder not found"

```bash
# List available encoders
ffmpeg -encoders

# Use alternative
ffmpeg -i input.mp4 -c:v mpeg4 output.mp4  # If libx264 missing
```

### "Decoder not found"

```bash
# Check available decoders
ffmpeg -decoders

# Try copying without decoding
ffmpeg -i input.mp4 -c copy output.mkv
```

## Format Errors

### "Could not find tag for codec"

**Cause**: Container doesn't support the codec.

```bash
# Wrong: AAC in AVI
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.avi

# Fixed: Use compatible container
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4
```

### "Invalid data found when processing input"

**Cause**: Corrupted file or wrong format detection.

```bash
# Force format
ffmpeg -f mp4 -i input.mp4 output.mkv

# Try repairing
ffmpeg -i input.mp4 -c copy -movflags +faststart output.mp4
```

### "Protocol not found"

```bash
# Wrong
ffmpeg -i https://example.com/video.mp4 output.mp4

# Check protocol support
ffmpeg -protocols

# If HTTPS not supported, download first
curl -o input.mp4 https://example.com/video.mp4
ffmpeg -i input.mp4 output.mp4
```

## Filter Errors

### "No such filter"

```bash
# Check available filters
ffmpeg -filters

# Common issue: space in filter name
# Wrong
-vf "scale = 1280:720"
# Correct
-vf "scale=1280:720"
```

### "Invalid filter graph"

**Cause**: Syntax error in filter chain.

```bash
# Check for:
# - Missing quotes
# - Wrong separator (use , between filters)
# - Unbalanced brackets

# Debug with verbose
ffmpeg -v verbose -i input.mp4 -vf "scale=1280:720" output.mp4
```

### "Option not found"

```bash
# Wrong filter parameter
-vf "scale=width=1280"

# Correct
-vf "scale=w=1280"

# Check filter options
ffmpeg -h filter=scale
```

## Stream Errors

### "Stream specifier does not match any stream"

```bash
# Check what streams exist
ffprobe -show_streams input.mp4

# Wrong: no audio stream
-map 0:a  # Error if no audio

# Correct: check first
ffprobe -select_streams a -show_entries stream=index input.mp4
```

### "Output file is empty"

**Cause**: No streams selected or filter produces no output.

```bash
# Check stream mapping
ffmpeg -i input.mp4 -map 0 output.mp4

# For filters, ensure output is connected
-filter_complex "[0:v]scale=1280:720[out]" -map "[out]"
```

### "Discarding packets" Warning

```bash
# Timestamps issue
ffmpeg -fflags +genpts -i input.mp4 -c copy output.mp4

# Or re-encode
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4
```

## Timing Errors

### "Non-monotonous DTS"

**Cause**: Timestamp issues in source.

```bash
# Re-encode
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4

# Or filter timestamps
ffmpeg -fflags +genpts -i input.mp4 -c copy output.mp4
```

### "Discarding empty data stream"

Safe to ignore in most cases.

### Audio/Video Sync Issues

```bash
# Reset timestamps
ffmpeg -i input.mp4 -async 1 -c:v libx264 -c:a aac output.mp4

# Or use audio filter
ffmpeg -i input.mp4 -af "aresample=async=1" -c:v copy output.mp4
```

## Size/Memory Errors

### "Memory allocation failed"

**Cause**: Not enough RAM for operation.

```bash
# Reduce resolution first
ffmpeg -i input.mp4 -vf "scale=1280:720" -c:v libx264 output.mp4

# Process in chunks for large files
# Or add swap space
```

### "Output file exceeds limit"

```bash
# For FAT32 (4GB limit)
# Split into segments
ffmpeg -i input.mp4 -c copy -f segment -segment_time 3600 segment_%03d.mp4
```

## Permission Errors

### "Permission denied"

```bash
# Check file permissions
ls -la input.mp4

# Check output directory
ls -la output_dir/

# Run with proper permissions
sudo ffmpeg -i input.mp4 output.mp4  # Not recommended
```

### "Cannot overwrite"

```bash
# Add -y to overwrite
ffmpeg -y -i input.mp4 output.mp4

# Or add -n to never overwrite
ffmpeg -n -i input.mp4 output.mp4
```

## Hardware Acceleration Errors

### "No NVENC capable devices found"

```bash
# Check NVIDIA driver
nvidia-smi

# Check FFmpeg build
ffmpeg -encoders | grep nvenc

# Verify GPU supports NVENC
# https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix
```

### "Error initializing QSV"

```bash
# Check Intel driver
vainfo

# Check libmfx
ffmpeg -encoders | grep qsv

# Try explicit device
ffmpeg -init_hw_device qsv=hw -i input.mp4 -c:v h264_qsv output.mp4
```

## Quality Issues

### Black Frames at Start

**Cause**: Cutting at non-keyframe with `-c copy`.

```bash
# Re-encode for precise cuts
ffmpeg -i input.mp4 -ss 00:00:37 -t 10 -c:v libx264 -c:a aac output.mp4
```

### Green/Corrupt Frames

**Cause**: Missing keyframe data or codec issue.

```bash
# Force pixel format
ffmpeg -i input.mp4 -pix_fmt yuv420p output.mp4

# Or re-encode
ffmpeg -i input.mp4 -c:v libx264 -crf 23 output.mp4
```

### Audio Clicks/Pops

```bash
# Smooth audio at cut points
ffmpeg -i input.mp4 -af "afade=t=in:d=0.1,afade=t=out:st=9.9:d=0.1" output.mp4
```

## Debugging

### Get Detailed Error Info

```bash
# Verbose output
ffmpeg -v verbose -i input.mp4 output.mp4

# Debug level
ffmpeg -v debug -i input.mp4 output.mp4

# Log to file
ffmpeg -i input.mp4 output.mp4 2> ffmpeg.log
```

### Test Without Output

```bash
# Dry run to check for errors
ffmpeg -i input.mp4 -f null -
```

### Check Input File

```bash
# Detailed info
ffprobe -v error -show_format -show_streams input.mp4

# JSON format
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```

## Quick Fixes

| Error | Quick Fix |
|-------|-----------|
| "Unknown encoder" | Check `ffmpeg -encoders` |
| "No such filter" | Check `ffmpeg -filters` |
| "Permission denied" | Check file/directory permissions |
| Black frames | Re-encode instead of copy |
| Sync issues | Use `-async 1` |
| Timestamp issues | Use `-fflags +genpts` |
| Memory issues | Reduce resolution first |

## Next Steps

- [Debugging](debugging.md) - Advanced debugging techniques
- [Compatibility](compatibility.md) - Cross-platform issues
