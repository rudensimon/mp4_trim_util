param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputFile
)

$host.UI.RawUI.WindowTitle = "Trim Clip v7.4"
$Invariant = [System.Globalization.CultureInfo]::InvariantCulture

function Show-Banner {
    Clear-Host
    Write-Host @'
 _______ ____  ___ __  __     ____ _     ___ ____
|__   __|  _ \|_ _|  \/  |   / ___| |   |_ _|  _ \
   | |  | |_) || || |\/| |  | |   | |    | || |_) |
   | |  |  _ < | || |  | |  | |___| |___ | ||  __/
   |_|  |_| \_\___|_|  |_|   \____|_____|___|_|

                        v7.4
'@
}

function Stop-WithError([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message"
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}

function Format-Seconds([double]$Value) {
    return $Value.ToString("0.###", $Invariant)
}

function Format-FileSeconds([double]$Value) {
    return (Format-Seconds $Value).Replace(".", "_")
}

function Quote-Argument([string]$Value) {
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Get-MediaDuration([string]$FfmpegPath, [string]$FilePath) {
    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $FfmpegPath
        $startInfo.Arguments = '-hide_banner -i ' + (Quote-Argument $FilePath)
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        [void]$process.Start()

        $probeText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        $match = [regex]::Match(
            $probeText,
            'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)'
        )

        if (-not $match.Success) {
            return $null
        }

        $hours = [double]$match.Groups[1].Value
        $minutes = [double]$match.Groups[2].Value
        $seconds = [double]::Parse($match.Groups[3].Value, $Invariant)

        return ($hours * 3600) + ($minutes * 60) + $seconds
    }
    catch {
        return $null
    }
}

function Convert-TimecodeToSeconds([string]$Timecode) {
    $match = [regex]::Match($Timecode, '^(\d+):(\d+):(\d+(?:\.\d+)?)$')

    if (-not $match.Success) {
        return 0.0
    }

    $hours = [double]$match.Groups[1].Value
    $minutes = [double]$match.Groups[2].Value
    $seconds = [double]::Parse($match.Groups[3].Value, $Invariant)

    return ($hours * 3600) + ($minutes * 60) + $seconds
}

function Show-ProgressBar([double]$Percent) {
    $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))

    $width = 32
    $filled = [int][Math]::Floor(($Percent / 100) * $width)
    $bar = ("#" * $filled) + ("-" * ($width - $filled))

    [Console]::Write(
        ("`r[{0}] {1,3}%" -f $bar, [int][Math]::Round($Percent))
    )
}

function Invoke-FfmpegTrim(
    [string]$FfmpegPath,
    [string[]]$Arguments,
    [double]$ExpectedDuration
) {
    $progressArgs = @(
        "-hide_banner",
        "-loglevel", "error",
        "-nostats",
        "-progress", "pipe:1"
    ) + $Arguments

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FfmpegPath
    $startInfo.Arguments = (($progressArgs | ForEach-Object {
        Quote-Argument $_
    }) -join " ")
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    try {
        [void]$process.Start()
    }
    catch {
        return 1
    }

    Show-ProgressBar 0

    while (-not $process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()

        if ($line.StartsWith("out_time=")) {
            $current = Convert-TimecodeToSeconds $line.Substring(9)

            if ($ExpectedDuration -gt 0) {
                Show-ProgressBar (($current / $ExpectedDuration) * 100)
            }
        }
        elseif ($line -eq "progress=end") {
            Show-ProgressBar 100
        }
    }

    $process.WaitForExit()
    Show-ProgressBar 100
    [Console]::WriteLine()

    return $process.ExitCode
}

Show-Banner

if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) {
    Stop-WithError "The selected file could not be found."
}

if ([IO.Path]::GetExtension($InputFile) -ine ".mp4") {
    Stop-WithError "Trim Clip currently supports MP4 files only."
}

$InputFile = (Resolve-Path -LiteralPath $InputFile).Path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localFfmpeg = Join-Path $scriptDir "ffmpeg.exe"

if (Test-Path -LiteralPath $localFfmpeg) {
    $ffmpeg = $localFfmpeg
}
else {
    $ffmpegCommand = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue

    if (-not $ffmpegCommand) {
        Stop-WithError "FFmpeg was not found. Put ffmpeg.exe in:`n$scriptDir`n`nor add FFmpeg to Windows PATH."
    }

    $ffmpeg = $ffmpegCommand.Source
}

$duration = Get-MediaDuration $ffmpeg $InputFile

if ($null -eq $duration -or $duration -le 0) {
    Stop-WithError "Could not determine the clip duration."
}

$fileName = [IO.Path]::GetFileName($InputFile)
$directory = [IO.Path]::GetDirectoryName($InputFile)
$stem = [IO.Path]::GetFileNameWithoutExtension($InputFile)

Write-Host $fileName
Write-Host ""
Write-Host "Enter = keep last 30s   |   45 = keep last 45s"
Write-Host "30s = trim start        |   30e = trim end"
Write-Host "30s30e = trim both"
Write-Host ""

$spec = (Read-Host "Trim [30]").Trim().ToLowerInvariant()

if ([string]::IsNullOrWhiteSpace($spec)) {
    $spec = "30"
}

$ffmpegArgs = @("-y")
$expectedDuration = 0.0
$output = $null

# A bare number keeps the last N seconds.
$bareNumber = [regex]::Match($spec, '^\d+(?:\.\d+)?$')

if ($bareNumber.Success) {
    $keep = [double]::Parse($spec, $Invariant)

    if ($keep -le 0) {
        Stop-WithError "The number must be greater than 0."
    }

    $expectedDuration = [Math]::Min($keep, $duration)
    $startAt = [Math]::Max(0, $duration - $expectedDuration)

    $safeKeep = Format-FileSeconds $keep
    $output = Join-Path $directory ($stem + "_trimmed_" + $safeKeep + ".mp4")

    # Use the same duration-based seek style as the flag modes.
    # This avoids a separate -sseof code path for the default command.
    if ($startAt -gt 0) {
        $ffmpegArgs += @("-ss", (Format-Seconds $startAt))
    }

    $ffmpegArgs += @(
        "-i", $InputFile,
        "-t", (Format-Seconds $expectedDuration)
    )
}
else {
    # Flags remove time from a side:
    # 30s = trim 30 seconds from start
    # 30e = trim 30 seconds from end
    # 30s30e = trim both
    $matches = [regex]::Matches(
        $spec,
        '(?<n>\d+(?:\.\d+)?)\s*-?\s*(?<f>[se])'
    )

    if ($matches.Count -eq 0) {
        Stop-WithError "Invalid command. Try: 30, 30s, 30e, or 30s30e."
    }

    $leftover = [regex]::Replace(
        $spec,
        '\d+(?:\.\d+)?\s*-?\s*[se]',
        ''
    ) -replace '\s+', ''

    if ($leftover.Length -gt 0) {
        Stop-WithError "Invalid command. Try: 30, 30s, 30e, or 30s30e."
    }

    $trimStart = 0.0
    $trimEnd = 0.0
    $hasStart = $false
    $hasEnd = $false

    foreach ($match in $matches) {
        $value = [double]::Parse($match.Groups["n"].Value, $Invariant)
        $flag = $match.Groups["f"].Value

        if ($flag -eq "s") {
            if ($hasStart) {
                Stop-WithError "The start flag was specified more than once."
            }

            $trimStart = $value
            $hasStart = $true
        }
        else {
            if ($hasEnd) {
                Stop-WithError "The end flag was specified more than once."
            }

            $trimEnd = $value
            $hasEnd = $true
        }
    }

    if (($trimStart + $trimEnd) -le 0) {
        Stop-WithError "Nothing to trim."
    }

    if (($trimStart + $trimEnd) -ge $duration) {
        Stop-WithError "The requested trims would remove the entire clip."
    }

    $expectedDuration = $duration - $trimStart - $trimEnd

    if ($hasStart -and $hasEnd) {
        $suffix = "_trimmed_" +
            (Format-FileSeconds $trimStart) + "s" +
            (Format-FileSeconds $trimEnd) + "e.mp4"
    }
    elseif ($hasStart) {
        $suffix = "_trimmed_" + (Format-FileSeconds $trimStart) + "s.mp4"
    }
    else {
        $suffix = "_trimmed_" + (Format-FileSeconds $trimEnd) + "e.mp4"
    }

    $output = Join-Path $directory ($stem + $suffix)

    if ($trimStart -gt 0) {
        $ffmpegArgs += @("-ss", (Format-Seconds $trimStart))
    }

    $ffmpegArgs += @("-i", $InputFile)

    if ($hasEnd) {
        $ffmpegArgs += @("-t", (Format-Seconds $expectedDuration))
    }
}

$ffmpegArgs += @(
    "-map", "0:v?",
    "-map", "0:a?",
    "-map_metadata", "0",
    "-c", "copy",
    "-avoid_negative_ts", "make_zero",
    $output
)

Write-Host ""
Write-Host "Trimming..."

$exitCode = Invoke-FfmpegTrim $ffmpeg $ffmpegArgs $expectedDuration

if ($exitCode -ne 0 -or -not (Test-Path -LiteralPath $output)) {
    Stop-WithError "Trim failed. The original file was not changed."
}

Write-Host ""
Write-Host "Done!  $([IO.Path]::GetFileName($output))"
Write-Host ""
Write-Host "Original kept."
