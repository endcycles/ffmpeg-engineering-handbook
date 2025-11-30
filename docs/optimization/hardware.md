# Hardware Acceleration

Use GPU encoding for dramatically faster processing.

## Overview

| Hardware | Encoder | Decoder | Quality vs Software |
|----------|---------|---------|---------------------|
| NVIDIA | NVENC | NVDEC | ~5-10% larger files |
| Intel | QSV | QSV | ~10-15% larger files |
| AMD | AMF | AMF | ~10-15% larger files |
| Apple | VideoToolbox | VideoToolbox | Good quality |

## NVIDIA (NVENC)

### Check Availability

```bash
ffmpeg -encoders | grep nvenc
# Should show: h264_nvenc, hevc_nvenc
```

### Basic Usage

```bash
# H.264
ffmpeg -i input.mp4 -c:v h264_nvenc output.mp4

# H.265
ffmpeg -i input.mp4 -c:v hevc_nvenc output.mp4
```

### Quality Settings

```bash
# Preset: p1 (fastest) to p7 (slowest/best)
ffmpeg -i input.mp4 -c:v h264_nvenc -preset p4 output.mp4

# Constant quality (like CRF)
ffmpeg -i input.mp4 -c:v h264_nvenc -cq 23 output.mp4

# High quality preset
ffmpeg -i input.mp4 -c:v h264_nvenc -preset p7 -tune hq -cq 20 output.mp4
```

### Hardware Decoding + Encoding

```bash
# Full GPU pipeline
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -c:v h264_nvenc -preset p4 -cq 23 \
  output.mp4
```

### With Scaling on GPU

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1280:720" \
  -c:v h264_nvenc output.mp4
```

## Intel Quick Sync (QSV)

### Check Availability

```bash
ffmpeg -encoders | grep qsv
```

### Basic Usage

```bash
# Initialize device and encode
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 \
  -c:v h264_qsv output.mp4
```

### Quality Settings

```bash
# Global quality (1-51, lower is better)
ffmpeg -init_hw_device qsv=hw \
  -i input.mp4 \
  -c:v h264_qsv -global_quality 23 output.mp4

# Preset: veryfast, faster, fast, medium, slow, slower, veryslow
ffmpeg -init_hw_device qsv=hw \
  -i input.mp4 \
  -c:v h264_qsv -preset slow output.mp4
```

### Hardware Decoding + Encoding

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 \
  -c:v h264_qsv -global_quality 23 output.mp4
```

### With Scaling on GPU

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 \
  -vf "scale_qsv=1280:720" \
  -c:v h264_qsv output.mp4
```

## AMD (AMF/VCE)

### Basic Usage

```bash
# H.264
ffmpeg -i input.mp4 -c:v h264_amf output.mp4

# H.265
ffmpeg -i input.mp4 -c:v hevc_amf output.mp4
```

### Quality Settings

```bash
# Quality preset: quality, balanced, speed
ffmpeg -i input.mp4 -c:v h264_amf -quality quality output.mp4

# Rate control
ffmpeg -i input.mp4 -c:v h264_amf -rc cqp -qp_i 20 -qp_p 23 output.mp4
```

## Apple VideoToolbox (macOS)

### Basic Usage

```bash
# H.264
ffmpeg -i input.mp4 -c:v h264_videotoolbox output.mp4

# H.265
ffmpeg -i input.mp4 -c:v hevc_videotoolbox output.mp4
```

### Quality Settings

```bash
# Quality (0-100)
ffmpeg -i input.mp4 -c:v h264_videotoolbox -q:v 65 output.mp4

# Bitrate control
ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4
```

### ProRes Encoding

```bash
# ProRes 422
ffmpeg -i input.mp4 -c:v prores_videotoolbox -profile:v 2 output.mov

# ProRes 4444
ffmpeg -i input.mp4 -c:v prores_videotoolbox -profile:v 4 output.mov
```

## VAAPI (Linux/AMD/Intel)

### Basic Usage

```bash
# Initialize device
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 \
  -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi output.mp4
```

### With Hardware Decoding

```bash
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 \
  -c:v h264_vaapi output.mp4
```

## Performance Comparison

Typical encoding times for 1-hour 1080p video:

| Method | Time | Quality |
|--------|------|---------|
| libx264 -preset medium | 60 min | Best |
| libx264 -preset fast | 30 min | Very Good |
| h264_nvenc -preset p4 | 5 min | Good |
| h264_qsv | 6 min | Good |
| h264_videotoolbox | 7 min | Good |

## When to Use Hardware Encoding

**Use Hardware**:
- Real-time encoding
- Batch processing many files
- Quick previews
- When time is more important than file size

**Use Software**:
- Final delivery
- Archival
- When quality is paramount
- When bandwidth/storage matters

## Hybrid Workflows

### Decode on GPU, Encode on CPU

```bash
ffmpeg -hwaccel cuda \
  -i input.mp4 \
  -c:v libx264 -crf 23 output.mp4
```

### CPU Filter with GPU Encode

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1280:720,drawtext=text='Test'" \
  -c:v h264_nvenc output.mp4
```

## Troubleshooting

### Check Hardware Support

```bash
# NVIDIA
nvidia-smi

# Intel
vainfo

# Available acceleration methods
ffmpeg -hwaccels
```

### Common Errors

**"No NVENC capable devices found"**
- Check NVIDIA driver installation
- Verify GPU supports NVENC

**"Failed to initialise VAAPI"**
- Check /dev/dri/renderD128 exists
- Verify user has access to device

**"Error initializing QSV"**
- Install Intel Media SDK
- Check libmfx availability

## Quality Tips

1. **Use slightly lower quality settings** - hardware encoders need it
2. **Test with short clips first** - compare quality
3. **Use lookahead** if available - improves quality

```bash
# NVENC with lookahead
ffmpeg -i input.mp4 -c:v h264_nvenc -rc-lookahead 32 output.mp4
```

## Next Steps

- [Bitrate Control](bitrate.md) - Rate control modes
- [Web Optimization](web.md) - Streaming-ready output
