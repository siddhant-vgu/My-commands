# treecreate

> A PowerShell utility that converts a text-based project tree into a
> real folder and file structure.

`treecreate` lets you create complete project structures from a simple
tree description. It supports both Unicode tree diagrams and 4-space
indentation, with multiple input modes including clipboard, interactive
Notepad editing, and existing tree files.

------------------------------------------------------------------------

## ✨ Features

-   🌳 Create folders and files from a tree structure
-   🔀 Supports **Unicode tree format**
-   ↔️ Supports **4-space indentation format**
-   📋 Create structures directly from the **clipboard**
-   📝 Interactive editor mode: `tc project.txt`
-   🔍 Dry-run mode with `-WhatIf`
-   📁 Automatically resolves nested parent-child relationships
-   📄 Detects common files by extension
-   🧩 Supports extensionless files such as `Dockerfile`, `LICENSE`,
    `Makefile`, `README`, `.env`, `.gitignore`, and `.dockerignore`
-   ♻️ Detects existing files and folders instead of blindly recreating
    them
-   ⚡ Short alias: `tc`
-   🪟 Designed for Windows PowerShell

------------------------------------------------------------------------

## 🎯 Why treecreate?

When starting a project, creating dozens of folders and empty files
manually is repetitive.

For example, instead of manually creating:

``` text
MY_APP/
├── src/
│   ├── main.py
│   └── utils.py
├── config/
│   └── settings.json
├── data/
│   └── input.csv
└── README.md
```

you can give the structure to `treecreate` and let it build the
filesystem automatically.

------------------------------------------------------------------------

## 🧠 How It Works

``` text
┌──────────────────────────────────────────────────────────────┐
│                         USER INPUT                           │
│                                                              │
│   📋 Clipboard       📝 Text File       ⌨️ Interactive Mode│
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                     FORMAT DETECTION                         │
│                                                              │
│        ┌──────────────────┐     ┌──────────────────┐         │
│        │  🌳 Unicode Tree│      │  📐 Indentation │         │
│        │  ├── ,└──,  │    │     │  4 Spaces / Level│         │
│        └────────┬─────────┘     └────────┬─────────┘         │
└─────────────────┼────────────────────────┼───────────────────┘
                  └────────────┬───────────┘
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                         PARSING                              │
│                                                              │
│     Line → Depth → Node Name → Parent → Full Path            │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    NODE CLASSIFICATION                       │
│                                                              │
│              📁 Folder              📄 File                 │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    FILESYSTEM CREATION                       │
│                                                              │
│                       New-Item                               │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                         OUTPUT                               │
│                                                              │
│                     📁 Project                               │
│                     ├── 📁 Folders                           │
│                     └── 📄 Files                             │
└──────────────────────────────────────────────────────────────┘
```

The parser uses a stack-based approach to determine the parent of every
node.

------------------------------------------------------------------------

## 📂 Project Structure

``` text
treecreate_project/
│
├── treecreate_project.ps1
├── README.md
├── project-tree.txt
├── test-tree.txt
└── test-indent.txt
```

### Main file

`treecreate_project.ps1`

Contains the core implementation:

-   File detection
-   Unicode parser
-   Indentation parser
-   Format detection
-   Parent stack handling
-   Filesystem creation
-   Dry-run support

------------------------------------------------------------------------

# 🚀 Installation

## 1. Clone or copy the project

Place the project somewhere permanent, for example:

``` text
E:\VGU\5th sem\My-commands\treecreate_project
```

## 2. Add the script to your PowerShell profile

Open the profile:

``` powershell
notepad $PROFILE
```

Add:

``` powershell
. "E:\VGU\5th sem\My-commands\treecreate_project\treecreate_project.ps1"

function treecreate {
    param(
        [Parameter(Position=0)]
        [string]$TreeFile,

        [switch]$WhatIf
    )

    if ([string]::IsNullOrWhiteSpace($TreeFile)) {

        $text = Get-Clipboard -Raw

        if ([string]::IsNullOrWhiteSpace($text)) {
            Write-Host "Clipboard khaali hai. Pehle tree structure copy karo." -ForegroundColor Red
            return
        }

        $tempFile = Join-Path $env:TEMP "treecreate_clipboard.txt"
        $text | Set-Content $tempFile -Encoding UTF8

        treecreate-final $tempFile -WhatIf:$WhatIf

        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

        return
    }

    $fullPath = [System.IO.Path]::GetFullPath(
        (Join-Path (Get-Location) $TreeFile)
    )

    if (-not (Test-Path $fullPath)) {
        Write-Host ""
        Write-Host "Tree file does not exist." -ForegroundColor Yellow
        Write-Host "Creating: $fullPath" -ForegroundColor Cyan

        New-Item -ItemType File -Path $fullPath -Force | Out-Null
    }

    Write-Host ""
    Write-Host "Opening tree file..." -ForegroundColor Cyan
    Write-Host "Paste your project structure, save it, then close Notepad." -ForegroundColor Yellow
    Write-Host ""

    Start-Process notepad.exe -ArgumentList "`"$fullPath`"" -Wait

    $content = Get-Content $fullPath -Raw

    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Host ""
        Write-Host "Tree file khaali hai. Kuch bhi create nahi kiya gaya." -ForegroundColor Red
        return
    }

    treecreate-final $fullPath -WhatIf:$WhatIf
}

Set-Alias -Name tc -Value treecreate -Force
```

Reload the profile:

``` powershell
. $PROFILE
```

Verify:

``` powershell
Get-Command treecreate
Get-Alias tc
Get-Command treecreate-final
```

------------------------------------------------------------------------

# 🛠️ Usage

## Mode 1 --- Clipboard Mode

Copy a tree structure:

``` text
MY_APP/
├── src/
│   ├── main.py
│   └── utils.py
├── config/
│   └── settings.json
├── data/
│   └── input.csv
└── README.md
```

Then navigate to the folder where you want the project:

``` powershell
cd "C:\Projects"
```

Run:

``` powershell
tc
```

The tree is read directly from the clipboard.

### Dry run

``` powershell
tc -WhatIf
```

No files or folders are created.

------------------------------------------------------------------------

# 📝 Mode 2 --- Interactive Editor Mode

You can create a tree file on demand:

``` powershell
tc project.txt
```

If `project.txt` does not exist:

1.  `treecreate` creates it.
2.  Notepad opens automatically.
3.  Paste your tree structure.
4.  Save the file.
5.  Close Notepad.
6.  `treecreate` parses the saved structure.

Example:

``` text
MY_APP/
├── src/
│   ├── main.py
│   └── utils.py
├── config/
│   └── settings.json
└── README.md
```

Then the filesystem is generated automatically.

### Editor + Dry Run

``` powershell
tc project.txt -WhatIf
```

------------------------------------------------------------------------

# 📄 Mode 3 --- Existing Tree File

If you already have a tree file:

``` powershell
tc project-tree.txt
```

No need to manually create folders or files.

------------------------------------------------------------------------

# 🌳 Supported Formats

## Unicode Tree

``` text
MY_APP/
├── src/
│   ├── main.py
│   └── utils.py
├── data/
│   └── input.csv
└── README.md
```

## 4-Space Indentation

``` text
MY_APP/
    src/
        main.py
        utils.py
    data/
        input.csv
    README.md
```

The tool automatically detects which format is being used.

------------------------------------------------------------------------

# 🔍 Dry Run

Before creating anything, use:

``` powershell
tc project.txt -WhatIf
```

Example output:

``` text
Format detected : Unicode

[WOULD CREATE FOLDER] ...\MY_APP\
[WOULD CREATE FOLDER] ...\MY_APP\src\
[WOULD CREATE FILE]   ...\MY_APP\src\main.py
[WOULD CREATE FILE]   ...\MY_APP\src\utils.py

========================================
 treecreate FINAL
========================================
Format           : Unicode
Folders created  : 3
Files created    : 4
Folders existing : 0
Files existing   : 0

DRY RUN - No files or folders were created.
========================================
```

`-WhatIf` is recommended when testing an unfamiliar tree.

------------------------------------------------------------------------

# 📁 File Detection

`treecreate` determines whether a node is a file or directory.

Examples of detected files:

``` text
main.py
config.json
data.csv
index.html
style.css
app.js
requirements.txt
README.md
```

It also recognizes common extensionless files:

``` text
Dockerfile
LICENSE
Makefile
Procfile
README
.env
.gitignore
.dockerignore
```

------------------------------------------------------------------------

# ♻️ Existing Files and Folders

Running the same command again does not blindly recreate everything.

The summary distinguishes between:

``` text
Folders created
Files created
Folders existing
Files existing
```

This makes repeated execution safer and easier to understand.

------------------------------------------------------------------------

# 🧪 Example

Input:

``` text
MY_APP/
├── src/
│   ├── main.py
│   └── utils.py
├── config/
│   └── settings.json
├── data/
│   └── input.csv
└── README.md
```

Command:

``` powershell
tc project.txt
```

Result:

``` text
MY_APP/
│   README.md
│
├── config/
│   └── settings.json
│
├── data/
│   └── input.csv
│
└── src/
    ├── main.py
    └── utils.py
```

------------------------------------------------------------------------

# 🧩 Architecture

``` text
treecreate
│
├── treecreate wrapper
│   ├── Clipboard mode
│   └── Editor mode
│
└── treecreate-final
    │
    ├── Get-TreeFormat
    │
    ├── Parse-UnicodeLine
    │
    ├── Parse-IndentLine
    │
    ├── Test-IsFileName
    │
    ├── Parent Stack
    │
    ├── Path Resolution
    │
    └── Filesystem Creation
```

------------------------------------------------------------------------

# ⚠️ Troubleshooting

## `treecreate-final` not recognized

Reload the PowerShell profile:

``` powershell
. $PROFILE
```

Then verify:

``` powershell
Get-Command treecreate-final
```

------------------------------------------------------------------------

## `tc` is running an old version

Check:

``` powershell
Get-Command treecreate | Format-List Definition
```

The definition should call:

``` text
treecreate-final
```

and should not call:

``` text
treecreate-v2
```

------------------------------------------------------------------------

## Clipboard mode says clipboard is empty

Copy the complete tree structure first:

``` text
MY_APP/
├── src/
└── README.md
```

Then run:

``` powershell
tc
```

------------------------------------------------------------------------

## Nothing is created

Use dry run first:

``` powershell
tc project.txt -WhatIf
```

Check the detected format and generated paths.

------------------------------------------------------------------------

# 🔐 Safety

`treecreate` creates filesystem objects based on the supplied tree.

Recommended workflow:

``` text
Create / paste tree
       ↓
Run -WhatIf
       ↓
Review paths
       ↓
Run actual command
```

Be especially careful when using tree files containing absolute paths or
when running the command in sensitive directories.

------------------------------------------------------------------------

# 🛣️ Future Improvements

Possible future versions could add:

-   [ ] `treecreate --help`
-   [ ] `treecreate --version`
-   [ ] `treecreate --install`
-   [ ] `treecreate --uninstall`
-   [ ] Better command-line argument parsing
-   [ ] Colored summary output
-   [ ] JSON/YAML input support
-   [ ] Ignore rules
-   [ ] Template variables
-   [ ] Project-name options
-   [ ] Automatic Git initialization
-   [ ] Optional file-content generation
-   [ ] Cross-platform PowerShell support
-   [ ] Package/distribution support

------------------------------------------------------------------------

# 📌 Quick Reference

  Command                    Purpose
  -------------------------- --------------------------------
  `tc`                       Create from clipboard
  `tc -WhatIf`               Clipboard dry run
  `tc project.txt`           Open/edit tree file and create
  `tc project.txt -WhatIf`   Edit tree file and dry run
  `Get-Command treecreate`   Check command
  `Get-Alias tc`             Check alias
  `. $PROFILE`               Reload PowerShell profile

------------------------------------------------------------------------

## 💡 Typical Workflow

For the fastest workflow:

``` text
Copy tree structure
        ↓
Open target folder
        ↓
tc -WhatIf
        ↓
Review
        ↓
tc
```

Or, when you want to edit the tree directly:

``` text
Target folder
     ↓
tc project.txt
     ↓
Notepad opens
     ↓
Paste tree
     ↓
Save + Close
     ↓
Project structure created
```

------------------------------------------------------------------------

## 📜 License

Choose a license appropriate for your intended distribution. For
example, MIT License if you want to make the project permissively
open-source.

------------------------------------------------------------------------

## 👨‍💻 Project

**treecreate** is a PowerShell-based project automation utility designed
to make project scaffolding fast, repeatable, and simple.
