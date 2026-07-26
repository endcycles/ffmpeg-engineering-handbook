#!/usr/bin/env bash

set -euo pipefail

video=${1:?"usage: generate-sprite-vtt.sh VIDEO [OUTPUT_DIRECTORY]"}
output_dir=${2:-sprite-output}
interval=2
width=160
height=90
cols=10
rows=10

video_dir=$(cd -- "$(dirname -- "$video")" && pwd -P)
video_path="$video_dir/$(basename -- "$video")"
mkdir -p -- "$output_dir"
output_dir=$(cd -- "$output_dir" && pwd -P)

duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$video_path")

if ! awk -v value="$duration" 'BEGIN { exit !(value > 0) }'; then
  printf 'Could not determine a positive duration for %s\n' "$video" >&2
  exit 1
fi

(
  cd -- "$output_dir"
  ffmpeg -hide_banner -n -i "$video_path" \
    -vf "fps=1/$interval,scale=$width:$height,tile=${cols}x${rows}" \
    -fps_mode vfr sprite_%03d.jpg

  awk -v duration="$duration" -v interval="$interval" \
      -v width="$width" -v height="$height" -v cols="$cols" -v rows="$rows" '
    function stamp(t, h, m, s) {
      h = int(t / 3600)
      m = int((t - h * 3600) / 60)
      s = t - h * 3600 - m * 60
      return sprintf("%02d:%02d:%06.3f", h, m, s)
    }
    BEGIN {
      print "WEBVTT\n"
      frames = int((duration + interval - 0.000001) / interval)
      cells = cols * rows
      for (i = 0; i < frames; i++) {
        start = i * interval
        end = (i + 1) * interval
        if (end > duration) end = duration
        page = int(i / cells) + 1
        cell = i % cells
        x = (cell % cols) * width
        y = int(cell / cols) * height
        printf "%s --> %s\n", stamp(start), stamp(end)
        printf "sprite_%03d.jpg#xywh=%d,%d,%d,%d\n\n", page, x, y, width, height
      }
    }
  ' > thumbnails.vtt
)
