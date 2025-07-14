# CachyOS KDE Handbook 🐧

System info: CachyOS + KDE Plasma Wayland + fish shell

<a href="https://cachyos.org/"><img src="https://cachyos.org/_astro/logo.DVTdAJi6.svg" width="100"/></a> &emsp;
<a href="https://kde.org/plasma-desktop"><img src="https://kde.org/stuff/clipart/logo/plasma-logo-colorful.svg" width="100"/></a> &emsp;
<a href="https://wayland.freedesktop.org"><img src="https://upload.wikimedia.org/wikipedia/commons/9/99/Wayland_Logo.svg" width="100"/></a> &emsp;
<a href="https://fishshell.com"><img src="https://avatars.githubusercontent.com/u/1828073" width="100"/></a>

---

- [Resource Management](#resource-management)
  - [Large file and folder monitor](#large-file-and-folder-monitor)
  - [Find large files](#find-large-files)
  - [Clean package manager caches](#clean-package-manager-caches)
  - [Rerate package mirrors](#rerate-package-mirros)
  - [AutoTrash](#autotrash)
  - [journalctl](#journalctl)
- [Services](#services)
  - [SSH Session Keep-Alive](#ssh-session-keep-alive)
  - [Java](#java)
  - [GPG](#gpg)
- [Applications](#applications)
  - [AppImages](#appimages)
  - [Librewolf](#librewolf)
  - [OneDrive](#onedrive)
  - [Jetbrains Toolbox](#jetbrains-toolbox)
  - [nvm](#nvm)
  - [Steam](#steam)
  - [yt-dlp](#yt-dlp)
- [TLS](#tls)
  - [Import CA](#import-ca)

---

The initial starting point is [`setup.fish`](setup.fish), which sets up all required tools and applications by itself.  
Run it with the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/setup.fish | fish
```

## Resource Management

### Large file and folder monitor

Simple overview of the largest files and folders:

```bash
ncdu /
```

### Find large files

Find files in current directory with a specified minimum size (in this example 100 MB):

```bash
find . -type f -size +100M
```

### Clean package manager caches

Call this to start interactive package manager cache clearing:

```bash
yay -Sc
```

### Rerate package mirros

```bash
sudo cachyos-rate-mirrors
```

### Autotrash

To automatically clear older files in the trash, run the following (example: files older than 40 days):

```bash
uv tool install autotrash
autotrash -d 40 --install
```

### journalctl

See space used by system logs:

```bash
journalctl --disk-usage
```

Set maximum log retention time in `/etc/systemd/journald.conf`:

```bash
MaxRetentionSec=1month
```

## Services

### SSH Session Keep-Alive

Edit `/etc/ssh/ssh_config` and append:

```bash
ServerAliveInterval 60
```

### Java

To install the correct version do the following and install the requested version:

```bash
sudo pacman -Ss java | grep jdk
```

To switch between installed java versions use:

```bash
archlinux-java
```

Set the `JAVA_HOME` env variable with the following config in `~/.env`:

```bash
JAVA_HOME=/usr/lib/jvm/default
```

### GPG

List keys:

```bash
gpg --list-secret-keys --keyid-format=long
```

Show public key for id:

```bash
gpg --armor --export <keyid>
```

Edit key:

```bash
gpg --edit-key <keyid>
```

Set correct `~/.gnupg/` permissions:

```bash
chown -R $(whoami) ~/.gnupg/
find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;
```

## Applications

### AppImages

To use AppImage files, call the following:

```bash
sudo pacman -S fuse
```

### Librewolf

To apply preferences to Librewolf via the [browser/librewolf.overrides.cfg](browser/librewolf.overrides.cfg), store it at `~/.librewolf/`.  
Restart the browser and find applied policies at `about:policies`.

### OneDrive

Install [abraunegg/onedrive](https://github.com/abraunegg/onedrive) with the following components:

- **d-compiler**: ldc
- **d-runtime**: liblphobos

To allow logging to `/var/log/onedrive`, do the following:

```bash
sudo mkdir /var/log/onedrive
sudo chown root:niko /var/log/onedrive
sudo chmod 0775 /var/log/onedrive
```

Initialize onedrive:  
```bash
onedrive
```

After initializing onedrive and BEFORE running the first sync, copy [config](onedrive/config) and [sync_list](onedrive/sync_list) to `~/.config/onedrive/`. Check the config with `onedrive --display-config`.

First sync:  
`onedrive --resync --sync`

### Jetbrains Toolbox

First allow AppImages (see [AppImages](#appimages)).

Then run [`jetbrains-toolbox.sh`](jetbrains-toolbox.sh) with:

```bash
curl -fsSL https://raw.githubusercontent.com/cyb3rko/cachykde-handbook/refs/heads/main/jetbrains-toolbox.sh | sh
```

Based on [nagygergo/jetbrains-toolbox-install](https://github.com/nagygergo/jetbrains-toolbox-install)

### nvm

Install nvm like explained in their [README](https://github.com/nvm-sh/nvm?tab=readme-ov-file#install--update-script).  
Then add the following to `config.fish`:

```fish
function nvm
    bash -c "source ~/.nvm/nvm.sh; nvm $argv"
end

set -U fish_user_paths /home/niko/.nvm/versions/node/*/bin $fish_user_paths
```

### Steam

Included in CachyOS gaming package `cachyos-gaming-applications`.  
Requires `cachyos-gaming-meta`.

Configuration:

- activate hardware acceleration in the Steam settings
- enable game emulation via Proton in the Steam settings

## TLS

### Import CA

1. Run `sudo trust anchor ca-file.pem`
2. Check import with `ls /etc/ca-certificates/trust-source` and `trust list` (to grep e.g. 'Cyb3rKo' in CA list, use `trust list | grep -iB 5 Cyb3rKo`)
3. [Test TLS connection with `openssl s_client -connect <host>:443`]
