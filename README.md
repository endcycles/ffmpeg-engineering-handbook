# FFmpeg Engineering Handbook

Practical FFmpeg guidance for inspecting media, choosing a processing path,
running copyable commands, and checking the result. The topic pages under
[`docs/`](docs/) are the canonical handbook; this README is only the entry
point.

## Tested baseline

Executable examples are being validated against **FFmpeg 8.1.2 “Hoare.”** A
command can still vary by operating system, package source, configure flags,
linked libraries, driver, and hardware. Check the installed binary before
assuming an encoder, decoder, filter, muxer, or accelerator exists.

```bash
ffmpeg -version
ffmpeg -buildconf
ffmpeg -hide_banner -encoders
ffmpeg -hide_banner -filters
ffmpeg -hide_banner -hwaccels
```

For one component, ask the binary directly:

```bash
ffmpeg -hide_banner -h encoder=libx264
ffmpeg -hide_banner -h filter=xfade
ffmpeg -hide_banner -h muxer=hls
```

## Start here

Before changing a file, inspect its complete stream topology:

```bash
ffprobe -v error -of json \
  -show_format -show_streams -show_chapters -show_programs input.mkv
```

Then choose the relevant guide:

### Fundamentals

- [Concepts and terminology](docs/fundamentals/concepts.md)
- [Command anatomy and option scope](docs/fundamentals/command-anatomy.md)
- [Filters and filter graphs](docs/fundamentals/filters.md)

### Core operations

- [Format conversion](docs/operations/conversion.md)
- [Trimming and cutting](docs/operations/trimming.md)
- [Resizing and scaling](docs/operations/scaling.md)
- [Concatenation](docs/operations/concatenation.md)

### Audio

- [Audio extraction](docs/audio/extraction.md)
- [Audio mixing](docs/audio/mixing.md)
- [Audio effects](docs/audio/effects.md)
- [Surround sound](docs/audio/surround.md)

### Advanced workflows

- [Overlays and compositing](docs/advanced/overlays.md)
- [Text and subtitles](docs/advanced/subtitles.md)
- [Speed manipulation](docs/advanced/speed.md)
- [Codec selection](docs/optimization/codecs.md)
- [Hardware acceleration](docs/optimization/hardware.md)

### Generation and automation

- [Thumbnails](docs/generation/thumbnails.md)
- [GIFs](docs/generation/gifs.md)
- [Slideshows](docs/generation/slideshows.md)
- [Storyboards](docs/generation/storyboards.md)
- [Batch processing](docs/automation/batch.md)
- [Troubleshooting](docs/troubleshooting/errors.md)

## One verified example

This transcodes the first video stream and optional first audio stream. It does
not preserve subtitles, attachments, data streams, chapters, or every metadata
field unless you map them deliberately.

```bash
ffmpeg -n -i input.mkv \
  -map 0:v:0 -map 0:a:0? \
  -c:v libx264 -crf 23 -preset medium \
  -c:a aac -b:a 160k \
  -movflags +faststart output.mp4

ffprobe -v error -of json -show_format -show_streams output.mp4
```

`+faststart` moves MP4 metadata to the front for progressive download. It does
not create HLS, DASH, or another adaptive-streaming package.

## Safety and validation

- Prefer `-n` while developing a command. `-y` overwrites without prompting.
- Treat input stream presence, order, timestamps, channel layout, and color
  properties as data to inspect, not assumptions.
- State which streams are copied, re-encoded, omitted, or generated.
- A zero exit code proves that FFmpeg completed; it does not prove that the
  output duration, topology, sync, color, loudness, or geometry is correct.
- Do not run untrusted media or paths through shell-concatenated commands.

The complete FFmpeg modernization backlog and supporting evidence are recorded in the
[repository update report](ffmpeg-engineering-handbook-update-report.md).

## License

[MIT](LICENSE)
