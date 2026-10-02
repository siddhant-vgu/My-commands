# ============================================================
# TREECREATE FINAL
# Supports:
#   1. 4-space indentation tree
#   2. Unicode tree: ├── │ └──
# ============================================================
function Test-IsFileName {
    param(
        [string]$Name
    )
    # Files with extensions
    if ([System.IO.Path]::GetExtension($Name)) {
        return $true
    }
    # Common extensionless files
    extensionlessFiles = @(
        'Dockerfile',
        'LICENSE',
        'Makefile',
        'Procfile',
        'README',
        '.env',
        '.gitignore',
        '.dockerignore'
    )
    return $extensionlessFiles -contains $Name
}

# ============================================================
# PARSE 4-SPACE FORMAT
# ============================================================
function Parse-IndentLine {
    param(
        [string]$Line
    )
    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $null
    }
    $Line = $Line.TrimEnd()
    $leadingSpaces = 0
    foreach ($char in $Line.ToCharArray()) {
        if ($char -eq ' ') {
            $leadingSpaces++
        }
        else {
            break
        }
    }
    # 4 spaces = 1 level
    $depth = [math]::Floor($leadingSpaces / 4)
    $name = $Line.Trim()
    return @{
        Depth = $depth
        Name  = $name
    }
}

# ============================================================
# PARSE UNICODE FORMAT
# ============================================================
function Parse-UnicodeLine {
    param(
        [string]$Line
    )
    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $null
    }
    $Line = $Line.TrimEnd()
    # Unicode characters using character codes.
    # This prevents PowerShell encoding/mojibake problems.
    $branch = [char]0x251C       # ├
    $last   = [char]0x2514       # └
    $dash   = [char]0x2500       # ─
    $connector1 = "$branch$dash$dash"
    $connector2 = "$last$dash$dash"
    $index = $Line.IndexOf($connector1)
    if ($index -lt 0) {
        $index = $Line.IndexOf($connector2)
    }
    # Root
    if ($index -lt 0) {
        return @{
            Depth = 0
            Name  = $Line.Trim()
        }
    }
    # Prefix before ├── / └──
    $prefix = $Line.Substring(0, $index)
    # Every 4 characters = one level
    $depth = [math]::Floor($prefix.Length / 4) + 1
    # Remove ├── / └──
    $name = $Line.Substring($index + 3).Trim()
    return @{
        Depth = $depth
        Name  = $name
    }
}

# ============================================================
# FORMAT DETECTION
# ============================================================
function Get-TreeFormat {
    param(
        [string[]]$Lines
    )
    $branch = [char]0x251C
    $last   = [char]0x2514
    $dash   = [char]0x2500
    $unicode1 = "$branch$dash$dash"
    $unicode2 = "$last$dash$dash"
    foreach ($line in $Lines) {
        if ($line.Contains($unicode1) -or
            $line.Contains($unicode2)) {
            return "Unicode"
        }
    }
    return "Indentation"
}

# ============================================================
# MAIN COMMAND
# ============================================================
function treecreate-final {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$TreeFile,
        [switch]$WhatIf
    )

    # --------------------------------------------------------
    # Check input file
    # --------------------------------------------------------
    if (-not (Test-Path -LiteralPath $TreeFile)) {
        Write-Error "Tree file not found: $TreeFile"
        return
    }

    # --------------------------------------------------------
    # Read file
    # --------------------------------------------------------
    $lines = Get-Content -LiteralPath $TreeFile -Encoding UTF8

    # --------------------------------------------------------
    # Detect format
    # --------------------------------------------------------
    $format = Get-TreeFormat $lines
    Write-Host ""
    Write-Host "Format detected : $format"
    Write-Host ""

    # --------------------------------------------------------
    # Counters
    # --------------------------------------------------------
    $foldersCreated = 0
    $filesCreated = 0
    $foldersExisting = 0
    $filesExisting = 0

    # --------------------------------------------------------
    # Parent stack
    # --------------------------------------------------------
    $stack = @()

    # ========================================================
    # PROCESS EVERY LINE
    # ========================================================
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # ----------------------------------------------------
        # Parse according to detected format
        # ----------------------------------------------------
        if ($format -eq "Unicode") {
            $node = Parse-UnicodeLine $line

        }
        else {

            $node = Parse-IndentLine $line
        }
        if ($null -eq $node) {
            continue
        }
        $depth = $node.Depth
        $name  = $node.Name

        # ----------------------------------------------------
        # Remove deeper parents
        # ----------------------------------------------------
        while ($stack.Count -gt $depth) {
            if ($stack.Count -eq 1) {
                $stack = @()
            }
            else {
                $stack = @(
                    $stack[0..($stack.Count - 2)]
                )
            }
        }

        # ----------------------------------------------------
        # Build full path
        # ----------------------------------------------------
        if ($depth -eq 0) {
            $fullPath = Join-Path `
                (Get-Location) `
                $name
        }
        else {
            if ($stack.Count -gt 0) {
                $parent = $stack[$stack.Count - 1]
                $fullPath = Join-Path `
                    $parent `
                    $name
            }
            else {
                $fullPath = Join-Path `
                    (Get-Location) `
                    $name
            }
        }

        # ----------------------------------------------------
        # Determine FILE or FOLDER
        # ---------------------------------------------------
        $isFile = Test-IsFileName $name

        # ====================================================
        # FILE
        # ====================================================
        if ($isFile) {
            if (Test-Path `
                -LiteralPath $fullPath `
                -PathType Leaf) {
                Write-Host "[EXISTS FILE]        $fullPath"
                $filesExisting++
            }
            elseif (Test-Path -LiteralPath $fullPath) {
                Write-Host "[CONFLICT]           $fullPath"
            }
            elseif ($WhatIf) {
                Write-Host "[WOULD CREATE FILE]  $fullPath"
                $filesCreated++
            }
            else {
                New-Item `
                    -ItemType File `
                    -Path $fullPath `
                    -Force |
                    Out-Null
                Write-Host "[FILE]               $fullPath"
                $filesCreated++
            }
        }

        # ====================================================
        # FOLDER
        # ====================================================
        else {
            if (Test-Path `
                -LiteralPath $fullPath `
                -PathType Container) {
                Write-Host "[EXISTS FOLDER]      $fullPath"
                $foldersExisting++
            }
            elseif (Test-Path -LiteralPath $fullPath) {
                Write-Host "[CONFLICT]           $fullPath"
            }
            elseif ($WhatIf) {
                Write-Host "[WOULD CREATE FOLDER] $fullPath"
                $foldersCreated++
            }
            else {
                New-Item `
                    -ItemType Directory `
                    -Path $fullPath `
                    -Force |
                    Out-Null
                Write-Host "[FOLDER]             $fullPath"
                $foldersCreated++
            }

            # ------------------------------------------------
            # Add folder to stack
            # -----------------------------------------------
            if ($stack.Count -eq $depth) {
                $stack += $fullPath
            }
            elseif ($stack.Count -gt $depth) {
                $stack[$depth] = $fullPath
            }
            else {
                $stack += $fullPath
            }
        }
    }

    # ========================================================
    # SUMMARY
    # ========================================================
    Write-Host ""
    Write-Host "========================================"
    Write-Host " treecreate FINAL"
    Write-Host "========================================"
    Write-Host "Format           : $format"
    Write-Host "Folders created  : $foldersCreated"
    Write-Host "Files created    : $filesCreated"
    Write-Host "Folders existing : $foldersExisting"
    Write-Host "Files existing   : $filesExisting"
    if ($WhatIf) {
        Write-Host ""
        Write-Host "DRY RUN - No files or folders were created."
    }
    Write-Host "========================================"
}

# ============================================================
# ALIAS
# ============================================================
Set-Alias `
    -Name tc-final `
    -Value treecreate-final `
    -Force