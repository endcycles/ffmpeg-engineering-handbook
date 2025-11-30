# Audio Mixing

Combining multiple audio sources—background music, voiceover, sound effects—is essential for video production.

## Basic Audio Mixing

### Mix Two Audio Sources

```bash
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex "[0:a][1:a]amix=inputs=2:duration=longest[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

| Parameter | Meaning |
|-----------|---------|
| `inputs=2` | Number of audio inputs |
| `duration=longest` | Use longest input's duration |
| `duration=shortest` | Use shortest input's duration |
| `duration=first` | Use first input's duration |

### Mix with Volume Adjustment

Lower music volume to make speech audible:

```bash
ffmpeg -i video_with_speech.mp4 -i background_music.mp3 \
  -filter_complex "[1:a]volume=0.3[music];[0:a][music]amix=inputs=2:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

### Mix Multiple Sources

```bash
ffmpeg -i video.mp4 -i music.mp3 -i sfx.mp3 \
  -filter_complex \
    "[1:a]volume=0.3[music]; \
     [2:a]volume=0.5[sfx]; \
     [0:a][music][sfx]amix=inputs=3:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

## Replace Audio

### Complete Replacement

```bash
ffmpeg -i video.mp4 -i new_audio.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -shortest output.mp4
```

### Keep Video Length

```bash
# If audio is shorter, video continues silent
ffmpeg -i video.mp4 -i short_audio.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac output.mp4

# If audio is longer, trim to video length
ffmpeg -i video.mp4 -i long_audio.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -shortest output.mp4
```

## Ducking (Voice Over Music)

Lower music when speech is detected (manual approach):

```bash
# Define when to duck (volume envelope)
ffmpeg -i video_with_speech.mp4 -i music.mp3 \
  -filter_complex \
    "[1:a]volume='if(between(t,5,15),0.2,1)':eval=frame[music]; \
     [0:a][music]amix=inputs=2[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

This ducks music between 5-15 seconds (when speech occurs).

### Sidechain Compression (Advanced)

```bash
ffmpeg -i music.mp3 -i voiceover.mp3 \
  -filter_complex "[0:a][1:a]sidechaincompress=threshold=0.03:ratio=9:attack=200:release=1000[a]" \
  -map "[a]" -c:a aac output.m4a
```

## Delay Audio

### Offset Second Audio Track

```bash
# Delay background music by 2 seconds
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex "[1:a]adelay=2000|2000[delayed];[0:a][delayed]amix=inputs=2:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

`adelay=2000|2000` delays both channels by 2000ms.

## Fade Audio

### Fade In/Out on Mix

```bash
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex \
    "[1:a]afade=t=in:d=2,afade=t=out:st=28:d=2,volume=0.3[music]; \
     [0:a][music]amix=inputs=2:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

## Channel Manipulation

### Mono to Stereo

```bash
ffmpeg -i mono.mp3 -af "channelmap=0|0" -c:a libmp3lame stereo.mp3
```

### Stereo to Mono

```bash
# Downmix both channels equally
ffmpeg -i stereo.mp3 -af "pan=mono|c0=0.5*c0+0.5*c1" mono.mp3

# Or use -ac
ffmpeg -i stereo.mp3 -ac 1 mono.mp3
```

### Left/Right Channel Extraction

```bash
# Left channel only to mono
ffmpeg -i stereo.mp3 -af "pan=mono|c0=FL" left.mp3

# Right channel only to mono
ffmpeg -i stereo.mp3 -af "pan=mono|c0=FR" right.mp3

# Left channel to both stereo channels
ffmpeg -i stereo.mp3 -af "pan=stereo|c0=FL|c1=FL" left_stereo.mp3
```

### Swap Channels

```bash
ffmpeg -i input.mp3 -af "pan=stereo|c0=c1|c1=c0" swapped.mp3
```

## Surround Sound

### Create 5.1 from 6 Mono Files

```bash
ffmpeg \
  -i front_left.wav \
  -i front_right.wav \
  -i center.wav \
  -i lfe.wav \
  -i surround_left.wav \
  -i surround_right.wav \
  -filter_complex "[0:a][1:a][2:a][3:a][4:a][5:a]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[a]" \
  -map "[a]" surround.wav
```

### Downmix 5.1 to Stereo

```bash
ffmpeg -i surround.mp4 -ac 2 -c:a aac stereo.mp4
```

### Encode Video with 5.1 Audio

```bash
ffmpeg -i video.mp4 -i surround.wav \
  -map 0:v -map 1:a \
  -c:v copy -c:a ac3 -ac 6 -ar 48000 -b:a 640k \
  output.mkv
```

## Audio Normalization in Mix

### Normalize Before Mixing

```bash
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex \
    "[0:a]dynaudnorm[speech]; \
     [1:a]dynaudnorm,volume=0.3[music]; \
     [speech][music]amix=inputs=2:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

### Loudness Normalization (Broadcast Standard)

```bash
# EBU R128 after mixing
ffmpeg -i mixed.mp4 \
  -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
  -c:v copy -c:a aac output.mp4
```

## Crossfade Between Audio

### Audio-Only Crossfade

```bash
ffmpeg -i audio1.mp3 -i audio2.mp3 \
  -filter_complex "[0:a][1:a]acrossfade=d=3:c1=tri:c2=tri[a]" \
  -map "[a]" output.mp3
```

| Curve | Description |
|-------|-------------|
| `tri` | Triangular (linear) |
| `qsin` | Quarter sine |
| `hsin` | Half sine |
| `log` | Logarithmic |
| `exp` | Exponential |
| `par` | Parabolic |

### Crossfade Multiple Files

```bash
ffmpeg -i a1.mp3 -i a2.mp3 -i a3.mp3 \
  -filter_complex \
    "[0:a][1:a]acrossfade=d=2[t1]; \
     [t1][2:a]acrossfade=d=2[a]" \
  -map "[a]" output.mp3
```

## Concatenate Audio

### Same Format (Fast)

```bash
# Create file list
echo "file 'audio1.mp3'" > list.txt
echo "file 'audio2.mp3'" >> list.txt
echo "file 'audio3.mp3'" >> list.txt

# Concatenate
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp3
```

### Different Formats

```bash
ffmpeg -i audio1.wav -i audio2.mp3 -i audio3.aac \
  -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1[a]" \
  -map "[a]" -c:a libmp3lame output.mp3
```

## Insert Audio at Specific Time

```bash
# Insert sound effect at 10 seconds
ffmpeg -i video.mp4 -i sfx.mp3 \
  -filter_complex \
    "[1:a]adelay=10000|10000[sfx]; \
     [0:a][sfx]amix=inputs=2:duration=first[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac output.mp4
```

## Common Issues

### Volume Too Loud After Mixing

amix increases volume. Normalize after:

```bash
-filter_complex "[0:a][1:a]amix=inputs=2,dynaudnorm[a]"
```

Or adjust input volumes before mixing.

### Audio/Video Sync Drift

```bash
# Re-sync audio
ffmpeg -i video.mp4 -af "aresample=async=1" -c:v copy output.mp4
```

### Different Sample Rates

Normalize before mixing:

```bash
-filter_complex "[0:a]aresample=44100[a0];[1:a]aresample=44100[a1];[a0][a1]amix=inputs=2[a]"
```

## Next Steps

- [Audio Effects](effects.md) - Apply EQ, compression, reverb
- [Surround Sound](surround.md) - Multi-channel audio details
