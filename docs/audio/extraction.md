# Audio Extraction

Extracting audio from video files is one of the most common FFmpeg operations.

## Basic Extraction

### Copy Audio (Fastest)

When the source audio format is acceptable:

```bash
# Extract as AAC (if source is AAC)
ffmpeg -i video.mp4 -vn -c:a copy audio.aac

# Extract as M4A container (AAC audio)
ffmpeg -i video.mp4 -vn -c:a copy audio.m4a
```

| Option | Purpose |
|--------|---------|
| `-vn` | Disable video |
| `-c:a copy` | Copy audio without re-encoding |

### Determine Source Format

First, check what audio format is in the video:

```bash
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 video.mp4
```

Common results: `aac`, `mp3`, `opus`, `vorbis`, `ac3`, `eac3`

## Convert During Extraction

### To MP3

```bash
# High quality (VBR ~190 kbps)
ffmpeg -i video.mp4 -vn -c:a libmp3lame -q:a 2 audio.mp3

# Fixed bitrate
ffmpeg -i video.mp4 -vn -c:a libmp3lame -b:a 192k audio.mp3

# Maximum quality
ffmpeg -i video.mp4 -vn -c:a libmp3lame -q:a 0 audio.mp3
```

| Quality | Approx Bitrate |
|---------|----------------|
| `-q:a 0` | ~245 kbps |
| `-q:a 2` | ~190 kbps |
| `-q:a 4` | ~165 kbps |
| `-q:a 6` | ~130 kbps |
| `-q:a 9` | ~65 kbps |

### To AAC

```bash
# Default AAC encoder
ffmpeg -i video.mp4 -vn -c:a aac -b:a 192k audio.m4a

# Using libfdk_aac (if available, higher quality)
ffmpeg -i video.mp4 -vn -c:a libfdk_aac -b:a 192k audio.m4a
```

### To WAV (PCM)

```bash
# 16-bit PCM (CD quality)
ffmpeg -i video.mp4 -vn -c:a pcm_s16le audio.wav

# 24-bit PCM
ffmpeg -i video.mp4 -vn -c:a pcm_s24le audio.wav

# 32-bit float
ffmpeg -i video.mp4 -vn -c:a pcm_f32le audio.wav
```

### To FLAC (Lossless)

```bash
ffmpeg -i video.mp4 -vn -c:a flac audio.flac
```

### To Opus

```bash
ffmpeg -i video.mp4 -vn -c:a libopus -b:a 128k audio.opus
```

### To OGG Vorbis

```bash
ffmpeg -i video.mp4 -vn -c:a libvorbis -q:a 5 audio.ogg
```

## Audio Properties

### Sample Rate

```bash
# Change sample rate to 44.1 kHz
ffmpeg -i video.mp4 -vn -ar 44100 -c:a libmp3lame audio.mp3

# Common sample rates: 22050, 44100, 48000, 96000
```

### Channels

```bash
# Convert to mono
ffmpeg -i video.mp4 -vn -ac 1 -c:a libmp3lame audio.mp3

# Convert to stereo
ffmpeg -i video.mp4 -vn -ac 2 -c:a libmp3lame audio.mp3
```

### Bitrate

```bash
# Fixed bitrate
ffmpeg -i video.mp4 -vn -b:a 256k -c:a aac audio.m4a

# Variable bitrate (quality-based)
ffmpeg -i video.mp4 -vn -q:a 2 -c:a libmp3lame audio.mp3
```

## Extract Specific Time Range

```bash
# Extract from 1:00 to 2:00
ffmpeg -i video.mp4 -ss 00:01:00 -to 00:02:00 -vn -c:a copy audio.aac

# Extract 30 seconds starting at 1:00
ffmpeg -i video.mp4 -ss 00:01:00 -t 30 -vn -c:a libmp3lame audio.mp3
```

## Multiple Audio Tracks

### List Audio Tracks

```bash
ffprobe -v error -select_streams a -show_entries stream=index,codec_name,tags:language -of default=noprint_wrappers=1 video.mkv
```

### Extract Specific Track

```bash
# Extract second audio track
ffmpeg -i video.mkv -map 0:a:1 -c:a copy audio_track2.aac

# Extract all audio tracks
ffmpeg -i video.mkv -map 0:a:0 track1.aac -map 0:a:1 track2.aac
```

### Extract All Tracks to Separate Files

```bash
# Using stream mapping
ffmpeg -i video.mkv \
  -map 0:a:0 -c:a copy track_0.aac \
  -map 0:a:1 -c:a copy track_1.aac \
  -map 0:a:2 -c:a copy track_2.aac
```

## For Speech Recognition

Optimal settings for speech-to-text services:

```bash
# OpenAI Whisper / Most STT APIs
ffmpeg -i video.mp4 -vn -ar 16000 -ac 1 -c:a pcm_s16le audio.wav

# As MP3 (smaller, still compatible)
ffmpeg -i video.mp4 -vn -ar 16000 -ac 1 -c:a libmp3lame -b:a 64k audio.mp3
```

## Loudness Normalization

### EBU R128 Normalization (Broadcast Standard)

```bash
# Two-pass loudness normalization
ffmpeg -i video.mp4 -vn -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=summary -f null -

# Then apply with measured values
ffmpeg -i video.mp4 -vn \
  -af "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=-23.5:measured_TP=-3.2:measured_LRA=7.2:measured_thresh=-34.5:offset=-0.5" \
  -c:a libmp3lame audio.mp3
```

### Simple Normalization

```bash
# Dynamic audio normalization
ffmpeg -i video.mp4 -vn -af "dynaudnorm" -c:a libmp3lame audio.mp3

# Peak normalization
ffmpeg -i video.mp4 -vn -af "volume=0dB" -c:a libmp3lame audio.mp3
```

## Preserve Metadata

```bash
# Copy ID3 tags when extracting
ffmpeg -i video.mp4 -vn -c:a libmp3lame -q:a 2 -map_metadata 0 audio.mp3
```

## From DVD/Blu-ray

### Extract AC3/DTS Audio

```bash
# Copy AC3 audio
ffmpeg -i movie.mkv -vn -map 0:a:0 -c:a copy audio.ac3

# Convert DTS to AC3
ffmpeg -i movie.mkv -vn -map 0:a:0 -c:a ac3 -b:a 640k audio.ac3
```

## Batch Extraction

```bash
# Extract audio from all MP4 files
for f in *.mp4; do
  ffmpeg -i "$f" -vn -c:a libmp3lame -q:a 2 "${f%.mp4}.mp3"
done
```

## Common Issues

### Error: "Discarding empty stream"

Source has no audio track:

```bash
ffprobe -v error -select_streams a -show_entries stream=index video.mp4
# Empty output means no audio
```

### Error: "Invalid audio codec"

Container doesn't support the audio codec:

```bash
# Convert instead of copy
ffmpeg -i video.mp4 -vn -c:a aac audio.m4a
```

### Sync Issues

Audio drifts from original:

```bash
# Reset timestamps
ffmpeg -i video.mp4 -vn -c:a copy -acodec copy -avoid_negative_ts 1 audio.aac
```

## Next Steps

- [Audio Mixing](mixing.md) - Combine multiple audio sources
- [Audio Effects](effects.md) - Apply filters and effects
