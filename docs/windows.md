# PureBuilder Simply on Windows

## Notice

PureBuilder Simply supports *ONLY* Windows PowerShell with Windows 10 and Windows Subsystem for Linux.

## Prepare

### Install Pandoc

[Get Pandoc from official install page](https://pandoc.org/installing.html) and install it.

Notice: *Pandoc 2.10.1 Windows installer installs pandoc 2.4! please replace files in [Pandoc 2.10.1 ZIP](https://github.com/jgm/pandoc/releases/latest) after installation.*

### Install Ruby

[Use RubyInstaller](https://github.com/jgm/pandoc/releases/latest) with enable PATH.

### Install Git for Windows

Install [Git for Windows](https://gitforwindows.org/).

### Install Windows Terminal (optional)

PureBuilder Simply on Windows wants Windows PowerShell.
Windows Terminal is way to use PowerShell with more effective.

It's on Microsoft Store.

### Install editor (optional)

You should get a good editor.

I recommend Visual Studio Code or Atom.

### Install PureBuilder Simply

Do that on PowerShell (or as `.ps1` script):

```powershell
cd $Env:LocalAppData
git clone 'git://github.com/reasonset/purebuilder-simply.git'
```

### PowerShell alias setting

PureBuilder Simply supports *Windows PowerShell on Windows 10,* but it needs difficult way.

#### Until create profile

Run PowerShell as **adminisatrator** and do that:

```powershell
Set-ExecutionPolicy RemoteSigned
```

*close administrator's PowerShell and open User's PowerShell.*
Do

```powershell
New-Item -type file -force $profile
```

#### add function to profile

Add PureBuilder Simply functions to profile.
Open it as

```powershell
notepad $Profile
```

and edit it.

```powershell
function PureBuilder-Simply { ruby $Env:LocalAppData/pbsimply-pandoc.rb $Args }
function PureBuilder-Server { ruby $Env:LocalAppData/pbsimply-testserver.rb $Args }
```

It you want, you can use short name instread of `PureBuilder-Simply`.

### Open PowerShell Here (optional)

If you don't use Windows Terminal, I recommend to enable opening PowerShell with right click.

You save this as `.reg` and run it.

```
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\shell\powershell_here]
@="Open PowerShell Here"

[HKEY_CLASSES_ROOT\Directory\shell\powershell_here\command]
@="C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%L'"

[HKEY_CLASSES_ROOT\Directory\Background\shell\powershell_here]
@="Open PowerShell Here"

[HKEY_CLASSES_ROOT\Directory\Background\shell\powershell_here\command]
@="C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'"
```

### If Ruby or Pandoc is not on PATH

If `ruby --version` or `pandoc --version` is not enabled, add folders include `ruby.exe` and `pandoc.exe` to `PATH` environment variable.

You can find it with Windows search "environment variable."

## Difference and restriction

### `dbstyle`

PureBuilder Simply use Ruby Marshal for index, but it's not work on Windows.

You can avoid it with set `dbstyle: yaml` on `.pbsimply.yaml` file. You can use also `json` or `oj`.

### Open terminal here

"Open Terminal here" is important action.

If you use Windows Terminal, you can it with `wt -d .` on Explorer's address bar.

### command

Use function name instread of `pbsimply-pandoc.rb` or `pbsimply-testserver.rb`.

### plugins

Plugins need

* A plugins has supported extension.
* The interprieter is able to invoke with simple command

for work.

## In other way: use WSL (recommended)

WSL solves any problem.

### Enable WSL

Search "Windows Subsystem for Linux" on Microsoft Docs.

I tested with openSUSE Leap, but it's not must.

### Install Windows Terminal

Get it on Microsoft store.

### Install Ruby and Pandoc

I recommend use Ruby on WSL instead of Ruby Windows.

Install ruby if this script on WSL

```bash
type ruby
```

returns not found, on openSUSE

```bash
zypper install ruby
```

Install git too if not exist.

I recommend to use Pandoc for Windows not on WSL.

Install Pandoc to Windows and create execlutable script `/usr/local/bin/pandoc`.

```bash
#!/bin/bash

"/mnt/c/Program Files/Pandoc/pandoc.exe" $@
```

If Pandoc binary is not on `C:\Program Files\Pandoc\pandoc.exe`, correct it.

More interpretation for not Linuxer:

If you can use Vi. edit with `sudo vi /usr/local/bin/pandoc`,
or on openSUSE Leap, you can use Emacs with `sudo emacs /usr/local/bin/pandoc`.

Key for Save on Emacs is `Ctrl+X Ctrl+S`. Key for close Emacs is `Ctrl+X Ctrl+C`.

After create it, set execlutable with

```bash
sudo chmod 755 /usr/local/bin/pandoc
```

### Install PureBuilder Simply

On WSL:

```bash
sudo mkdir /opt
sudo chmod 777 /opt
cd /opt
git clone 'git://github.com/reasonset/purebuilder-simply.git'
cd /usr/local/bin
sudo ln -s /opt/purebuilder-simply/*.rb .
```

### Write documents and build.

Create project folder.
You can edit source files very normally.

WSL is used on building step.
Open WSL environment with type `wt -d .` on Explorer's address bar on source document root.
(Choose WSL distribution from right side of tab if started with without WSL.)

Now you can build like on the Linux. Use `pbsimply-pandoc.rb` command.