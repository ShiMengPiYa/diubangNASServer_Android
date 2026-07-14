#Requires -Version 5.1
<#
.SYNOPSIS
  Pre-download media_kit libmpv Android JARs with MD5 verification and retries.

.DESCRIPTION
  Mirrors the Windows server bootstrap flow (tool/bootstrap_windows.ps1):
  download native deps before flutter build, verify integrity, retry on failure.

  NAS Client Android uses ExoPlayer from Maven and does not need this step.
  This script is for NASServer Android (media_kit / libmpv).

.EXAMPLE
  .\tool\bootstrap_media_kit_android.ps1
.EXAMPLE
  .\tool\bootstrap_media_kit_android.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [int]$MaxAttempts = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Get-FileMd5Hex([string]$Path) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            return ([System.BitConverter]::ToString($md5.ComputeHash($stream)) -replace '-', '').ToLowerInvariant()
        } finally {
            $stream.Dispose()
        }
    } finally {
        $md5.Dispose()
    }
}

function Test-JarValid([string]$Path, [string]$ExpectedMd5) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if ((Get-Item -LiteralPath $Path).Length -lt 1024) { return $false }
    return (Get-FileMd5Hex -Path $Path) -eq $ExpectedMd5.ToLowerInvariant()
}

function Get-MirrorPrefix {
    $gradleProps = Join-Path (Get-RepoRoot) 'android\gradle.properties'
    if (-not (Test-Path -LiteralPath $gradleProps)) {
        return 'https://ghfast.top/'
    }
    foreach ($line in Get-Content -LiteralPath $gradleProps) {
        if ($line -match '^\s*githubMirrorPrefix\s*=\s*(.+)\s*$') {
            return $Matches[1].Trim()
        }
    }
    return 'https://ghfast.top/'
}

function Get-CandidateUrls([string]$BaseUrl) {
    $mirror = Get-MirrorPrefix
    $urls = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($mirror)) {
        $prefix = if ($mirror.EndsWith('/')) { $mirror } else { "$mirror/" }
        $urls.Add("$prefix$BaseUrl")
    }
    $urls.Add("https://ghproxy.net/$BaseUrl")
    $urls.Add("https://mirror.ghproxy.com/$BaseUrl")
    $urls.Add($BaseUrl)
    return $urls | Select-Object -Unique
}

$files = @(
    @{ Name = 'default-arm64-v8a.jar'; Md5 = '83df25b61193af8fa815e373143ac9af' },
    @{ Name = 'default-armeabi-v7a.jar'; Md5 = '22e21526fefc0a2b8f17adbec9f57590' },
    @{ Name = 'default-x86_64.jar'; Md5 = '6fa26bf0459b11f1c0b0dbc29e5b940d' },
    @{ Name = 'default-x86.jar'; Md5 = '0d742b756dc9d1fcd84ea271d8b68f32' }
)

$repoRoot = Get-RepoRoot
$destDir = Join-Path $repoRoot 'build\media_kit_libs_android_video\v1.1.7'
New-Item -ItemType Directory -Force -Path $destDir | Out-Null

Write-Host "Preparing media_kit libmpv JARs in: $destDir"
$failures = @()

foreach ($file in $files) {
    $baseUrl = "https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.7/$($file.Name)"
    $dest = Join-Path $destDir $file.Name

    if ((Test-Path -LiteralPath $dest) -and -not $Force) {
        if (Test-JarValid -Path $dest -ExpectedMd5 $file.Md5) {
            $sizeMb = [math]::Round((Get-Item -LiteralPath $dest).Length / 1MB, 1)
            Write-Host "$($file.Name): already present (${sizeMb} MB, MD5 OK)."
            continue
        }
        Write-Warning "$($file.Name): invalid cache, re-downloading."
        Remove-Item -LiteralPath $dest -Force
    }

    if ($Force -and (Test-Path -LiteralPath $dest)) {
        Remove-Item -LiteralPath $dest -Force
    }

    $urls = Get-CandidateUrls -BaseUrl $baseUrl
    $downloaded = $false
    $lastError = 'No URLs attempted.'

    foreach ($url in $urls) {
        for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
            try {
                Write-Host "$($file.Name): downloading attempt $attempt/$MaxAttempts"
                Write-Host "  URL: $url"
                Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 600
                if (-not (Test-JarValid -Path $dest -ExpectedMd5 $file.Md5)) {
                    $size = if (Test-Path -LiteralPath $dest) { (Get-Item -LiteralPath $dest).Length } else { 0 }
                    throw "Verification failed (size=$size bytes)."
                }
                $sizeMb = [math]::Round((Get-Item -LiteralPath $dest).Length / 1MB, 1)
                Write-Host "$($file.Name): verified (${sizeMb} MB)."
                $downloaded = $true
                break
            } catch {
                $lastError = $_.Exception.Message
                if (Test-Path -LiteralPath $dest) {
                    Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
                }
                if ($attempt -lt $MaxAttempts) {
                    Start-Sleep -Seconds ([math]::Pow(2, $attempt))
                }
            }
        }
        if ($downloaded) { break }
    }

    if (-not $downloaded) {
        $failures += [pscustomobject]@{
            Name = $file.Name
            Error = $lastError
            BaseUrl = $baseUrl
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host 'Bootstrap FAILED:'
    foreach ($failure in $failures) {
        Write-Host "  [$($failure.Name)] $($failure.Error)"
        Write-Host "    $($failure.BaseUrl)"
    }
    Write-Host ''
    Write-Host 'Try: .\tool\bootstrap_media_kit_android.ps1 -Force'
    Write-Host 'Or adjust android/gradle.properties githubMirrorPrefix and retry.'
    exit 1
}

Write-Host 'media_kit Android JARs ready.'
