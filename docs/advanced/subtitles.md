# Text & Subtitles

Add text overlays, burn subtitles, and handle caption files.

## Text Overlay (drawtext)

### Basic Text

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Hello World':x=100:y=100:fontsize=48:fontcolor=white" \
  output.mp4
```

### Text Properties

| Property | Description | Example |
|----------|-------------|---------|
| `text` | Text content | `text='Hello'` |
| `textfile` | Read from file | `textfile=caption.txt` |
| `fontfile` | Font file path | `fontfile=/path/to/font.ttf` |
| `fontsize` | Font size | `fontsize=48` |
| `fontcolor` | Text color | `fontcolor=white` |
| `x`, `y` | Position | `x=100:y=100` |
| `alpha` | Transparency (0-1) | `alpha=0.8` |

### Positioning Expressions

```bash
# Center text
-vf "drawtext=text='Centered':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=48"

# Bottom center
-vf "drawtext=text='Bottom':x=(w-text_w)/2:y=h-text_h-20:fontsize=48"

# Top right
-vf "drawtext=text='Corner':x=w-text_w-10:y=10:fontsize=48"
```

### Text with Background Box

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Subtitle':x=(w-text_w)/2:y=h-80:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.6:boxborderw=10" \
  output.mp4
```

| Property | Description |
|----------|-------------|
| `box=1` | Enable background box |
| `boxcolor` | Box color with opacity |
| `boxborderw` | Padding around text |
| `borderw` | Text border/outline |
| `bordercolor` | Border color |

### Text with Outline

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Outlined':fontsize=48:fontcolor=white:borderw=2:bordercolor=black:x=100:y=100" \
  output.mp4
```

### Shadow Effect

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Shadow':fontsize=48:fontcolor=white:shadowcolor=black@0.5:shadowx=3:shadowy=3:x=100:y=100" \
  output.mp4
```

## Timed Text

### Show at Specific Time

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Now visible':enable='between(t,5,10)':x=100:y=100:fontsize=48" \
  output.mp4
```

### Fade Text In/Out

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Fading':x=100:y=100:fontsize=48:alpha='if(lt(t,2),t/2,if(lt(t,8),1,(10-t)/2))':enable='between(t,0,10)'" \
  output.mp4
```

### Multiple Timed Messages

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='First':x=100:y=100:fontsize=48:enable='between(t,0,5)', \
       drawtext=text='Second':x=100:y=100:fontsize=48:enable='between(t,5,10)', \
       drawtext=text='Third':x=100:y=100:fontsize=48:enable='between(t,10,15)'" \
  output.mp4
```

## Dynamic Text

### Timecode Display

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='%{pts\\:hms}':x=10:y=10:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5" \
  output.mp4
```

### Frame Number

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Frame %{frame_num}':x=10:y=10:fontsize=24" \
  output.mp4
```

### Current Date/Time

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=text='%{localtime\\:%Y-%m-%d %H\\:%M\\:%S}':x=10:y=10:fontsize=24" \
  output.mp4
```

### Text from File

```bash
# Read text content from file
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=caption.txt:x=100:y=100:fontsize=36" \
  output.mp4
```

## Subtitles (SRT, ASS)

### Burn Subtitles into Video

```bash
# SRT subtitles
ffmpeg -i video.mp4 -vf "subtitles=subs.srt" output.mp4

# ASS/SSA subtitles
ffmpeg -i video.mp4 -vf "subtitles=subs.ass" output.mp4
```

### Style SRT Subtitles

```bash
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=2'" \
  output.mp4
```

### Style Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `FontName` | Font family | `FontName=Arial` |
| `FontSize` | Size | `FontSize=24` |
| `PrimaryColour` | Text color (AABBGGRR) | `PrimaryColour=&HFFFFFF` |
| `OutlineColour` | Outline color | `OutlineColour=&H000000` |
| `Outline` | Outline width | `Outline=2` |
| `BorderStyle` | 1=outline, 3=box | `BorderStyle=3` |
| `Shadow` | Shadow depth | `Shadow=1` |
| `Bold` | 0 or 1 | `Bold=1` |
| `Italic` | 0 or 1 | `Italic=1` |

### Background Box for Subtitles

```bash
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF,OutlineColour=&H80000000,Outline=4,BorderStyle=3'" \
  output.mp4
```

### Custom Font

```bash
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:fontsdir=/path/to/fonts:force_style='FontName=CustomFont'" \
  output.mp4
```

## Subtitle Streams

### Add Subtitle Track (Soft Subs)

```bash
# Add SRT as subtitle stream (not burned)
ffmpeg -i video.mp4 -i subs.srt \
  -c copy -c:s srt \
  -metadata:s:s:0 language=eng \
  output.mkv
```

### Extract Subtitles

```bash
# Extract first subtitle track
ffmpeg -i video.mkv -map 0:s:0 subtitles.srt
```

### Multiple Subtitle Tracks

```bash
ffmpeg -i video.mp4 -i english.srt -i spanish.srt \
  -map 0 -map 1 -map 2 \
  -c:v copy -c:a copy -c:s srt \
  -metadata:s:s:0 language=eng -metadata:s:s:0 title="English" \
  -metadata:s:s:1 language=spa -metadata:s:s:1 title="Spanish" \
  output.mkv
```

### Set Default Subtitle

```bash
ffmpeg -i video.mp4 -i subs.srt \
  -c copy -c:s srt \
  -disposition:s:0 default \
  output.mkv
```

## SRT File Format

```srt
1
00:00:01,000 --> 00:00:04,000
First subtitle line

2
00:00:05,000 --> 00:00:08,000
Second subtitle line
With multiple lines

3
00:00:10,000 --> 00:00:15,000
<b>Bold</b> and <i>italic</i> text
```

## ASS File Format (Advanced)

ASS offers more styling control:

```ass
[Script Info]
Title: My Subtitles
ScriptType: v4.00+

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, OutlineColour, BorderStyle, Outline, Shadow, Alignment
Style: Default,Arial,24,&H00FFFFFF,&H00000000,1,2,0,2

[Events]
Format: Layer, Start, End, Style, Text
Dialogue: 0,0:00:01.00,0:00:04.00,Default,First line
Dialogue: 0,0:00:05.00,0:00:08.00,Default,{\b1}Bold{\b0} and {\i1}italic{\i0}
```

### ASS Styling Tags

| Tag | Effect |
|-----|--------|
| `{\b1}` | Bold on |
| `{\b0}` | Bold off |
| `{\i1}` | Italic on |
| `{\i0}` | Italic off |
| `{\fs24}` | Font size 24 |
| `{\c&HFFFFFF&}` | Text color |
| `{\pos(x,y)}` | Position |
| `{\fade(in,out)}` | Fade timing |
| `{\an5}` | Alignment (numpad position) |

## Convert Between Formats

```bash
# SRT to ASS
ffmpeg -i subs.srt subs.ass

# ASS to SRT
ffmpeg -i subs.ass subs.srt

# From video to SRT
ffmpeg -i video.mkv -map 0:s:0 subs.srt
```

## Offset/Sync Subtitles

```bash
# Delay subtitles by 2 seconds
ffmpeg -itsoffset 2 -i subs.srt -c copy subs_delayed.srt

# Using filter
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:charenc=UTF-8,setpts=PTS+2/TB" \
  output.mp4
```

## Animated Text

### Scrolling Text (Credits)

```bash
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=credits.txt:x=(w-text_w)/2:y=h-t*30:fontsize=24" \
  output.mp4
```

### Typing Effect

```bash
# Reveal text character by character
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Typing effect':x=100:y=100:fontsize=48:enable='lt(t,10)':fontcolor_expr='if(lt(mod(t*10,1),0.5),white,black)'" \
  output.mp4
```

## Common Issues

### Special Characters

Escape special characters in shell:

```bash
# Colon
-vf "drawtext=text='Time\\: 10\\:30'"

# Percent
-vf "drawtext=text='100%%'"

# Single quote
-vf "drawtext=text='It'\''s working'"
```

### Character Encoding

```bash
# Specify encoding for subtitles
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:charenc=UTF-8" \
  output.mp4
```

### Font Not Found

```bash
# List available fonts
fc-list

# Specify font directory
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:fontsdir=/path/to/fonts" \
  output.mp4
```

## Next Steps

- [Overlays](overlays.md) - Image and video overlays
- [Complex Filters](complex-filters.md) - Multi-layer compositions
