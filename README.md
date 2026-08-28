# TRIM CLIP v7.4

Lightweight Windows context-menu tool (right-click menu) for quickly trimming/cutting MP4 files using PowerShell and FFmpeg.

It supports keeping the last portion of a video or removing time from the beginning, end, or both ends of a clip.

## Installation

1. Download a **static build of FFmpeg** for Windows.

2. Extract the FFmpeg download and copy:

```text
ffmpeg.exe
```

into the same folder as:

```text
Install Trim Clip v7.4.bat
```

Your folder should look something like this:

```text
Trim Clip/
├── Install Trim Clip v7.4.bat
├── Uninstall Trim Clip v7.4.bat
├── Trim Clip.ps1
└── ffmpeg.exe
```

3. Run:

```bat
Install Trim Clip v7.4.bat
```

Trim Clip installs the PowerShell script to:

```text
%USERPROFILE%\TrimClip\Trim Clip.ps1
```

The included `ffmpeg.exe` is copied to:

```text
%USERPROFILE%\TrimClip\ffmpeg.exe
```

After installation, a new command is added to the right-click menu for MP4 files:

```text
Trim clip...
```

## Usage

Right-click an `.mp4` file and select:

```text
Trim clip...
```

Then enter one of the supported commands.

| Command  | Action                                                       |
| -------- | ------------------------------------------------------------ |
| `Enter`  | Keep the last 30 seconds                                     |
| `45`     | Keep the last 45 seconds                                     |
| `30s`    | Remove 30 seconds from the start                             |
| `30e`    | Remove 30 seconds from the end                               |
| `30s30e` | Remove 30 seconds from both ends                             |
| `30s20e` | Remove 30 seconds from the start and 20 seconds from the end |

Spaces and optional dashes are also accepted:

```text
30s 20e
30 -s 20 -e
```

## Output

Trimmed files are saved beside the original MP4.

Examples:

```text
clip_trimmed_30.mp4
clip_trimmed_30s.mp4
clip_trimmed_30e.mp4
clip_trimmed_30s30e.mp4
```

The original file is **never deleted or overwritten** by Trim Clip.

## Uninstallation

Run:

```bat
Uninstall Trim clip v7.4.bat
```

The uninstaller removes only:

- The current `Trim clip...` context-menu entry
- `%USERPROFILE%\TrimClip\Trim Clip.ps1`

It does **not** delete `ffmpeg.exe`.

## Requirements

- Windows
- PowerShell
- A static Windows build of FFmpeg (`ffmpeg.exe`)
