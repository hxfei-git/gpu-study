[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Errors = [System.Collections.Generic.List[string]]::new()
$SourceLineCache = @{}

function ConvertTo-HeadingSlug {
    param([Parameter(Mandatory)][string]$Heading)

    $Slug = $Heading.Trim().ToLowerInvariant()
    $Slug = [regex]::Replace($Slug, '<[^>]+>', '')
    $Slug = [regex]::Replace(
        $Slug,
        '[\p{P}\p{S}]',
        { param($Match) if ($Match.Value -in @('-', '_')) { $Match.Value } else { '' } }
    )
    return [regex]::Replace($Slug, '\s+', '-')
}

$Docs = @(
    Get-ChildItem -LiteralPath (Join-Path $RepoRoot '1.笔记') -Filter '*.md' -File
    Get-ChildItem -LiteralPath $RepoRoot -Filter '*.md' -File |
        Where-Object Name -ne 'AGENTS.md'
    Get-Item -LiteralPath (Join-Path $RepoRoot '2.源码\README.md')
)

$HeadingMap = @{}
foreach ($Doc in $Docs) {
    $Slugs = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $Seen = @{}

    foreach ($Line in Get-Content -LiteralPath $Doc.FullName) {
        if ($Line -notmatch '^#{1,6}\s+(?<heading>.+?)\s*#*\s*$') {
            continue
        }

        $Base = ConvertTo-HeadingSlug $Matches['heading']
        if (-not $Seen.ContainsKey($Base)) {
            $Seen[$Base] = 0
            [void]$Slugs.Add($Base)
        } else {
            $Seen[$Base]++
            [void]$Slugs.Add("$Base-$($Seen[$Base])")
        }
    }
    $HeadingMap[$Doc.FullName] = $Slugs
}

$LocalLinkCount = 0
$SourcePathCount = 0
$SourceLineRefCount = 0

foreach ($Doc in $Docs) {
    $Lines = @(Get-Content -LiteralPath $Doc.FullName)

    for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
        $LineNumber = $Index + 1
        $Line = $Lines[$Index]

        foreach ($Match in [regex]::Matches(
            $Line,
            '\]\((?<angle><)?(?<target>[^)>]+)(?(angle)>)\)'
        )) {
            $Target = $Match.Groups['target'].Value.Trim()
            if ($Target -match '^(?:https?://|mailto:|thread:|app:)') {
                continue
            }

            $Parts = $Target -split '#', 2
            $PathPart = [uri]::UnescapeDataString($Parts[0])
            $Anchor = if ($Parts.Count -eq 2) {
                [uri]::UnescapeDataString($Parts[1]).ToLowerInvariant()
            } else {
                ''
            }

            if ([string]::IsNullOrWhiteSpace($PathPart)) {
                $TargetPath = $Doc.FullName
            } else {
                $TargetPath = [System.IO.Path]::GetFullPath(
                    (Join-Path $Doc.DirectoryName $PathPart)
                )
                $LocalLinkCount++
                if (-not (Test-Path -LiteralPath $TargetPath)) {
                    $Errors.Add(
                        "$($Doc.FullName):$LineNumber local link target is missing: $Target"
                    )
                    continue
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($Anchor) -and
                $HeadingMap.ContainsKey($TargetPath) -and
                -not $HeadingMap[$TargetPath].Contains($Anchor)) {
                $Errors.Add(
                    "$($Doc.FullName):$LineNumber heading anchor is missing: $Target"
                )
            }
        }

        foreach ($Match in [regex]::Matches(
            $Line,
            '(?:\.\./)?(?<path>2\.源码/[A-Za-z0-9_.+/-]+)'
        )) {
            $RelativePath = $Match.Groups['path'].Value.TrimEnd('.', '/', '-')
            $SourcePath = Join-Path $RepoRoot (
                $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
            )
            $SourcePathCount++
            if (-not (Test-Path -LiteralPath $SourcePath)) {
                $Errors.Add(
                    "$($Doc.FullName):$LineNumber source path is missing: $RelativePath"
                )
            }
        }

        $LastReferencedSource = $null
        $LineReferencePattern =
            '(?<path>2\.源码/[A-Za-z0-9_.+/-]+):' +
            '(?<lines>\d+(?:-\d+)?(?:\s*[,、/]\s*\d+(?:-\d+)?)*)' +
            '|同文件\s*`?\s*:?\s*(?<sameLines>\d+(?:-\d+)?)'

        foreach ($Match in [regex]::Matches($Line, $LineReferencePattern)) {
            if ($Match.Groups['path'].Success) {
                $LastReferencedSource = $Match.Groups['path'].Value
                $LineSpecs = $Match.Groups['lines'].Value
            } else {
                if ($null -eq $LastReferencedSource) {
                    continue
                }
                $LineSpecs = $Match.Groups['sameLines'].Value
            }

            $RelativePath = $LastReferencedSource
            $SourcePath = Join-Path $RepoRoot (
                $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
            )
            if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
                continue
            }

            if (-not $SourceLineCache.ContainsKey($SourcePath)) {
                $SourceLineCache[$SourcePath] = @(Get-Content -LiteralPath $SourcePath).Count
            }

            foreach ($LineSpec in ($LineSpecs -split '\s*[,、/]\s*')) {
                $RangeBounds = $LineSpec -split '-', 2
                $ReferencedLine = [int]$RangeBounds[-1]
                $SourceLineRefCount++
                if ($ReferencedLine -gt $SourceLineCache[$SourcePath]) {
                    $Errors.Add(
                        "$($Doc.FullName):$LineNumber source line is out of range: " +
                        "$RelativePath`:$LineSpec (file has $($SourceLineCache[$SourcePath]) lines)"
                    )
                }
            }
        }
    }
}

$ExpectedCommits = [ordered]@{
    'linux' = '248951ddc14de84de3910f9b13f51491a8cd91df'
    'rocm-clr' = '81277d69e3352e7144ced2ee9601484f9b48d950'
    'rocr-runtime' = 'ba56a24c6132c5d195686ae4adf969ca1222fbba'
    'rocm-device-libs' = '1915fc612c243bdbc656608ecba3fa9618d6afc3'
    'pal' = '9fab16015e522fff05890a045a1e9d8d3c23a636'
    'pocl' = '42fad325efaee07915307ab802f1527171b434d0'
    'vortex' = 'd76b7f24e658867ab57e3942d7c648c3e6af072d'
}

foreach ($Entry in $ExpectedCommits.GetEnumerator()) {
    $SourceRepo = Join-Path $RepoRoot "2.源码\$($Entry.Key)"
    $Head = [string](& git -C $SourceRepo rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0) {
        $Errors.Add("cannot read Git HEAD for 2.源码/$($Entry.Key)")
        continue
    }
    if ($Head.Trim() -ne $Entry.Value) {
        $Errors.Add(
            "2.源码/$($Entry.Key) HEAD mismatch: expected $($Entry.Value), got $($Head.Trim())"
        )
    }
}

$ClrRepo = Join-Path $RepoRoot '2.源码\rocm-clr'
& git -C $ClrRepo cat-file -e 'refs/notes-baselines/clr-historical^{commit}' 2>$null
if ($LASTEXITCODE -ne 0) {
    $Errors.Add('missing CLR historical commit ref: refs/notes-baselines/clr-historical')
}
& git -C $ClrRepo cat-file -e (
    'refs/notes-baselines/clr-historical:' +
    'rocclr/runtime/device/pal/palvirtual.cpp'
) 2>$null
if ($LASTEXITCODE -ne 0) {
    $Errors.Add('missing palvirtual.cpp in the saved CLR historical object')
}

if ($Errors.Count -gt 0) {
    Write-Host "FAILED: $($Errors.Count) dependency problem(s)"
    $Errors | ForEach-Object { Write-Host "- $_" }
    exit 1
}

Write-Host 'PASS: documentation is self-contained against the checked local baseline.'
Write-Host "Documents: $($Docs.Count)"
Write-Host "Local link targets checked: $LocalLinkCount"
Write-Host "Local source path occurrences checked: $SourcePathCount"
Write-Host "Source line references checked: $SourceLineRefCount"
Write-Host "Pinned source repositories checked: $($ExpectedCommits.Count)"
