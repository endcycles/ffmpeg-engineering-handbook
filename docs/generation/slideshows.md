# Slideshows

Create video slideshows from images with transitions and effects.

## Basic Slideshow

### Fixed Duration Per Image

```bash
# Each image shown for 3 seconds, 25fps output
ffmpeg -framerate 1/3 -pattern_type glob -i '*.jpg' \
  -c:v libx264 -r 25 -pix_fmt yuv420p \
  slideshow.mp4
```

| Option | Meaning |
|--------|---------|
| `-framerate 1/3` | 1 frame every 3 seconds |
| `-r 25` | Output at 25fps |
| `-pix_fmt yuv420p` | Compatible pixel format |

### From Numbered Images

```bash
ffmpeg -framerate 1/5 -i image_%04d.jpg \
  -c:v libx264 -r 30 -pix_fmt yuv420p \
  slideshow.mp4
```

### Variable Frame Rate

```bash
# Specify duration per image with concat demuxer
# Create input file (input.txt):
# file 'image1.jpg'
# duration 2
# file 'image2.jpg'
# duration 5
# file 'image3.jpg'
# duration 3
# file 'image3.jpg'  # Last file repeated for duration to work

ffmpeg -f concat -i input.txt -c:v libx264 -pix_fmt yuv420p slideshow.mp4
```

## With Audio

```bash
ffmpeg -framerate 1/3 -pattern_type glob -i '*.jpg' \
  -i background.mp3 \
  -c:v libx264 -r 25 -pix_fmt yuv420p \
  -c:a aac -b:a 192k \
  -shortest \
  slideshow.mp4
```

## Ken Burns Effect

Zoom and pan for dynamic slideshows:

### Zoom In

```bash
ffmpeg -loop 1 -i image.jpg -t 5 \
  -filter_complex "scale=8000:-1,zoompan=z='zoom+0.001':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=125:s=1920x1080:fps=25" \
  -c:v libx264 -pix_fmt yuv420p \
  output.mp4
```

### Zoom Out

```bash
ffmpeg -loop 1 -i image.jpg -t 5 \
  -filter_complex "scale=8000:-1,zoompan=z='if(lte(zoom,1.0),1.5,max(1.001,zoom-0.001))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=125:s=1920x1080:fps=25" \
  -c:v libx264 -pix_fmt yuv420p \
  output.mp4
```

### Pan Across

```bash
ffmpeg -loop 1 -i image.jpg -t 5 \
  -filter_complex "scale=-1:1080,zoompan=z='1':x='(iw-iw/zoom)*t/5':y='0':d=125:s=1920x1080:fps=25" \
  -c:v libx264 -pix_fmt yuv420p \
  output.mp4
```

### Multiple Images with Ken Burns

```bash
ffmpeg \
  -loop 1 -t 4 -i img1.jpg \
  -loop 1 -t 4 -i img2.jpg \
  -loop 1 -t 4 -i img3.jpg \
  -filter_complex \
    "[0:v]scale=8000:-1,zoompan=z='zoom+0.001':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=100:s=1920x1080:fps=25[v0]; \
     [1:v]scale=8000:-1,zoompan=z='if(lte(zoom,1.0),1.5,max(1.001,zoom-0.001))':d=100:s=1920x1080:fps=25[v1]; \
     [2:v]scale=8000:-1,zoompan=z='zoom+0.001':x='0':y='ih/2-(ih/zoom/2)':d=100:s=1920x1080:fps=25[v2]; \
     [v0][v1][v2]concat=n=3:v=1" \
  -c:v libx264 -pix_fmt yuv420p \
  kenburns.mp4
```

## Transitions

### Crossfade Between Images

```bash
ffmpeg \
  -loop 1 -t 5 -i img1.jpg \
  -loop 1 -t 5 -i img2.jpg \
  -loop 1 -t 5 -i img3.jpg \
  -filter_complex \
    "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=4:d=1[v0]; \
     [1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v1]; \
     [2:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1[v2]; \
     [v0][v1]xfade=transition=fade:duration=1:offset=4[t1]; \
     [t1][v2]xfade=transition=fade:duration=1:offset=8" \
  -c:v libx264 -pix_fmt yuv420p \
  slideshow.mp4
```

### Available Transitions

```
fade, fadeblack, fadewhite, wipeleft, wiperight, wipeup, wipedown,
slideleft, slideright, slideup, slidedown, smoothleft, smoothright,
circlecrop, rectcrop, circleclose, circleopen, dissolve, pixelize,
radial, hblur, wipetl, wipetr, wipebl, wipebr, squeezeh, squeezev,
zoomin
```

### Example Transitions

```bash
# Slide left
xfade=transition=slideleft:duration=1:offset=4

# Circle close
xfade=transition=circleclose:duration=1:offset=4

# Dissolve
xfade=transition=dissolve:duration=1:offset=4

# Zoom in
xfade=transition=zoomin:duration=1:offset=4
```

## Different Image Sizes

### Scale and Pad (Letterbox)

```bash
ffmpeg -framerate 1/3 -pattern_type glob -i '*.jpg' \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
  -c:v libx264 -r 25 -pix_fmt yuv420p \
  slideshow.mp4
```

### Scale and Crop (Fill)

```bash
ffmpeg -framerate 1/3 -pattern_type glob -i '*.jpg' \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1" \
  -c:v libx264 -r 25 -pix_fmt yuv420p \
  slideshow.mp4
```

## With Text Overlays

### Title on Each Image

```bash
ffmpeg -framerate 1/3 -pattern_type glob -i '*.jpg' \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,drawtext=text='My Slideshow':x=(w-text_w)/2:y=h-50:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.5" \
  -c:v libx264 -r 25 -pix_fmt yuv420p \
  slideshow.mp4
```

### Different Text Per Image

Use concat demuxer with individual processing:

```bash
# Process each image with text
ffmpeg -loop 1 -t 3 -i img1.jpg -vf "scale=1920:1080,drawtext=text='Photo 1'" -c:v libx264 temp1.mp4
ffmpeg -loop 1 -t 3 -i img2.jpg -vf "scale=1920:1080,drawtext=text='Photo 2'" -c:v libx264 temp2.mp4

# Concatenate
ffmpeg -f concat -i <(echo -e "file 'temp1.mp4'\nfile 'temp2.mp4'") -c copy slideshow.mp4
```

## Aspect Ratio Options

### 16:9 (Widescreen)

```bash
-vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
```

### 9:16 (Vertical/Stories)

```bash
-vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2"
```

### 1:1 (Square)

```bash
-vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2"
```

### 4:3 (Traditional)

```bash
-vf "scale=1440:1080:force_original_aspect_ratio=decrease,pad=1440:1080:(ow-iw)/2:(oh-ih)/2"
```

## Background Options

### Solid Color

```bash
-vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=white"
```

### Gradient (using lavfi)

```bash
# Create gradient background
ffmpeg -f lavfi -i "gradients=s=1920x1080:c0=blue:c1=purple" -t 15 gradient_bg.mp4

# Overlay images
ffmpeg -i gradient_bg.mp4 -framerate 1/5 -pattern_type glob -i '*.jpg' \
  -filter_complex "[1:v]scale=1600:-1[img];[0:v][img]overlay=(W-w)/2:(H-h)/2" \
  slideshow.mp4
```

### Blurred Background

```bash
ffmpeg -framerate 1/3 -pattern_type glob -i '*.jpg' \
  -filter_complex \
    "[0:v]split[orig][blur]; \
     [blur]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=20:20[bg]; \
     [orig]scale=1920:1080:force_original_aspect_ratio=decrease[fg]; \
     [bg][fg]overlay=(W-w)/2:(H-h)/2" \
  -c:v libx264 -r 25 -pix_fmt yuv420p \
  slideshow.mp4
```

## Looping

### Create Looping Video

```bash
# Play twice
ffmpeg -stream_loop 1 -i slideshow.mp4 -c copy slideshow_loop.mp4

# Play 5 times
ffmpeg -stream_loop 4 -i slideshow.mp4 -c copy slideshow_5x.mp4
```

### Seamless Loop

Add crossfade between end and start:

```bash
# With xfade at loop point
ffmpeg -i slideshow.mp4 \
  -filter_complex "[0:v]split[main][end];[end]trim=0:1,setpts=PTS-STARTPTS[endclip];[main]trim=1,setpts=PTS-STARTPTS[mainclip];[mainclip][endclip]xfade=transition=fade:duration=0.5:offset=duration-0.5" \
  looping.mp4
```

## Script for Complex Slideshows

```bash
#!/bin/bash
# slideshow.sh - Create slideshow with transitions

OUTPUT="slideshow.mp4"
DURATION=4
TRANSITION=1
FPS=25

# Build filter
filter=""
offset=0
count=0

for img in *.jpg; do
  if [ $count -eq 0 ]; then
    filter="[$count:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p[v$count]"
  else
    filter="$filter;[$count:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p[v$count]"
  fi
  ((count++))
done

# Add xfade transitions
for ((i=0; i<count-1; i++)); do
  next=$((i+1))
  if [ $i -eq 0 ]; then
    filter="$filter;[v0][v1]xfade=transition=fade:duration=$TRANSITION:offset=$((DURATION-TRANSITION))[x1]"
    offset=$((DURATION*2-TRANSITION))
  else
    filter="$filter;[x$i][v$next]xfade=transition=fade:duration=$TRANSITION:offset=$((offset-TRANSITION))[x$next]"
    offset=$((offset+DURATION-TRANSITION))
  fi
done

# Build input arguments
inputs=""
for img in *.jpg; do
  inputs="$inputs -loop 1 -t $DURATION -i $img"
done

# Execute
eval ffmpeg $inputs -filter_complex "$filter" -c:v libx264 -pix_fmt yuv420p $OUTPUT
```

## Common Issues

### Green Frames

Missing pixel format conversion:
```bash
-pix_fmt yuv420p
```

### Audio/Video Length Mismatch

Use `-shortest` to match lengths:
```bash
ffmpeg -framerate 1/3 -i '*.jpg' -i audio.mp3 -shortest slideshow.mp4
```

### Wrong Image Order

Rename images with proper numbering:
```bash
i=1; for f in *.jpg; do mv "$f" "$(printf '%04d' $i).jpg"; ((i++)); done
```

## Next Steps

- [Ken Burns Details](../advanced/speed.md) - More animation techniques
- [Thumbnails](thumbnails.md) - Extract frames from slideshows
