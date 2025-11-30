# Surround Sound

Working with multi-channel audio for home theater, broadcast, and immersive experiences.

## Channel Layouts

### Common Layouts

| Layout | Channels | Description |
|--------|----------|-------------|
| mono | 1 | Single channel |
| stereo | 2 | Left, Right |
| 2.1 | 3 | Stereo + LFE |
| 5.1 | 6 | FL, FR, FC, LFE, BL, BR |
| 7.1 | 8 | FL, FR, FC, LFE, BL, BR, SL, SR |

### Channel Abbreviations

| Code | Channel |
|------|---------|
| FL | Front Left |
| FR | Front Right |
| FC | Front Center |
| LFE | Low Frequency Effects (subwoofer) |
| BL | Back Left (Surround Left) |
| BR | Back Right (Surround Right) |
| SL | Side Left |
| SR | Side Right |

## Inspecting Audio Channels

```bash
# Check channel layout
ffprobe -v error -select_streams a:0 \
  -show_entries stream=channel_layout,channels \
  -of default=noprint_wrappers=1 input.mkv

# Detailed audio info
ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name,channels,channel_layout,sample_rate,bit_rate \
  -of json input.mkv
```

## Creating Surround Sound

### From 6 Mono Files

```bash
ffmpeg \
  -i front_left.wav \
  -i front_right.wav \
  -i front_center.wav \
  -i lfe.wav \
  -i back_left.wav \
  -i back_right.wav \
  -filter_complex \
    "[0:a][1:a][2:a][3:a][4:a][5:a]join=inputs=6:channel_layout=5.1:map=0.0-FL|1.0-FR|2.0-FC|3.0-LFE|4.0-BL|5.0-BR[a]" \
  -map "[a]" surround_5.1.wav
```

### From Stereo + Center + LFE + Surrounds

```bash
ffmpeg \
  -i stereo_lr.wav \
  -i center.wav \
  -i lfe.wav \
  -i surround_lr.wav \
  -filter_complex \
    "[0:a]channelsplit=channel_layout=stereo[FL][FR]; \
     [3:a]channelsplit=channel_layout=stereo[BL][BR]; \
     [FL][FR][1:a][2:a][BL][BR]join=inputs=6:channel_layout=5.1[a]" \
  -map "[a]" surround_5.1.wav
```

### Upmix Stereo to 5.1 (Simulated)

```bash
ffmpeg -i stereo.mp3 \
  -af "aresample=channel_layout=5.1" \
  -c:a ac3 surround.ac3
```

**Note**: This is simple upmixing, not true surround extraction.

## Downmixing

### 5.1 to Stereo

```bash
# Automatic downmix
ffmpeg -i surround.mkv -ac 2 -c:a aac stereo.m4a

# Custom downmix matrix
ffmpeg -i surround.mkv \
  -af "pan=stereo|FL<FL+0.707*FC+0.707*BL|FR<FR+0.707*FC+0.707*BR" \
  -c:a aac stereo.m4a
```

### 5.1 to Mono

```bash
ffmpeg -i surround.mkv -ac 1 -c:a aac mono.m4a
```

### Extract Specific Channels

```bash
# Extract center channel only
ffmpeg -i surround.mkv \
  -af "pan=mono|c0=FC" \
  center_only.wav

# Extract front stereo only
ffmpeg -i surround.mkv \
  -af "pan=stereo|FL=FL|FR=FR" \
  front_stereo.wav

# Extract surround channels
ffmpeg -i surround.mkv \
  -af "pan=stereo|FL=BL|FR=BR" \
  surround_stereo.wav
```

## Surround Sound Codecs

### AC3 (Dolby Digital)

```bash
# Encode 5.1 audio as AC3
ffmpeg -i input.wav -c:a ac3 -b:a 640k output.ac3

# With video
ffmpeg -i video.mp4 -i surround.wav \
  -map 0:v -map 1:a \
  -c:v copy -c:a ac3 -b:a 448k \
  output.mkv
```

| Bitrate | Quality |
|---------|---------|
| 384k | DVD standard |
| 448k | High quality |
| 640k | Maximum |

### EAC3 (Dolby Digital Plus)

```bash
ffmpeg -i surround.wav -c:a eac3 -b:a 1024k output.eac3
```

### DTS

```bash
# If dca encoder is available
ffmpeg -i surround.wav -c:a dca -b:a 1536k output.dts

# DTS passthrough (copy)
ffmpeg -i input.mkv -c:a copy output.mkv
```

### PCM (Uncompressed)

```bash
# Linear PCM for Blu-ray
ffmpeg -i surround.wav -c:a pcm_s24le output.wav
```

## Video with Surround Audio

### Encode MKV with 5.1 AC3

```bash
ffmpeg -i video.mp4 -i surround_5.1.wav \
  -map 0:v -map 1:a \
  -c:v libx264 -crf 18 \
  -c:a ac3 -ac 6 -ar 48000 -b:a 448k \
  output.mkv
```

### Encode MKV with Linear PCM

```bash
ffmpeg -i video.mp4 -i surround.wav \
  -map 0:v -map 1:a \
  -c:v libx264 -crf 18 \
  -c:a pcm_s16le -ac 6 -ar 48000 \
  output.mkv
```

### Multiple Audio Tracks

```bash
# Video with both 5.1 and stereo tracks
ffmpeg -i video.mp4 -i surround.wav \
  -filter_complex "[1:a]pan=stereo|FL<FL+0.707*FC+0.707*BL|FR<FR+0.707*FC+0.707*BR[stereo]" \
  -map 0:v -map 1:a -map "[stereo]" \
  -c:v copy \
  -c:a:0 ac3 -b:a:0 448k \
  -c:a:1 aac -b:a:1 192k \
  -metadata:s:a:0 language=eng -metadata:s:a:0 title="5.1 Surround" \
  -metadata:s:a:1 language=eng -metadata:s:a:1 title="Stereo" \
  output.mkv
```

## Channel Layout Manipulation

### Rearrange Channels

```bash
# Swap back left and back right
ffmpeg -i input.wav \
  -af "channelmap=0|1|2|3|5|4:5.1" \
  output.wav
```

### Add Silent Channels

```bash
# Add silent LFE to 4.0
ffmpeg -i quadraphonic.wav \
  -filter_complex \
    "[0:a]channelsplit=channel_layout=4.0[FL][FR][BL][BR]; \
     anullsrc=cl=mono:r=48000[LFE]; \
     [FL][FR][LFE][BL][BR]join=inputs=5:channel_layout=5.0[a]" \
  -map "[a]" output_5.0.wav
```

## Analyze Channels

### Display Channel Levels

```bash
# Show peak levels per channel
ffmpeg -i surround.mkv -af "astats=metadata=1:reset=1" -f null -
```

### Visualize Each Channel

```bash
# Split and visualize
ffmpeg -i surround.mkv -filter_complex \
  "[0:a]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR]; \
   [FL]showwavespic=s=640x120[wFL]; \
   [FR]showwavespic=s=640x120[wFR]; \
   [FC]showwavespic=s=640x120[wFC]; \
   [wFL][wFR][wFC]vstack=inputs=3" \
  channels.png
```

## Common Issues

### Wrong Channel Order

Different sources use different orders. Remap as needed:

```bash
# DTS order to AC3 order
ffmpeg -i input.dts -af "channelmap=0|1|4|5|2|3:5.1" output.ac3
```

### LFE Too Loud/Quiet

```bash
# Boost LFE by 6dB
ffmpeg -i input.wav \
  -filter_complex \
    "[0:a]channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR]; \
     [LFE]volume=6dB[LFE2]; \
     [FL][FR][FC][LFE2][BL][BR]join=inputs=6:channel_layout=5.1[a]" \
  -map "[a]" output.wav
```

### Playback Compatibility

For maximum compatibility, include both 5.1 and stereo tracks:

```bash
ffmpeg -i video.mp4 -i surround.wav \
  -filter_complex "[1:a]pan=stereo|FL<FL+0.707*FC+0.707*BL|FR<FR+0.707*FC+0.707*BR[stereo]" \
  -map 0:v -map 1:a -map "[stereo]" \
  -c:v copy \
  -c:a:0 ac3 -b:a:0 448k \
  -c:a:1 aac -b:a:1 192k \
  output.mkv
```

## Next Steps

- [Audio Mixing](mixing.md) - Combine multiple audio sources
- [Optimization](../optimization/codecs.md) - Codec selection for distribution
