# Audio Effects

FFmpeg provides a comprehensive set of audio filters for processing, enhancement, and creative effects.

## Volume Control

### Simple Volume Adjustment

```bash
# Double volume
ffmpeg -i input.mp3 -af "volume=2.0" output.mp3

# Half volume
ffmpeg -i input.mp3 -af "volume=0.5" output.mp3

# Adjust by decibels
ffmpeg -i input.mp3 -af "volume=6dB" output.mp3
ffmpeg -i input.mp3 -af "volume=-6dB" output.mp3
```

### Dynamic Volume Over Time

```bash
# Fade volume from 0 to 1 over first 3 seconds
ffmpeg -i input.mp3 -af "volume='if(lt(t,3),t/3,1)':eval=frame" output.mp3
```

## Fades

### Fade In

```bash
# 2 second fade in at start
ffmpeg -i input.mp3 -af "afade=t=in:st=0:d=2" output.mp3
```

### Fade Out

```bash
# 3 second fade out at 27 seconds (for 30 second audio)
ffmpeg -i input.mp3 -af "afade=t=out:st=27:d=3" output.mp3
```

### Both Fades

```bash
ffmpeg -i input.mp3 -af "afade=t=in:d=1,afade=t=out:st=29:d=1" output.mp3
```

### Fade Curves

```bash
# Different fade shapes
-af "afade=t=in:d=2:curve=tri"      # Linear
-af "afade=t=in:d=2:curve=qsin"     # Quarter sine (smooth)
-af "afade=t=in:d=2:curve=hsin"     # Half sine
-af "afade=t=in:d=2:curve=log"      # Logarithmic
-af "afade=t=in:d=2:curve=exp"      # Exponential
-af "afade=t=in:d=2:curve=par"      # Parabolic
```

## Normalization

### Peak Normalization

```bash
# Normalize to -3dB peak
ffmpeg -i input.mp3 -af "volume=replaygain" output.mp3
```

### Dynamic Range Normalization

```bash
# Even out loud and quiet parts
ffmpeg -i input.mp3 -af "dynaudnorm" output.mp3

# With parameters
ffmpeg -i input.mp3 -af "dynaudnorm=f=150:g=15:p=0.95" output.mp3
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `f` | 500 | Frame length (smoothing window) |
| `g` | 31 | Gaussian smoothing size |
| `p` | 0.95 | Peak target (0.0-1.0) |

### EBU R128 Loudness Normalization

Two-pass for broadcast-compliant audio:

```bash
# Pass 1: Analyze
ffmpeg -i input.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=summary -f null -

# Pass 2: Apply (use measured values from pass 1)
ffmpeg -i input.mp3 -af \
  "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=-23.0:measured_TP=-2.5:measured_LRA=8.0:measured_thresh=-33.5:offset=-0.5:linear=true" \
  output.mp3
```

| Parameter | Target | Description |
|-----------|--------|-------------|
| `I=-16` | -16 LUFS | Integrated loudness |
| `TP=-1.5` | -1.5 dBTP | True peak |
| `LRA=11` | 11 LU | Loudness range |

## Compression

### Basic Compression

```bash
ffmpeg -i input.mp3 -af "compand=attacks=0.3:decays=0.8:points=-80/-900|-45/-15|-27/-9|0/-7|20/-7" output.mp3
```

### Limiter

```bash
# Limit peaks to -1dB
ffmpeg -i input.mp3 -af "alimiter=limit=0.9:level=1" output.mp3
```

### Noise Gate

```bash
ffmpeg -i input.mp3 -af "agate=threshold=0.02:attack=25:release=150" output.mp3
```

## Equalization

### Low/High Pass Filters

```bash
# Remove frequencies below 80Hz (rumble filter)
ffmpeg -i input.mp3 -af "highpass=f=80" output.mp3

# Remove frequencies above 8kHz
ffmpeg -i input.mp3 -af "lowpass=f=8000" output.mp3

# Both
ffmpeg -i input.mp3 -af "highpass=f=80,lowpass=f=15000" output.mp3
```

### Band Pass

```bash
# Only pass 300-3000Hz (telephone effect)
ffmpeg -i input.mp3 -af "bandpass=f=1650:width_type=h:width=2700" output.mp3
```

### Parametric EQ

```bash
# Boost 100Hz by 6dB
ffmpeg -i input.mp3 -af "equalizer=f=100:t=q:w=1:g=6" output.mp3

# Cut 4kHz by 3dB
ffmpeg -i input.mp3 -af "equalizer=f=4000:t=q:w=2:g=-3" output.mp3
```

| Parameter | Meaning |
|-----------|---------|
| `f` | Center frequency |
| `t` | Width type (q, h, o) |
| `w` | Width value |
| `g` | Gain in dB |

### Multiple EQ Bands

```bash
ffmpeg -i input.mp3 -af \
  "equalizer=f=60:t=q:w=1:g=3, \
   equalizer=f=170:t=q:w=1:g=-2, \
   equalizer=f=1000:t=q:w=1:g=1, \
   equalizer=f=5000:t=q:w=2:g=4" \
  output.mp3
```

## Noise Reduction

### Simple Noise Reduction

```bash
# Reduce constant background noise
ffmpeg -i input.mp3 -af "afftdn=nf=-25" output.mp3
```

| Parameter | Description |
|-----------|-------------|
| `nf=-25` | Noise floor in dB |
| `nt=w` | Noise type (white) |
| `nr=0.5` | Noise reduction amount |

### High Pass for Rumble

```bash
ffmpeg -i input.mp3 -af "highpass=f=60,lowpass=f=15000" output.mp3
```

## Speed and Pitch

### Change Speed (Affects Pitch)

```bash
# 2x speed (also raises pitch)
ffmpeg -i input.mp3 -af "atempo=2.0" output.mp3

# 0.5x speed (also lowers pitch)
ffmpeg -i input.mp3 -af "atempo=0.5" output.mp3
```

**Note**: atempo range is 0.5 to 100. Chain for higher speeds:

```bash
# 4x speed
ffmpeg -i input.mp3 -af "atempo=2.0,atempo=2.0" output.mp3
```

### Change Speed (Preserve Pitch)

```bash
# Using rubberband filter (if available)
ffmpeg -i input.mp3 -af "rubberband=tempo=1.5" output.mp3
```

### Change Pitch (Preserve Speed)

```bash
# Shift pitch up
ffmpeg -i input.mp3 -af "asetrate=44100*1.25,aresample=44100" output.mp3

# Shift pitch down
ffmpeg -i input.mp3 -af "asetrate=44100*0.8,aresample=44100" output.mp3
```

## Reverb and Echo

### Simple Echo

```bash
# Single echo
ffmpeg -i input.mp3 -af "aecho=0.8:0.88:60:0.4" output.mp3

# Multiple echoes
ffmpeg -i input.mp3 -af "aecho=0.8:0.88:60|100|180:0.4|0.3|0.2" output.mp3
```

| Parameters | Meaning |
|------------|---------|
| 0.8 | Input gain |
| 0.88 | Output gain |
| 60 | Delay in ms |
| 0.4 | Decay |

### Reverb

```bash
ffmpeg -i input.mp3 -af "aecho=0.8:0.9:1000|1800:0.3|0.25" output.mp3
```

### Chorus Effect

```bash
ffmpeg -i input.mp3 -af "chorus=0.7:0.9:55:0.4:0.25:2" output.mp3
```

## Stereo Effects

### Widen Stereo

```bash
ffmpeg -i input.mp3 -af "stereotools=slev=1:sbal=0:mlev=1:mpan=0:base=0.5:phase=0:mode=lr>lr:msc=true" output.mp3
```

### Create Fake Stereo

```bash
# From mono
ffmpeg -i mono.mp3 -af "aecho=0.8:0.88:6:0.4,channelsplit=channel_layout=stereo[L][R];[L][R]amerge=inputs=2" output.mp3
```

### Swap Channels

```bash
ffmpeg -i input.mp3 -af "pan=stereo|c0=c1|c1=c0" output.mp3
```

## Special Effects

### Tremolo

```bash
ffmpeg -i input.mp3 -af "tremolo=f=5:d=0.5" output.mp3
```

### Vibrato

```bash
ffmpeg -i input.mp3 -af "vibrato=f=5:d=0.5" output.mp3
```

### Flanger

```bash
ffmpeg -i input.mp3 -af "flanger=delay=0:depth=2:regen=0:width=71:speed=0.5:shape=triangular:phase=25" output.mp3
```

### Phaser

```bash
ffmpeg -i input.mp3 -af "aphaser=type=t:speed=0.5:decay=0.4" output.mp3
```

### Robot Voice

```bash
ffmpeg -i input.mp3 -af "afftfilt=real='hypot(re,im)*sin(0)':imag='hypot(re,im)*cos(0)':win_size=512:overlap=0.75" output.mp3
```

### Telephone Effect

```bash
ffmpeg -i input.mp3 -af "highpass=f=300,lowpass=f=3400" output.mp3
```

### AM Radio Effect

```bash
ffmpeg -i input.mp3 -af "highpass=f=100,lowpass=f=5000,volume=0.8" output.mp3
```

## Chaining Effects

Multiple effects can be chained with commas:

```bash
ffmpeg -i input.mp3 -af \
  "highpass=f=80, \
   lowpass=f=15000, \
   equalizer=f=100:t=q:w=1:g=3, \
   dynaudnorm, \
   afade=t=in:d=1, \
   afade=t=out:st=29:d=1" \
  output.mp3
```

## Visualization

### Generate Waveform

```bash
ffmpeg -i input.mp3 -filter_complex "showwavespic=s=640x120" waveform.png
```

### Generate Spectrogram

```bash
ffmpeg -i input.mp3 -filter_complex "showspectrumpic=s=640x480" spectrogram.png
```

## Next Steps

- [Surround Sound](surround.md) - Multi-channel audio
- [Loudness & Standards](../optimization/web.md) - Broadcast compliance
