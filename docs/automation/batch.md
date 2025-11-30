# Batch Processing

Process multiple files efficiently with loops, parallel processing, and scripts.

## Basic Loops

### Convert All Files

```bash
# All AVI to MP4
for f in *.avi; do
  ffmpeg -i "$f" -c:v libx264 -crf 23 -c:a aac "${f%.avi}.mp4"
done

# All MOV to MP4
for f in *.mov; do
  ffmpeg -i "$f" -c:v libx264 -crf 23 -c:a aac "${f%.mov}.mp4"
done
```

### With Progress

```bash
files=(*.avi)
total=${#files[@]}
count=0

for f in "${files[@]}"; do
  ((count++))
  echo "Processing $count of $total: $f"
  ffmpeg -y -i "$f" -c:v libx264 -crf 23 "${f%.avi}.mp4"
done
```

### Output to Different Directory

```bash
mkdir -p output
for f in *.mp4; do
  ffmpeg -i "$f" -c:v libx264 -crf 23 "output/${f%.mp4}_converted.mp4"
done
```

## Recursive Processing

### Find All Files

```bash
# Process all MP4 in subdirectories
find . -name "*.mp4" -exec ffmpeg -i {} -c:v libx264 -crf 23 {}.converted.mp4 \;
```

### With Proper Output Naming

```bash
find . -name "*.avi" | while read f; do
  output="${f%.avi}.mp4"
  ffmpeg -y -i "$f" -c:v libx264 -crf 23 "$output"
done
```

## Parallel Processing

### GNU Parallel

```bash
# 4 parallel jobs
find . -name "*.avi" | parallel -j4 'ffmpeg -y -i {} -c:v libx264 -crf 23 {.}.mp4'

# With progress bar
find . -name "*.avi" | parallel --progress -j4 'ffmpeg -y -i {} -c:v libx264 -crf 23 {.}.mp4'
```

### xargs

```bash
# 4 parallel processes
find . -name "*.avi" -print0 | xargs -0 -P4 -I {} ffmpeg -y -i {} -c:v libx264 -crf 23 {}.mp4
```

### Background Jobs

```bash
# Start multiple in background
for f in *.avi; do
  ffmpeg -y -i "$f" -c:v libx264 -crf 23 "${f%.avi}.mp4" &
done
wait  # Wait for all to complete
```

**Note**: Limit concurrent jobs to avoid overwhelming system.

## Common Batch Tasks

### Extract Thumbnails

```bash
for f in *.mp4; do
  ffmpeg -ss 5 -i "$f" -frames:v 1 -q:v 2 "${f%.mp4}_thumb.jpg"
done
```

### Create GIFs

```bash
for f in *.mp4; do
  ffmpeg -ss 0 -t 3 -i "$f" \
    -filter_complex "fps=10,scale=480:-1,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    "${f%.mp4}.gif"
done
```

### Normalize Audio

```bash
for f in *.mp4; do
  ffmpeg -y -i "$f" -af "dynaudnorm" -c:v copy "${f%.mp4}_normalized.mp4"
done
```

### Add Watermark

```bash
for f in *.mp4; do
  ffmpeg -y -i "$f" -i logo.png \
    -filter_complex "overlay=main_w-overlay_w-10:10" \
    "${f%.mp4}_watermarked.mp4"
done
```

### Resize for Social

```bash
for f in *.mp4; do
  # YouTube 1080p
  ffmpeg -y -i "$f" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:black" "${f%.mp4}_youtube.mp4"

  # Instagram Square
  ffmpeg -y -i "$f" -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:black" "${f%.mp4}_insta.mp4"
done
```

## Error Handling

### Skip on Error

```bash
for f in *.avi; do
  ffmpeg -y -i "$f" -c:v libx264 -crf 23 "${f%.avi}.mp4" || echo "Failed: $f"
done
```

### Log Errors

```bash
for f in *.avi; do
  if ! ffmpeg -y -i "$f" -c:v libx264 -crf 23 "${f%.avi}.mp4" 2>> errors.log; then
    echo "$f" >> failed.txt
  fi
done
```

### Retry Failed

```bash
while read f; do
  ffmpeg -y -i "$f" -c:v libx264 -crf 23 "${f%.avi}.mp4"
done < failed.txt
```

## File Lists

### Generate List

```bash
# For concat demuxer
for f in *.mp4; do echo "file '$f'"; done > files.txt

# Sorted
ls -1 *.mp4 | sort | sed "s/^/file '/" | sed "s/$/'/" > files.txt
```

### Process from List

```bash
while read f; do
  ffmpeg -y -i "$f" -c:v libx264 -crf 23 "${f%.mp4}_out.mp4"
done < files.txt
```

## Conditional Processing

### Only If Not Exists

```bash
for f in *.avi; do
  output="${f%.avi}.mp4"
  if [ ! -f "$output" ]; then
    ffmpeg -y -i "$f" -c:v libx264 -crf 23 "$output"
  else
    echo "Skipping $f (output exists)"
  fi
done
```

### Based on File Properties

```bash
for f in *.mp4; do
  # Get resolution
  width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$f")

  # Only process if > 1080p
  if [ "$width" -gt 1920 ]; then
    ffmpeg -y -i "$f" -vf "scale=1920:-2" "${f%.mp4}_1080p.mp4"
  fi
done
```

### Based on Duration

```bash
for f in *.mp4; do
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")

  # Only if longer than 60 seconds
  if (( $(echo "$duration > 60" | bc -l) )); then
    echo "Processing $f (${duration}s)"
    ffmpeg -y -i "$f" -t 60 "${f%.mp4}_first60.mp4"
  fi
done
```

## Batch Script Template

```bash
#!/bin/bash
# batch_convert.sh

set -e  # Exit on error

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./output}"
EXTENSION="${3:-mp4}"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" -maxdepth 1 -name "*.$EXTENSION" | while read f; do
  filename=$(basename "$f")
  output="$OUTPUT_DIR/${filename%.$EXTENSION}_converted.mp4"

  echo "Processing: $f -> $output"

  if ! ffmpeg -y -i "$f" -c:v libx264 -crf 23 -c:a aac "$output" 2>> "$OUTPUT_DIR/errors.log"; then
    echo "FAILED: $f" >> "$OUTPUT_DIR/failed.txt"
  fi
done

echo "Done!"
```

Usage:
```bash
chmod +x batch_convert.sh
./batch_convert.sh /path/to/videos /path/to/output avi
```

## Performance Tips

1. **Limit concurrency** - too many parallel jobs slows everything
2. **Use hardware encoding** for faster batch processing
3. **Process to local SSD** - avoid network bottlenecks
4. **Start with `-t 10`** - test on first 10 seconds first

```bash
# Hardware accelerated batch
find . -name "*.avi" | parallel -j2 'ffmpeg -y -i {} -c:v h264_nvenc -cq 23 {.}.mp4'
```

## Next Steps

- [Shell Scripts](scripts.md) - Reusable script patterns
- [Pipeline Patterns](pipelines.md) - Complex workflows
