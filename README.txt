TRIM CLIP v7.4

INSTALL
-------
Run:
  Install Trim Clip v7.4.bat

Trim Clip installs:
  %USERPROFILE%\TrimClip\Trim Clip.ps1

If ffmpeg.exe is included beside the installer, it is copied to:
  %USERPROFILE%\TrimClip\ffmpeg.exe

If no local ffmpeg.exe is present, Trim Clip can also use FFmpeg from Windows PATH.

The installer adds one MP4 right-click command:
  Trim clip...

USE
---
Right-click an MP4 and choose:
  Trim clip...

Commands:
  Enter      Keep the last 30 seconds
  45         Keep the last 45 seconds
  30s        Remove 30 seconds from the start
  30e        Remove 30 seconds from the end
  30s30e     Remove 30 seconds from both ends
  30s20e     Remove 30 seconds from start and 20 seconds from end

Spaces and optional dashes are also accepted:
  30s 20e
  30 -s 20 -e

OUTPUT
------
Examples:
  clip_trimmed_30.mp4
  clip_trimmed_30s.mp4
  clip_trimmed_30e.mp4
  clip_trimmed_30s30e.mp4

The output is saved beside the original MP4.
The original file is never deleted by Trim Clip.

UNINSTALL
---------
Run:
  Uninstall Trim Clip v7.4.bat

The uninstaller removes only:
- The current "Trim clip..." context-menu entry
- %USERPROFILE%\TrimClip\Trim Clip.ps1

It does not delete ffmpeg.exe.
