# PowerShell Custom Commands

A simple guide to create a PowerShell profile and add custom commands for frequently used scripts.

## 1. Create PowerShell Profile

```powershell
New-Item -Path $PROFILE -Type File -Force
```

**Meaning:**

* `New-Item` → Creates a new item.
* `-Path` → Specifies the location.
* `$PROFILE` → Built-in variable containing the PowerShell profile path.
* `-Type File` → Creates a file.
* `-Force` → Creates the required path/item when necessary.

Check the profile location:

```powershell
$PROFILE
```

---

## 2. Open Profile

```powershell
notepad $PROFILE
```

Opens the PowerShell profile directly in Notepad.

---

## 3. Create a Custom Command

PowerShell functions can be used to create your own commands.

### Syntax

```powershell
function <command> {
    <command to execute>
}
```

### Example

```powershell
function wth {
    python "C:\Users\victus\OneDrive\Desktop\Mycommands\weather.py"
}
```

Now simply run:

```powershell
wth
```

This executes the `weather.py` script.

---

## 4. Multiple Commands

You can add multiple functions to `$PROFILE`:

```powershell
function wth {
    python "C:\Users\victus\OneDrive\Desktop\Mycommands\weather.py"
}

function yt {
    python "C:\Users\victus\OneDrive\Desktop\Mycommands\youtube.py"
}
```

Then use:

```powershell
wth
yt
```

---

## Quick Reference

| Command                                     | Purpose               |
| ------------------------------------------- | --------------------- |
| `$PROFILE`                                  | Show profile path     |
| `New-Item -Path $PROFILE -Type File -Force` | Create profile        |
| `notepad $PROFILE`                          | Open profile          |
| `function name { ... }`                     | Create custom command |

### Basic Flow

```text
Create Profile
      ↓
Open Profile
      ↓
Add Functions
      ↓
Save Profile
      ↓
Use Custom Commands
```
