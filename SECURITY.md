# Security Policy

## Reporting

Do not open a public issue for a vulnerability in a handbook script or recipe.
Use GitHub's private vulnerability-reporting feature for this repository. If
that feature is unavailable, contact the repository owner through a private
channel listed on the owner's GitHub profile.

Include the affected page or script, FFmpeg version/build, platform, minimal
reproduction, impact, and any known mitigation. Do not include private media,
credentials, tokens, or identifying paths.

## Supported documentation

Security corrections target the current default branch and latest tagged
handbook release. Older examples may describe unsupported FFmpeg versions; a
historical note is not a claim that the version remains secure.

## Untrusted inputs

Treat media, manifests, subtitle files, filter scripts, URLs, filenames, and
metadata as untrusted. Use a currently supported FFmpeg build, restrict allowed
protocols, avoid shell command construction, set resource/time limits, isolate
processing where practical, and write to a temporary output before validation
and atomic replacement.

The handbook does not promise that parsing hostile media is safe merely because
a command succeeds.
