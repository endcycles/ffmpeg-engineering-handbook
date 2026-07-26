#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
test_dir=$(mktemp -d)
trap 'find "$test_dir" -depth -delete' EXIT
cd -- "$test_dir"

assert_near() {
  local actual=$1
  local expected=$2
  local tolerance=$3
  local label=$4
  awk -v actual="$actual" -v expected="$expected" -v tolerance="$tolerance" \
    -v label="$label" 'BEGIN {
      delta = actual - expected
      if (delta < 0) delta = -delta
      if (delta > tolerance) {
        printf "%s: expected %.6f +/- %.6f, got %.6f\n", label, expected, tolerance, actual > "/dev/stderr"
        exit 1
      }
    }'
}

ffmpeg -hide_banner -loglevel error \
  -f lavfi -i 'testsrc2=size=160x90:rate=120:duration=8' \
  -f lavfi -i 'sine=frequency=1000:sample_rate=48000:duration=8' \
  -map 0:v:0 -map 1:a:0 \
  -c:v libx264 -pix_fmt yuv420p -c:a aac input.mp4

# A 4x time-lapse must be one quarter of the source duration.
ffmpeg -hide_banner -loglevel error -i input.mp4 \
  -vf 'setpts=(PTS-STARTPTS)/4,fps=30' \
  -fps_mode cfr -an timelapse.mp4
duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 timelapse.mp4)
assert_near "$duration" 2 0.05 '4x time-lapse duration'

# Segmented video and audio retiming must remain synchronized.
ffmpeg -hide_banner -loglevel error -i input.mp4 \
  -filter_complex \
    '[0:v]trim=start=0:end=5,setpts=2*(PTS-STARTPTS)[v0];
     [0:a]atrim=start=0:end=5,asetpts=PTS-STARTPTS,atempo=0.5[a0];
     [0:v]trim=start=5,setpts=0.5*(PTS-STARTPTS)[v1];
     [0:a]atrim=start=5,asetpts=PTS-STARTPTS,atempo=2.0[a1];
     [v0][a0][v1][a1]concat=n=2:v=1:a=1[v][a]' \
  -map '[v]' -map '[a]' -c:v libx264 -c:a aac speed-segments.mp4
video_duration=$(ffprobe -v error -select_streams v:0 \
  -show_entries stream=duration -of default=nw=1:nk=1 speed-segments.mp4)
audio_duration=$(ffprobe -v error -select_streams a:0 \
  -show_entries stream=duration -of default=nw=1:nk=1 speed-segments.mp4)
assert_near "$video_duration" 11.5 0.05 'segmented video duration'
assert_near "$audio_duration" 11.5 0.05 'segmented audio duration'

# Quad has rear channels; 4.0 does not. The mapped result must report 5.1.
ffmpeg -hide_banner -loglevel error \
  -f lavfi \
  -i 'aevalsrc=sin(2*PI*220*t)|sin(2*PI*330*t)|sin(2*PI*440*t)|sin(2*PI*550*t):s=48000:d=1:c=quad' \
  -filter_complex \
  '[0:a]aformat=channel_layouts=quad,pan=5.1|FL=FL|FR=FR|FC=0*FL|LFE=0*FL|BL=BL|BR=BR[a]' \
  -map '[a]' output-5.1.wav
layout=$(ffprobe -v error -select_streams a:0 -show_entries stream=channel_layout \
  -of default=nw=1:nk=1 output-5.1.wav)
[[ $layout == '5.1' ]]

# Limit source thumbnails before one 5x4 tile is emitted.
ffmpeg -hide_banner -loglevel error -i input.mp4 \
  -vf "fps=2,select='lt(n,20)',scale=120:68,tile=5x4" \
  -frames:v 1 storyboard.jpg
geometry=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
  -of csv=p=0:s=x storyboard.jpg)
[[ $geometry == '600x272' ]]

# Shift subtitle cues, not video timestamps.
printf '1\n00:00:00,000 --> 00:00:01,000\nTest\n' > subs.srt
ffmpeg -hide_banner -loglevel error \
  -i input.mp4 -itsoffset 2 -i subs.srt \
  -map 0:v:0 -map '0:a?' -map 1:0 \
  -c:v copy -c:a copy -c:s srt subtitled.mkv
subtitle_pts=$(ffprobe -v error -select_streams s:0 -show_entries packet=pts_time \
  -of csv=p=0 subtitled.mkv | sed -n '1p')
assert_near "$subtitle_pts" 2 0.05 'shifted subtitle cue'

# xfade receives numeric offsets derived from the probed duration.
source_duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 input.mp4)
body_end=$(awk -v d="$source_duration" 'BEGIN { printf "%.6f", d - 0.5 }')
fade_at=$(awk -v d="$source_duration" 'BEGIN { printf "%.6f", d - 1.0 }')
ffmpeg -hide_banner -loglevel error -i input.mp4 \
  -filter_complex \
    "[0:v]trim=start=0:end=${body_end},setpts=PTS-STARTPTS,fps=30,format=yuv420p[body];
     [0:v]trim=start=0:end=0.5,setpts=PTS-STARTPTS,fps=30,format=yuv420p[head];
     [body][head]xfade=transition=fade:duration=0.5:offset=${fade_at}[v]" \
  -map '[v]' -an -c:v libx264 -fps_mode cfr looping.mp4
loop_duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 looping.mp4)
assert_near "$loop_duration" 7.5 0.06 'looping xfade duration'

# More than 100 thumbnails must paginate without out-of-bounds VTT rectangles.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i 'testsrc2=size=160x90:rate=1:duration=205' \
  -c:v libx264 -pix_fmt yuv420p long.mp4
"$repo_dir/scripts/generate-sprite-vtt.sh" long.mp4 sprites >/dev/null 2>&1
[[ -f sprites/sprite_001.jpg && -f sprites/sprite_002.jpg ]]
awk '
  /^sprite_/ {
    split($1, parts, "#xywh=")
    split(parts[2], box, ",")
    if (box[1] < 0 || box[2] < 0 || box[1] + box[3] > 1600 || box[2] + box[4] > 900) exit 1
  }
' sprites/thumbnails.vtt
last_end=$(awk '/ --> / { end=$3 } END { print end }' sprites/thumbnails.vtt)
[[ $last_end == '00:03:25.000' ]]

printf 'repaired recipe smoke tests passed\n'
